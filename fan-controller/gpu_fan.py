#!/usr/bin/env python3
"""
GPU Fan Control — WHO?-basierte Arduino-Erkennung
Findet seinen Arduino selbst anhand der EEPROM-ID.
Kein fester Port, keine udev-Abhängigkeit für Arduinos.
"""
import subprocess
import serial
import serial.tools.list_ports
import time
import glob

# ── Konfiguration ────────────────────────────────────────────────────────────
MY_FAN_ID  = 'FAN1'           # ← einzige individuelle Konfiguration
PCI_BUS_ID = '0000:04:00.0'   # ← PCI-ID der zugehörigen GPU (fest, nie ändern)
GPU_LABEL  = 'GPU0'           # nur für Logs
BAUD_RATE  = 9600
INTERVAL   = 5
FALLBACK_TEMP = 85            # bei nvidia-smi Fehler → Vollgas (sicher)
SCAN_RETRY_DELAY = 15         # Sekunden zwischen Scan-Versuchen

# ── Arduino finden ────────────────────────────────────────────────────────────
def port_contains_my_id(response):
    """Prüft ob eine Antwort vom Arduino unsere ID enthält.
    Akzeptiert sowohl WHO?-Antwort als auch Startup-Message:
      WHO?-Format:     'FAN:FAN3'
      Startup-Format:  'Arduino bereit - 25kHz PWM - ID:FAN3'
    """
    return (response == f'FAN:{MY_FAN_ID}' or
            f'ID:{MY_FAN_ID}' in response)

def find_my_arduino():
    """Scannt alle ttyUSB* und sucht den Arduino mit MY_FAN_ID."""
    # Gestaffelter Start — verhindert Race Condition bei parallelem Start
    # FAN1=0s, FAN2=2s, FAN3=4s, FAN4=6s, FAN5=8s ...
    fan_num = int(MY_FAN_ID.replace('FAN', ''))
    startup_delay = (fan_num - 1) * 2
    if startup_delay > 0:
        print(f"[{MY_FAN_ID}] Warte {startup_delay}s (gestaffelter Start)...")
        time.sleep(startup_delay)

    candidates = sorted(glob.glob('/dev/ttyUSB*'))
    if not candidates:
        print(f"[{MY_FAN_ID}] Keine ttyUSB-Geräte gefunden.")
        return None

    for port in candidates:
        try:
            ser = serial.Serial(
                port, BAUD_RATE, timeout=2,
                dsrdtr=False, rtscts=False
            )
            ser.setDTR(False)
            ser.setRTS(False)

            # Doppeltes Flush: erst warten bis gepufferte Daten ankommen,
            # dann leeren — so erwischen wir auch verzögerte Startup-Messages
            time.sleep(0.3)
            ser.reset_input_buffer()
            time.sleep(0.3)
            ser.reset_input_buffer()

            # WHO? senden und auf Antwort warten
            ser.write(b'WHO?\n')
            time.sleep(0.3)
            response = ser.readline().decode('utf-8', errors='replace').strip()

            if port_contains_my_id(response):
                print(f"[{MY_FAN_ID}] Gefunden auf {port} ✅")
                ser.reset_input_buffer()
                return ser
            else:
                if response:
                    print(f"[{MY_FAN_ID}] {port} → '{response}' (nicht meiner)")
                ser.close()

        except serial.SerialException:
            # Port bereits belegt (anderer Fan-Service) — überspringen
            pass
        except Exception as e:
            print(f"[{MY_FAN_ID}] {port}: {e}")

    return None

# ── GPU-Temperatur lesen ──────────────────────────────────────────────────────
def get_gpu_temp():
    try:
        result = subprocess.run(
            ['nvidia-smi',
             '--query-gpu=temperature.gpu',
             '--format=csv,noheader,nounits',
             f'--id={PCI_BUS_ID}'],
            capture_output=True, text=True, timeout=10
        )
        output = result.stdout.strip()
        if not output or result.returncode != 0:
            print(f"[{MY_FAN_ID}] WARN: nvidia-smi kein Output → Fallback {FALLBACK_TEMP}°C")
            return FALLBACK_TEMP
        return int(output)
    except Exception as e:
        print(f"[{MY_FAN_ID}] WARN: nvidia-smi Fehler ({e}) → Fallback {FALLBACK_TEMP}°C")
        return FALLBACK_TEMP

# ── Haupt-Loop ────────────────────────────────────────────────────────────────
def main():
    print(f"[{MY_FAN_ID}] Starte — suche Arduino mit ID {MY_FAN_ID} (GPU: {PCI_BUS_ID})")

    while True:
        ser = find_my_arduino()
        if ser is None:
            print(f"[{MY_FAN_ID}] Arduino nicht gefunden — retry in {SCAN_RETRY_DELAY}s")
            time.sleep(SCAN_RETRY_DELAY)
            continue

        print(f"[{MY_FAN_ID}] Verbunden. Starte Regelkreis.")
        try:
            while True:
                temp = get_gpu_temp()
                ser.write(f"{temp}\n".encode())
                time.sleep(0.1)
                while ser.in_waiting:
                    response = ser.readline().decode().strip()
                    if response:
                        print(f"[{MY_FAN_ID}] {GPU_LABEL}: {temp}°C → {response}")
                time.sleep(INTERVAL)

        except Exception as e:
            print(f"[{MY_FAN_ID}] Verbindung verloren: {e} — suche neu...")
            try:
                ser.close()
            except:
                pass
            time.sleep(5)

if __name__ == "__main__":
    main()
