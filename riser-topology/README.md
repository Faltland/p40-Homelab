# PCIe Riser Topology

Verified slot map for the Dell PowerEdge R730 with 7x Tesla P40.

## The short version

The R730 has three riser positions with 7 PCIe slots total. This is the hardware ceiling — determined by PCIe lane count (80 lanes across both E5-2630 v4 CPUs) and fixed mainboard routing. No alternative riser configuration adds more slots.

## Slot map (verified via `lspci -tv`)

```
CPU1 [0000:00]:
|- Riser 3, Slot A  ->  Bus 04  --  x16
|- Riser 3, Slot B  ->  Bus 05  --  x16
`- Riser 2, Slot 5  ->  Bus 06  --  x16

CPU2 [0000:80]:
|- Riser 2, Slot 4  ->  Bus 81  --  x16
|- Riser 1, Slot 1  ->  Bus 82  --  x8
|- Riser 1, Slot 3  ->  Bus 83  --  x8
`- Riser 1, Slot 2  ->  Bus 84  --  x8
```

4x x16 slots, 3x x8 slots.

## Current GPU assignment

| GPU | PCIe Bus | Riser | Bandwidth | CPU domain |
|-----|---------|-------|-----------|------------|
| 0 | 04:00.0 | Riser 3, Slot A | x16 | CPU1 |
| 1 | 06:00.0 | Riser 2, Slot 5 | x16 | CPU1 |
| 2 | 81:00.0 | Riser 2, Slot 4 | x16 | CPU2 |
| 3 | 82:00.0 | Riser 1, Slot 1 | x8 | CPU2 |
| 4 | 83:00.0 | Riser 1, Slot 3 | x8 | CPU2 |
| 5 | 84:00.0 | Riser 1, Slot 2 | x8 | CPU2 |
| 6 | 05:00.0 | Riser 3, Slot B | x16 | CPU1 |

All GPUs run via 60cm PCIe extender cables into the external U-Frame. The server holds no GPUs internally.

## Things that weren't obvious

**Riser 2 is split across both CPUs.** Slot 4 routes to CPU2, Slot 5 routes to CPU1. This is not mentioned in Dell documentation and only becomes clear via `lspci -tv`. Earlier versions of this build assumed Riser 2 was entirely on one CPU — that was wrong both times.

**Riser 1 Slot 3 is physically in the middle, not at the end.** The slot numbering does not follow physical order. Slot 1 is leftmost, Slot 3 is center, Slot 2 is rightmost (when viewed from the rear of the server).

**The 7-slot limit is real.** Dell offers an alternative Riser 3 (part 800JH) with 1x x16 instead of 2x x8, which actually reduces slot count. There is no riser combination that exceeds 7 slots on this chassis.

## PCIe bifurcation (in progress)

A bifurcation adapter splits one x16 slot into two x8 endpoints via the PCIe spec's bifurcation feature, each connecting to a separate GPU via extender cable. If the R730 BIOS supports it, this allows more than 7 GPUs on 7 slots.

Planned next step: 1x V100 32 GB (Volta, sm_70) on a direct x16, bifurcation adapter on a second x16 slot with 2x P40 on the outputs.

Target configuration: 4x V100 via bifurcated x16 slots alongside the 7x P40 — 11 GPUs total, 296 GB VRAM.

BIOS support for bifurcation has not yet been verified on this specific chassis.

## How to verify your own slot mapping

```bash
# Full PCIe tree
lspci -tv

# GPU bus IDs only
nvidia-smi --query-gpu=index,name,pci.bus_id --format=csv

# Which CPU domain a bus belongs to
# Bus addresses 00:xx are CPU1, 80:xx are CPU2 on dual-socket Xeon systems
```
