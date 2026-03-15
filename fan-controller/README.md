# Arduino PWM Fan Controller for Tesla P40 in Dell R730

**25 kHz PWM · Tachometer monitoring · Failure detection · systemd integration**

The Tesla P40 is a passive GPU — no blower, no active cooling. In a Dell R730 with forced airflow it mostly survives, but there's a critical problem: the P40 doesn't report its temperature to iDRAC. The R730's baseboard management is completely blind to the GPU. The chassis fans regulate on CPU/DIMM temperature only.

This is a complete Arduino-based solution: read GPU temperature via `nvidia-smi`, send it over serial to an Arduino Nano, which generates a proper 25 kHz PWM signal for a 4-pin fan mounted on the P40. Includes tachometer feedback, automatic failure detection, and systemd services that start on boot.

Tested with: **Arctic S4028-15K** (40mm, up to 28,000 RPM, 4-pin PWM) — see `../enclosure/` for the 3D-printed adapter that makes it fit in the R730's tight clearances.

---

## Why not just crank the system fans?

The R730's system fans at manual override run at full speed (~18,000 RPM) — extremely loud and not targeted at the GPU. There's no way to make them respond to P40 temperature through iDRAC. A dedicated solution is the only clean option.

## Why 25 kHz PWM?

Arduino's `analogWrite()` defaults to ~490 Hz PWM. On 4-pin fans this causes two problems: the fan oscillates instead of regulating linearly, and 490 Hz falls in the audible range, producing an annoying whine. The Intel 4-pin fan spec defines 25 kHz as the standard. At 25 kHz, fan controllers respond smoothly and the frequency is inaudible.

The solution: configure Timer1 directly on the ATmega328P. `ICR1 = 320` gives exactly 25 kHz at 16 MHz: `16,000,000 / 320 = 50,000 half-periods = 25,000 Hz`.

---

## Hardware

| Component | Spec | Notes |
|-----------|------|-------|
| Arduino Nano CH340 | ATmega328P, 16 MHz | Processor: ATmega328P (NOT Old Bootloader) |
| 40mm fan | 4-pin PWM, 12V | Arctic S4028-15K or similar, max ~15,000 RPM |
| USB hub | 4-port, internal | Kapton-wrapped, connected to R730 internal USB port |
| Dupont cables | Female-to-female | Arduino to fan header |
| WAGO connectors | 2-wire, 12V | 12V distribution to fan pin 2 |
| Kapton tape | High-temperature | Insulation and securing inside the server |

### System architecture

One Arduino Nano per GPU. All Nanos connect to an internal USB hub, mounted on the air shroud with Kapton tape and plugged into the R730's internal USB port (under the air shroud).

```
Dell PowerEdge R730
└── Internal USB port
    └── USB hub (Kapton-wrapped, mounted on air shroud)
        ├── Arduino 1 (/dev/ttyUSB0) → Fan for P40 #1 (Riser 2, internal)
        ├── Arduino 2 (/dev/ttyUSB1) → Fan for P40 #2 (internal)
        └── Arduino 3 (/dev/ttyUSB2) → Fan for P40 #3 (Riser 1, external)
```

---

## Fan wiring (4-pin PWM)

| Pin | Color | Function | Connection |
|-----|-------|----------|------------|
| 1 | Black | GND | Arduino GND |
| 2 | Yellow | 12V supply | 12V from PSU via WAGO/Molex — NOT from Arduino |
| 3 | Green | Tachometer | Arduino D2 (interrupt) |
| 4 | Blue | PWM signal | Arduino D9 (25 kHz) |

**Critical:** Pin 2 (12V) is NOT supplied by the Arduino — the Arduino can only source 5V at 40mA per pin. 12V comes directly from the server PSU via WAGO connector or Molex tap. Arduino and fan share only a common GND.

---

## Arduino sketch

The same sketch runs on all Nanos. The intelligence (which GPU, which port) lives entirely in the Python script on the server.

