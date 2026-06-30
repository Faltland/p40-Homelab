# 7x Tesla P40 in a Dell PowerEdge R730 (and counting)

**Current state:** 7x Tesla P40, 168 GB VRAM, all external via custom U-Frame, Arduino-based fan control with self-identifying firmware

**In progress:** PCIe bifurcation + 1x V100 (32 GB HBM2) — if the R730 BIOS supports it, this gets to 11 GPUs and 296 GB VRAM

---

## Why this exists

Local AI inference that doesn't depend on cloud availability. The R730 was cheap on the refurbished market. The P40 was cheaper. The combination requires some work.

---

## Hardware

| Component | Spec |
|-----------|------|
| Server | Dell PowerEdge R730 |
| CPUs | 2x Intel Xeon E5-2630 v4 (10C/20T each) |
| RAM | 188 GB DDR4 ECC |
| GPUs | 7x Tesla P40 (24 GB GDDR5 ECC, Pascal sm_61) |
| Fan control | 7x Arduino Nano, custom firmware, 25 kHz PWM |
| Power (GPUs) | 4x Dell DPS-750XB A (750W each) — GPU power only |
| Power (server) | 2x internal Dell PSU |
| Enclosure | 3D-printed U-Frame (PETG, ~24h print) |

---

## The P40 cooling problem

The P40 is a datacenter card with no display outputs and no fans. Inside a server, blade airflow handles cooling. In a homelab with external GPUs on extender cables, each card is outside the server airflow entirely and needs its own cooling.

---

## Fan control

### v1: hardcoded ports

```python
SERIAL_PORT = '/dev/ttyUSB2'
```

Worked until the first GPU swap. After that, `/dev/ttyUSB2` was a different Arduino, and a fan was cooling the wrong card.

### v2: udev symlinks

Added udev rules to assign stable names like `/dev/ttyFan1`. Worked until new USB devices reshuffled enumeration on reboot.

### v3: WHO?/EEPROM protocol

Each Arduino stores a permanent ID in EEPROM. On startup, each Python script scans every `/dev/ttyUSB*` port and sends `WHO?`. The Arduino with the matching ID responds and gets adopted. Port numbers are irrelevant.

```
WHO?\n      ->  FAN:FAN3
ID:FAN3\n   ->  OK:FAN3
RESET\n     ->  OK:RESET
```

Fan-to-GPU mapping uses PCI bus IDs rather than CUDA device indices. CUDA indices renumber when cards are added. PCI bus IDs don't.

If `nvidia-smi` fails to read a temperature, the script returns `85°C` rather than `30°C`. A silent minimum looks fine in logs while the card overheats.

**PWM curve** (in Arduino firmware):
```
< 30°C  ->  20%
30-55°C ->  20 to 60%, linear
55-70°C ->  60 to 100%, linear
>= 70°C ->  100%
```

If RPM reads zero while PWM is above 30%, the Arduino locks to 100% until reboot.

One issue that took time to find: opening a serial port in Python toggles DTR/RTS by default, which resets the Arduino. Fix: `dsrdtr=False, rtscts=False` plus `setDTR(False)` and `setRTS(False)` immediately after opening the port.

---

## PCIe topology

The R730 has three riser positions with 7 PCIe slots total. This is a hardware ceiling determined by PCIe lane count (80 lanes total across both CPUs).

```
CPU1 [0000:00]:
|- Riser 3, Slot A  ->  Bus 04  --  x16  --  GPU 0
|- Riser 3, Slot B  ->  Bus 05  --  x16  --  GPU 6
`- Riser 2, Slot 5  ->  Bus 06  --  x16  --  GPU 1

CPU2 [0000:80]:
|- Riser 2, Slot 4  ->  Bus 81  --  x16  --  GPU 2
|- Riser 1, Slot 1  ->  Bus 82  --  x8   --  GPU 3
|- Riser 1, Slot 3  ->  Bus 83  --  x8   --  GPU 4
`- Riser 1, Slot 2  ->  Bus 84  --  x8   --  GPU 5
```

One non-obvious finding: Riser 2 routes across both CPUs. Slot 4 goes to CPU2, Slot 5 goes to CPU1. This only became clear via `lspci -tv`.

All GPUs run via 60cm extender cables into the external U-Frame. The server itself holds no GPUs.

---

## U-Frame

The external GPUs are mounted in a 3D-printed frame built around 4x M6 guide rods. Print time was around 24h in PETG with gyroid infill on a Creality K2 with CFS.

Eight GPU tunnels total. Seven are active. The eighth holds a spare P40 that can be swapped in after a clean shutdown without waiting for shipping.

**Power wiring per card:**
- 2.5mm² solid-core wire to Wago 221 connector to 1mm² stranded wire to PCIe 8-pin (Mini-Fit Jr)
- No Y-splits
- Arduino GND bonded to PSU GND

**Important:** The P40 8-pin pinout is fixed, but aftermarket cables sold for it are frequently wired incorrectly. Of three cables tested, only one was correct. A wrong cable can destroy the card or cause a fire. Measure continuity on every cable before connecting it, regardless of what the listing says.

**Power budget:**

| Scenario | GPU draw | PSU load |
|----------|---------|----------|
| All idle (P-state managed) | ~70W total | 2.3% |
| 2-3 GPUs active | ~500W | 17% |
| All at TDP (250W each) | 1750W | 58% |

---

## Vertical stand

The server stands upright on a 30cm wide rolling cart, reducing floor footprint from ~70cm depth to ~9cm width and making the whole setup mobile. Four identical 3D-printed cradles support it. The rack ears slot into a pocket in each cradle; no screws or adhesive needed.

STL files and OpenSCAD source in `/enclosure`.

---

## PCIe bifurcation (in progress)

A bifurcation adapter splits one x16 slot into two x8 endpoints, each connected to a separate GPU via extender cable. Slot count stays at 7, device count increases.

Planned configuration: 1x V100 32 GB on a direct x16, bifurcation adapter on a second x16 slot with 2x P40 on the outputs. That gets to 9 GPUs as a first step.

Target configuration: 4x V100 via bifurcated x16 slots, alongside the existing 7x P40. That would be 11 GPUs total: 7x P40 (168 GB) + 4x V100 (128 GB) = 296 GB VRAM.

The V100 is physically here. The bifurcation adapters are here. Whether the R730 BIOS supports bifurcation is still being verified.

The V100 also matters because it's sm_70 (Volta). The P40 is sm_61 (Pascal), which was dropped from upstream PyTorch and requires a custom build. A Volta card opens a path for workloads that need current framework support without the custom build.

---

## Files

```
p40-homelab/
├── fan-controller/
│   ├── fan-control.ino          Arduino sketch (WHO?/EEPROM, v2)
│   ├── fan_provisioning.py      One-time EEPROM provisioning
│   ├── gpu_fan.py               Host-side fan control template
│   └── README.md
├── enclosure/
│   ├── kufe_v16_final.scad      OpenSCAD source
│   └── README.md
└── riser-topology/
    └── README.md                PCIe slot map, bus IDs, CPU domains
```

---

## Notes

Fan mapping (cooling the wrong card after a swap) was the most persistent problem. Shared airflow in the U-Frame made temperature-delta diagnostics unreliable. Physical cable tracing resolved it.

The bifurcation path is unverified. Everything here is what actually worked, including the parts that didn't work first.
