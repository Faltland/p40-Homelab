# p40-homelab

**Running Tesla P40s in a Dell PowerEdge R730 — riser topology, fan control, 3D enclosures.**

This repo documents everything I've learned getting up to 6× Tesla P40 GPUs running in a Dell R730 for local LLM inference. No cloud. No subscription. Just hardware, iteration, and a lot of airflow math.

The P40 is an underrated card for local AI workloads — 24GB GDDR5 ECC, cheap on the secondhand market, and it fits in a standard PCIe slot. The R730 is a capable dual-socket server that takes them well, but it needs some help: custom riser configurations, fan curve overrides, and 3D-printed enclosures to keep everything cool and organized.

---

## What's in this repo

### Riser topology
How to fit multiple P40s into an R730 without fighting the PCIe bus. Slot assignments, riser card types, bandwidth considerations, and what actually works vs. what looks good on paper.

### Fan control
The R730's default fan behavior is aggressive and loud. This documents how to get sane fan curves while keeping the GPUs cool under sustained inference load — without triggering the iDRAC's thermal protection.

### 3D enclosures
The P40 is a passive card. In a server chassis with directional airflow that's fine — but cable management, card retention, and dust are real issues. STL files and print settings for enclosures that solve this.

---

## Hardware

- **Server:** Dell PowerEdge R730 (dual Xeon E5-2630 v4, 128 GB RAM)
- **GPUs:** Tesla P40 24GB (passive, no blower fan)
- **OS:** Ubuntu 24.04
- **Inference stack:** Ollama

---

## Why

Running large language models locally means owning the hardware. The P40 hits a sweet spot: enough VRAM for serious models (24GB fits most 13B-34B models comfortably, and 2× P40 handles 70B), data center reliability, and secondhand prices that make the math work.

The R730 is a platform that scales — starting with one P40 and expanding to six is a documented path, not an afterthought.

---

## Status

| Component | Status |
|-----------|--------|
| Single P40 installation | ✅ Done |
| Fan control (iDRAC override) | ✅ Done |
| Riser topology documentation | ✅ Done |
| 3D enclosure designs | 🔄 In progress — horizontal stand v1 ✅, cover v1 ✅, STLs available in `enclosure/` |
| 2× P40 configuration | ⏳ Next |
| 3× P40 and beyond | ⏳ Planned |

---

## More from faltland

This is one part of a larger project. More will follow.

---

*Built in the open. Documented as it goes. Nothing hidden except what isn't ready yet.*