```cpp
volatile int pulseCount = 0;
unsigned long lastRPMCheck = 0;
int rpm = 0;
bool fanError = false;

void countPulse() { pulseCount++; }

void setup() {
  Serial.begin(9600);
  pinMode(9, OUTPUT);
  pinMode(2, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(2), countPulse, FALLING);

  // Configure Timer1 for 25 kHz PWM on pin 9
  TCCR1A = 0; TCCR1B = 0;
  TCCR1A |= (1 << COM1A1) | (1 << WGM11);
  TCCR1B |= (1 << WGM13) | (1 << CS10);
  ICR1 = 320;   // 16 MHz / 320 = 25 kHz
  OCR1A = 64;   // 20% startup duty cycle (64/320)

  Serial.println("Arduino ready - 25kHz PWM");
}

void setPWM(int percent) {
  OCR1A = map(percent, 0, 100, 0, 320);
}

void loop() {
  // Calculate RPM every 2 seconds
  if (millis() - lastRPMCheck >= 2000) {
    rpm = (pulseCount * 60) / 2 / 2; // 2 pulses/rev, 2s window
    pulseCount = 0;
    lastRPMCheck = millis();

    // Fan failure detection
    if (rpm == 0 && OCR1A > 96) { // PWM > 30% but no rotation
      fanError = true;
      setPWM(100);
      Serial.println("ERROR:FAN_FAILURE");
    } else {
      fanError = false;
    }
    Serial.print("RPM:"); Serial.println(rpm);
  }

  // Receive temperature from Python script
  if (Serial.available() > 0) {
    int temp = Serial.parseInt();
    if (temp > 0) {
      if (!fanError) {
        int percent = map(temp, 30, 55, 20, 100);
        percent = constrain(percent, 20, 100);
        setPWM(percent);
        Serial.print("Temp:"); Serial.print(temp);
        Serial.print(" PWM%:"); Serial.print(percent);
        Serial.print(" RPM:"); Serial.println(rpm);
      } else {
        Serial.println("ERROR:FAN_FAILURE - PWM locked");
      }
    }
  }
}
```

---

## Python control script (`gpu_fan.py`)

Reads GPU temperature every 5 seconds via `nvidia-smi` and sends it to the Arduino over serial.

```python
#!/usr/bin/env python3
import subprocess
import serial
import time

SERIAL_PORT = '/dev/ttyUSB0'  # Arduino 1 (P40 #1)
BAUD_RATE = 9600
INTERVAL = 5  # seconds between readings

def get_gpu_temp(gpu_index=0):
    try:
        result = subprocess.run(
            ['nvidia-smi', '--query-gpu=temperature.gpu',
             '--format=csv,noheader,nounits', f'--id={gpu_index}'],
            capture_output=True, text=True)
        return int(result.stdout.strip())
    except:
        return 30  # fallback: minimum speed

def main():
    print(f'Connecting to Arduino on {SERIAL_PORT}...')
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2)
        time.sleep(2)  # wait for Arduino reset
        print('Connected.')
    except Exception as e:
        print(f'Error: {e}'); return

    while True:
        temp = get_gpu_temp(gpu_index=0)
        ser.write(f'{temp}\n'.encode())
        time.sleep(0.1)
        while ser.in_waiting:
            response = ser.readline().decode().strip()
            if response:
                print(f'GPU0: {temp}C -> {response}')
        time.sleep(INTERVAL)

if __name__ == '__main__':
    main()
```

For multiple GPUs, create copies with adjusted port and GPU index:

```bash
# gpu_fan.py   → SERIAL_PORT = '/dev/ttyUSB0', gpu_index=0
# gpu_fan2.py  → SERIAL_PORT = '/dev/ttyUSB1', gpu_index=1
# gpu_fan3.py  → SERIAL_PORT = '/dev/ttyUSB2', gpu_index=2
```

---

## Installation

