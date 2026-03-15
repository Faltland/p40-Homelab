#!/usr/bin/env python3
import subprocess
import serial
import time

SERIAL_PORT = '/dev/ttyUSB1'
BAUD_RATE = 9600
INTERVAL = 5

def get_gpu_temp(gpu_index=1):
    try:
        result = subprocess.run(
            ['nvidia-smi',
             '--query-gpu=temperature.gpu',
             '--format=csv,noheader,nounits',
             f'--id={gpu_index}'],
            capture_output=True, text=True
        )
        return int(result.stdout.strip())
    except:
        return 30  # fallback: minimum speed

def main():
    print(f"Connecting to Arduino 2 on {SERIAL_PORT}...")
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2)
        time.sleep(2)
        print("Connected.")
    except Exception as e:
        print(f"Error: {e}")
        return

    while True:
        temp = get_gpu_temp(gpu_index=1)
        ser.write(f"{temp}\n".encode())

        time.sleep(0.1)
        while ser.in_waiting:
            response = ser.readline().decode().strip()
            if response:
                print(f"GPU1: {temp}C -> {response}")

        time.sleep(INTERVAL)

if __name__ == "__main__":
    main()
