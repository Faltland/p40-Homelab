# P40 Enclosure & Mounting — 3D Print Files

3D-printed parts for running a Dell R730 vertically and housing Tesla P40 GPUs cleanly. All parts are tested and in production use.

---

## Contents

### 1. Vertical stand (`kufe_v16_final`)
Two identical cross-feet that hold the R730 upright. The server stands on its side between a couch and a box — the feet lift it off the floor and create a floating effect. No screws, no glue — form-fit only.

- Footprint reduced from ~70cm depth to ~9cm width
- Front panel fully accessible
- Airflow unchanged: front intake → rear exhaust
- Print 2× identical

See `R730_Vertikalstaender_Doku.md` for full design documentation including critical geometry notes.

### 2. Top cover — 3 segments (`abdeckung_seg1/2/3`)
A three-part cover for the narrow top face of the vertically-mounted R730. Dust protection and aesthetics. The server is 690mm long — three 230mm segments with tongue-and-groove joints.

- Material: PETG (better long-term load than PLA)
- Accounts for rack ear geometry, shoulder screw pockets, and bezel cutout
- SCAD source files included for modifications

See `Abdeckung_R730.md` for full spec including measurements, segment layout, and shoulder screw positions.

### 3. 40mm fan adapter (`40mm_Fan_adapter`)
Modified fan adapter for attaching an active 40mm fan to the passive P40 heatsink. Reduced from 20mm to **15mm depth** to fit inside the extremely tight Dell R730 chassis — the original 20mm version physically interferes with the chassis wall.

- Fan secured via **4× M3 heat-set nuts** embedded in the print
- Insert nuts with soldering iron at 230°C — clean and straight
- Attach fan with M3 × 25mm bolts
- Tested with: **Arctic S4028-15K** (40mm, up to 28,000 RPM, 4-pin PWM)

See `fan-controller/` for Arduino PWM controller and wiring.

---

## Print settings

| Part | Material | Infill | Notes |
|------|----------|--------|-------|
| Vertical stand (`kufe_v16_final`) | PETG | 40–50% | 3–4 perimeters, print lying flat, no supports |
| Top cover segments | PETG | 40–50% | 3–4 perimeters, print lying flat (top face up) |
| Fan adapter | PLA | 15–20% | Supports as needed |

**Printer:** Creality K2 with CFS (multi-filament) — bed sufficient for 230mm segments.

**Why PETG for structural parts:** Better long-term load resistance than PLA, slight flexibility helps with press-fit tolerances.

---

## Files

### Vertical stand
| File | Description |
|------|-------------|
| `kufe_v16_final.stl` | Ready to print — 2× required |
| `kufe_v16_final.scad` | OpenSCAD source for modifications |
| `R730_Vertikalstaender_Doku.md` | Full design documentation |

### Top cover
| File | Description |
|------|-------------|
| `abdeckung_seg1_v4.scad` | Bezel segment — OpenSCAD source |
| `abdeckung_seg2_v3.scad` | Middle segment — OpenSCAD source |
| `abdeckung_seg3_v3.scad` | Wall segment — OpenSCAD source |
| `abdeckung_seg1_v4.stl` | Bezel segment — ready to print |
| `abdeckung_seg2_v3.stl` | Middle segment — ready to print |
| `abdeckung_seg3_v3.stl` | Wall segment — ready to print |
| `Abdeckung_R730.md` | Full spec and geometry documentation |

### Fan adapter
| File | Description |
|------|-------------|
| `40mm_Fan_adapter.stl` | Modified adapter — 15mm depth, fits Dell R730 |

#### Fan adapter attribution
Based on **"40mm Fan Adapter for P40/P100/M40"** by D3Cove.
Original: https://www.printables.com/model/1602263-nvidia-tesla-p40-p100-m40-40mm-fan-adapter
Licensed under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) — this remix is also CC BY-NC 4.0.

**What changed:** Depth reduced from 20mm to 15mm to fit Dell R730 chassis clearances. Mounting holes and fan attachment unchanged.

---

## Status

| Component | Status |
|-----------|--------|
| Vertical stand v16 | ✅ In production use |
| Top cover seg 1–3 | ✅ Test print successful, in production |
| Fan adapter (15mm) | ✅ In production use |
| Enclosure for additional P40s | ⏳ In progress |

---

*Part of the [faltland/p40-Homelab](https://github.com/faltland/p40-Homelab) project.*