```bash
# Install pyserial
pip install pyserial --break-system-packages

# Grant serial port access without sudo
sudo usermod -aG dialout $USER
# Log out and back in after this

# Deploy script
sudo cp gpu_fan.py /usr/local/bin/gpu_fan.py
sudo chmod +x /usr/local/bin/gpu_fan.py
```

---

## systemd service

```ini
[Unit]
Description=GPU Fan Control P40-1
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/gpu_fan.py
Restart=always
RestartSec=10
User=YOUR_USERNAME

[Install]
WantedBy=multi-user.target
```

```bash
sudo nano /etc/systemd/system/gpu_fan.service
# (paste content, Ctrl+O, Enter, Ctrl+X)

sudo systemctl daemon-reload
sudo systemctl enable gpu_fan
sudo systemctl start gpu_fan
sudo systemctl status gpu_fan
```

If the Arduino isn't connected yet (e.g. before installing the second GPU), the service starts, fails, and retries every 10 seconds (`Restart=always, RestartSec=10`). Once the Arduino is plugged in, the service picks up automatically.

---

## Temperature / RPM curve

| GPU temp | Duty cycle | Approx. RPM |
|----------|-----------|-------------|
| ≤ 30°C | 20% | ~5,000 |
| 40°C | 40% | ~7,500 |
| 47°C | 60% | ~10,000 |
| 52°C | 75% | ~12,000 |
| 55°C | 90% | ~14,000 |
| ≥ 55°C | 100% | ~15,000 |

Minimum 20%: below this threshold, 40mm fans begin to oscillate. 20% is the experimentally determined minimum for stable operation with the Arctic S4028-15K. This may vary by fan model.

---

## Arduino upload notes

**Important:** In Arduino IDE under Tools → Processor, select **ATmega328P** — NOT "ATmega328P (Old Bootloader)". CH340-based Nanos with the newer bootloader will fail to upload with the wrong processor type.

```bash
# Find port on Linux:
ls /dev/ttyUSB*

# Find port on Mac:
ls /dev/tty.usbserial*
```

---

## Debugging

```bash
# Service status
sudo systemctl status gpu_fan
journalctl -u gpu_fan -f        # live log

# Test serial directly (without Python script running)
screen /dev/ttyUSB0 9600
# Type a temperature value, e.g. '50' + Enter
# Arduino responds: Temp:50 PWM%:80 RPM:13200
# Exit: Ctrl+A then K

# GPU temperature
nvidia-smi --query-gpu=temperature.gpu,fan.speed --format=csv
watch -n 1 nvidia-smi
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `Permission denied` on `/dev/ttyUSB*` | `sudo usermod -aG dialout $USER`, then log out and back in |
| Fan oscillates / doesn't regulate | Wrong PWM frequency — configure Timer1 for 25 kHz (see sketch above) |
| Upload error "Old Bootloader" | Arduino IDE: Tools → Processor → ATmega328P (without Old Bootloader) |
| RPM always 0 | Check tachometer pin: `INPUT_PULLUP` active? Fan pin 3 connected to D2? |
| Service doesn't start after reboot | `systemctl enable gpu_fan` missed? Or `dialout` group not active yet (re-login needed) |

---

## Planned extensions

- **Visual status indicator:** RGB LED on the server front panel via a fourth Arduino (OrganicStat) — idle: blue breathing, load: orange pulse, error: red blink
- **Temperature logging:** InfluxDB/Grafana integration for long-term thermal curves
- **Hysteresis:** Smoother regulation to avoid frequent up/down oscillation under stable load

---

## Files

| File | Description |
|------|-------------|
| `gpu_fan.py` | Python control script (GPU 1) |
| `gpu_fan2.py` | Python control script (GPU 2) |
| `gpu_fan3.py` | Python control script (GPU 3) |
| `gpu_fan.service` | systemd service unit (GPU 1) |
| `arduino_pwm_fan/arduino_pwm_fan.ino` | Arduino sketch |

---

*Part of the [faltland/p40-homelab](https://github.com/faltland/p40-Homelab) project.*
