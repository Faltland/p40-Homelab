# Fan Controller

Arduino-based PWM fan control for external Tesla P40 GPUs. Each Arduino controls one 4-pin PWM fan and is identified by a permanent ID stored in EEPROM.

## Files

| File | Purpose |
|------|---------|
| `fan-control.ino` | Arduino sketch — flash to each Nano |
| `gpu_fan.py` | Host-side control script — one instance per GPU |
| `fan_provisioning.py` | One-time EEPROM setup — run once before deploying |

## Hardware

- Arduino Nano (CH340 USB-serial)
- 4-pin PWM fan
- Arduino D9 → fan pin 4 (PWM signal)
- Arduino D2 → fan pin 3 (tachometer)
- Fan 12V and GND from GPU PSU
- Arduino GND bonded to PSU GND (required for signal integrity)

## How it works

Each Arduino stores a unique ID (`FAN1` through `FAN7`) in EEPROM. The host-side script scans all `/dev/ttyUSB*` ports on startup and sends `WHO?` to each. The Arduino with the matching ID responds and gets adopted. Port numbers are irrelevant — the script finds its Arduino regardless of enumeration order after reboot or hardware changes.

GPU-to-fan mapping uses PCI bus IDs rather than CUDA device indices. CUDA indices renumber when GPUs are added; PCI bus IDs don't.

## Serial protocol

| Command | Response | Effect |
|---------|---------|--------|
| `WHO?\n` | `FAN:FAN3` | Query ID |
| `ID:FAN3\n` | `OK:FAN3` | Write ID to EEPROM |
| `RESET\n` | `OK:RESET` | Clear EEPROM |
| `<integer>\n` | `Temp:42 PWM%:60 RPM:8000 ID:FAN3` | Set PWM from temperature |

## PWM curve

The curve runs in Arduino firmware. The host script sends raw temperature; the Arduino calculates PWM.

```
< 30°C   ->  20%
30-55°C  ->  20 to 60%, linear
55-70°C  ->  60 to 100%, linear
>= 70°C  ->  100%
```

## Failsafe

If `nvidia-smi` fails to return a temperature, the host script sends `85°C` rather than a low fallback. A fan running too fast is recoverable. A card that overheats because the script silently sent minimum speed is not.

If the Arduino reads RPM = 0 while PWM is above 30%, it locks to 100% until reboot. A fan that isn't spinning despite being commanded to is treated as a hardware failure.

## Setup

**1. Flash the sketch**

Flash `fan-control.ino` to each Arduino Nano via Arduino IDE. Each Arduino starts with ID `UNKNOWN`.

**2. Provision EEPROM IDs**

Stop all fan services, then run:

```bash
sudo systemctl stop gpu_fan.service gpu_fan2.service  # etc.
python3 fan_provisioning.py
```

The script assigns IDs while the port mapping is still known. After provisioning, port assignments are permanent regardless of enumeration order.

**3. Configure the host script**

Each GPU needs its own copy of `gpu_fan.py` with two lines changed:

```python
MY_FAN_ID  = 'FAN3'           # must match EEPROM ID on the Arduino
PCI_BUS_ID = '0000:82:00.0'   # PCI bus ID of the GPU this fan cools
```

Find PCI bus IDs with `nvidia-smi --query-gpu=pci.bus_id --format=csv`.

**4. Create systemd service**

```ini
[Unit]
Description=GPU Fan Control FAN3
After=multi-user.target

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/gpu_fan3.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now gpu_fan3.service
```

## Serial port note

Opening a serial port in Python toggles DTR/RTS by default, which resets the Arduino before it can respond. The script disables this:

```python
ser = serial.Serial(port, 9600, dsrdtr=False, rtscts=False)
ser.setDTR(False)
ser.setRTS(False)
```

Without this, `WHO?` responses will be missing or malformed.

## Staggered startup

Multiple fan services starting simultaneously will race for serial ports. The script staggers startup automatically based on fan number: FAN1 starts immediately, FAN2 waits 2s, FAN3 waits 4s, and so on.
