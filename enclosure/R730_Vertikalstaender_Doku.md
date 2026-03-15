# R730 Vertikalständer — Druckdokumentation

## Konzept

Der Dell PowerEdge R730 wird hochkant aufgestellt, zwischen einer Box und einer Couchseite im Heimlabor. Zwei identische Querkufen tragen den Server, heben ihn vom Boden ab und erzeugen einen Schwebeeffekt. Box und Couch übernehmen die seitliche Stabilisierung — zwei Kufen reichen.

## Maße & Referenz

| Maß | Wert | Quelle |
|---|---|---|
| Gehäusebreite Y | 87,3 mm | Dell Spec Sheet |
| Rack-Ear Überstand | ~19,2 mm pro Seite | (Xa - Xb) / 2 |
| Rack-Ear Dicke | 5 mm | gemessen |
| Einbautiefe Ear | 30 mm | gemessen |
| Spalt Couch/Box | 220 mm | gemessen |

## Kufen-Design

**Datei:** `kufe_v16_final.scad`  
**Drucken:** 2× identisch

### Abmessungen
| Element | Maß | Hinweis |
|---|---|---|
| Gesamtlänge | 230 mm | Keil 70 + Quader 90 + Keil 70 |
| Keil links | 70 mm | |
| Mittelquader | 90 mm | ergibt 88mm Innenmaß nach Keilüberlapp |
| Keil rechts | 70 mm | |
| Innenmaß | 88 mm | Server Y 87,3mm + 0,7mm Luft |
| Breite | 50 mm | |
| Keilhöhe | 150 mm | |
| Quaderhöhe | 40 mm | |

### Absatz (Rack-Ear Aufnahme)
| Maß | Wert | Toleranz |
|---|---|---|
| Breite | 31 mm | +1mm auf 30mm Ear |
| Tiefe | 7 mm | +2mm auf 5mm Ear |

## Druckempfehlungen

| Parameter | Empfehlung |
|---|---|
| Material | PETG |
| Infill | 40–50% |
| Wandstärken | 3–4 Perimeter |
| Druckrichtung | liegend (Boden unten) |
| Supports | nicht nötig |

**Warum PETG:** Kombination aus Steifigkeit und leichter Flexibilität. Verträgt Dauerbelastung besser als PLA.

## Montage

1. Zwei Kufen mit Abstand zu Vorder- und Hinterkante positionieren
2. Server von oben einsetzen — Rack-Ear links in den Absatz
3. Couch/Box sichern seitlich — kein Befestigungsmaterial nötig
4. Formschluss hält den Server — keine Schrauben, kein Kleben

## Ergebnis

- Standfläche reduziert von ~70cm Tiefe auf ~9cm Breite
- Server schwebt über dem Boden
- Frontseite vollständig zugänglich
- Airflow unverändert: Front ansaugen → Rear ausblasen

## Entwicklungshistorie

| Version | Änderung |
|---|---|
| v1–v2 | Grundform Quader + Keile |
| v3–v5 | Kantenrundung iteriert |
| v6 | Keile auf 70mm verlängert |
| v7 | Keilhöhe auf 150mm erhöht |
| v8 | Quader auf 88mm (vorher 80mm → zu schmal) |
| v9 | Absatz mit Toleranz: 31×7mm |
| v10 | Oberkante Keile gerundet |
| v11–v15 | Versuche gerade Innenfläche per Polyhedron / linear_extrude — verworfen |
| v16 | Quader auf 90mm → 88mm Innenmaß ✅ — Druckversion |

> **Kritische Erkenntnis:** Keile überlappen je 1mm in den Quader. Formel: **Innenmaß = Quaderbreite − 2mm**. v8–v10 hatten Quader 88mm → nur 86mm Innenmaß → Server (87,3mm) passte nicht. Erst v16 mit Quader 90mm ist korrekt.

## Status

| Schritt | Status |
|---|---|
| Design abgeschlossen (v16) | ✅ |
| Testdrucke & Passform korrigiert | ✅ |
| 2. Kufe drucken | ✅ |
| Server aufstellen | ✅ |
| **Projekt abgeschlossen** | **✅** |

**Ergebnis:** Zwei Kufen reichen — Box und Couch übernehmen die seitliche Stabilisierung. Server steht hochkant, Frontseite zugänglich, Airflow unverändert. Platz gefunden. ✅
