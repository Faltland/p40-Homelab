#!/usr/bin/env python3
"""
Fan-Arduino Provisioning Script

Writes a unique FAN-ID into each Arduino's EEPROM.
Run this once before deploying fan services.

Usage:
  1. Stop all running fan services
  2. Connect each Arduino via USB
  3. Edit ASSIGNMENTS below to match your setup
  4. Run: python3 fan_provisioning.py

After provisioning, the gpu_fan.py scripts will find their Arduinos
automatically via WHO? scanning — port assignments become irrelevant.

For new Arduinos added later, either extend ASSIGNMENTS and re-run,
or provision directly via Arduino IDE Serial Monitor:
  Send: ID:FAN5
  Verify: WHO?  ->  should respond: FAN:FAN5
"""
import serial
import time
import sys

BAUD_RATE = 9600

# Map port -> FAN-ID
# Use the current port assignment (check with: ls /dev/ttyUSB*)
# Port order may change after reboot — that's fine, provisioning only needs to run once.
ASSIGNMENTS = [
    ('/dev/ttyUSB0', 'FAN1'),
    ('/dev/ttyUSB1', 'FAN2'),
    ('/dev/ttyUSB2', 'FAN3'),
    ('/dev/ttyUSB3', 'FAN4'),
]


def provision(port, fan_id):
    print(f"\n{port} -> {fan_id}")
    try:
        ser = serial.Serial(
            port, BAUD_RATE, timeout=3,
            dsrdtr=False, rtscts=False
        )
        ser.setDTR(False)
        ser.setRTS(False)
        time.sleep(1)
        ser.reset_input_buffer()

        # Check current ID
        ser.write(b'WHO?\n')
        response = ser.readline().decode().strip()
        print(f"  Current:  {response}")

        # Write new ID
        ser.write(f'ID:{fan_id}\n'.encode())
        time.sleep(0.5)
        response = ser.readline().decode().strip()
        print(f"  Set:      {response}")

        # Verify
        ser.write(b'WHO?\n')
        time.sleep(0.3)
        response = ser.readline().decode().strip()
        print(f"  Verify:   {response}")

        expected = f'FAN:{fan_id}'
        if response == expected:
            print(f"  OK")
            ser.close()
            return True
        else:
            print(f"  FAIL — expected '{expected}', got '{response}'")
            ser.close()
            return False

    except Exception as e:
        print(f"  ERROR: {e}")
        return False


def main():
    print("Fan-Arduino Provisioning")
    print("Prerequisite: all gpu_fan*.service stopped")
    print()

    answer = input("Fan services stopped? [y/N] ").strip().lower()
    if answer != 'y':
        print("Aborted.")
        sys.exit(0)

    results = {}
    for port, fan_id in ASSIGNMENTS:
        ok = provision(port, fan_id)
        results[port] = (fan_id, ok)

    print()
    all_ok = True
    for port, (fan_id, ok) in results.items():
        status = "OK" if ok else "FAIL"
        print(f"  {status}  {port} -> {fan_id}")
        if not ok:
            all_ok = False

    if all_ok:
        print("\nAll Arduinos provisioned. Start fan services and verify.")
    else:
        print("\nErrors occurred. Do not start fan services until resolved.")


if __name__ == '__main__':
    main()
