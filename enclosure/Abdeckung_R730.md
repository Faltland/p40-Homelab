# Abdeckung R730 — Projektdokumentation

## Kontext

Der Dell PowerEdge R730 steht hochkant auf selbstgedruckten Kufen (kufe_v16_final.scad). Die schmale Oberseite (Y-Achse des liegenden Servers) zeigt nach oben und wird mit einer dreiteiligen Abdeckung versehen — Ästhetik und Staubschutz.

---

## Maße & Referenz

| Parameter | Wert | Herkunft |
|---|---|---|
| Servertiefe Zb | 684mm | Dell Spec Sheet |
| Gehäusebreite Y | 87,3mm | Dell Spec Sheet |
| Xa | 482,4mm | Dell Spec Sheet |
| Xb | 444,0mm | Dell Spec Sheet |
| Bezel-Halter Überstand | (Xa-Xb)/2 = 19,2mm | berechnet |
| Rack-Ear Dicke | 5mm | gemessen |
| Rack-Ear Einbautiefe | 30mm | gemessen |
| Bezel-Halter Tiefe | 17mm | gemessen |
| Bezel-Halter Höhe | 5mm | gemessen |

---

## Abdeckung — Spec

| Parameter | Wert | Anmerkung |
|---|---|---|
| Gesamtlänge | 690mm | 684mm + 6mm Überstand Wandseite |
| Außenbreite | 93mm | 88mm Innenmaß + 2× 2.5mm Gegenrand |
| Innenmaß | 88mm | Y 87.3mm + 0.7mm Toleranz |
| Gesamthöhe | 23.6mm | 19.3mm + 4.3mm → bündig mit Bezel-Halterung |
| Segmente | 3 × 230mm | — |
| Verbindung | Nut + Feder | — |
| Material | PETG | 40–50% Infill, 3–4 Perimeter |
| Druckrichtung | liegend | Deckfläche oben |

---

## Profil (Querschnitt)

```
←——————————— 93mm ————————————→
┌─────────────────────────────┐  ← Oberfläche gerundet (r=3mm)
│                             │
└─┐  Rack-Ear Absatz      ┌───┘
  │  31×6mm               │  ← beide Seiten 6mm herunter
  │  (Y=2.5 bis Y=33.5)   │     2.5mm Wandstärke
```

- Y=0 bis 2.5mm → hängende Wand (Gegenrand)
- Y=2.5 bis 33.5mm → Rack-Ear Absatz (31×6mm, 1:1 von Kufe v16)
- Y=33.5 bis 90.5mm → Auflagefläche
- Y=90.5 bis 93mm → Gegenrand

---

## Nut + Feder

| Parameter | Wert |
|---|---|
| Feder | 25mm × 3mm × 5mm (Y × Z × X) |
| Nut | 25.6mm × 3.6mm × 5mm (+0.3mm Toleranz je Seite) |
| Position | zentriert in Y und Z |

---

## Segmente

| Segment | X=0 | X=230 | Besonderheit |
|---|---|---|---|
| Seg 1 — Bezel | Feder (ragt in -X) | Bezel-Ausschnitt (freie Kante) | Bezel-Ausschnitt: 17mm tief, nur Innenbreite, Z=0 nach oben |
| Seg 2 — Mitte | Feder (ragt in -X) | Nut | — |
| Seg 3 — Wand | freie Kante | Nut | — |

**Reihenfolge auf dem Server:**
```
Bezel [Seg1: Feder←] ←Nut— [Seg2: Feder←] ←Nut— [Seg3: frei] Wand
```

---

## Shoulder Screws (Pilzköpfe)

Vier Shoulder Screws (10-32, 7/16") befestigen die Rack-Schienen am Chassis. Sie ragen 3mm über das Chassis und müssen in Taschen der Unterseite aufgenommen werden.

| Parameter | Wert |
|---|---|
| Kopfdurchmesser gemessen | 7mm |
| Ausschnitt Durchmesser | 8.5mm (⌀7 + 1.5mm Toleranz) |
| Tiefe | 3.5mm (3mm + 0.5mm Toleranz) |
| Y-Position | 61.5mm (29mm von Innenkante = 31.5mm von Außenkante) |

**Positionen** (Referenz: Vorderkante Seg1 = X=230):

| Knopf | Ab Vorderkante | Segment | Lokales X |
|---|---|---|---|
| K1 | 42.5mm | Seg1 | 187.5mm |
| K2 | 244.5mm | Seg2 | 215.5mm |
| K3 | 396.5mm | Seg2 | 63.5mm |
| K4 | 586.5mm | Seg3 | 103.5mm |

Abstände entsprechen Dell-Standard-Rack-Positionen in Zoll: 8" (202mm), 6" (152mm), 7.5" (190mm).

---

## Kritische Geometrie-Regeln (hart erarbeitet)

- **Absatz-Schnitt** beginnt bei `Y=rand_staerke` (2.5mm) — nie bei Y=-1, sonst wird die hängende Wand weggeschnitten
- **Absatz Z=-1** ist sicher weil Y-Zone (2.5..33.5) nicht mit hängenden Wänden überlappt → entfernt Bodenfläche vollständig, keine Zwischenwand
- **Bezel-Ausschnitt** auf `Y=rand_staerke..breite-rand_staerke` begrenzt → hängende Wände laufen durchgehend bis Vorderkante
- **Ghost Walls** entstehen durch koplanare Flächen → immer 1mm Überstand an Außenflächen

---

## Dateien

| Datei | Inhalt | Status |
|---|---|---|
| abdeckung_seg1_v4.scad | Bezel-Segment | ✅ Testdruck erfolgreich |
| abdeckung_seg2_v3.scad | Mittelsegment | ✅ druckfertig |
| abdeckung_seg3_v3.scad | Wand-Segment | ✅ druckfertig |

---

## Drucker

Creality K2 mit CFS (Multi-Filament) — Druckbett ausreichend für 230mm Segmente. PETG, 40–50% Infill, 3–4 Perimeter, liegend drucken.
