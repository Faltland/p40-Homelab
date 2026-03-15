// Abdeckung R730 — Segment 1 (Bezel) v4
// Basis: Segment 2 v3 — identisches Sattel-Profil
// Änderungen gegenüber Seg2:
//   - Nut X=0 → Feder (ragt in -X Richtung)
//   - Feder X=230 → Bezel-Ausschnitt (freies Ende)
// ——————————————————————————————————————————

$fn = 64;

laenge  = 230;
breite  = 93;
hoehe   = 23.6;
r       = 3;

// Absatz (Rack-Ear)
absatz_y = 31;
absatz_z = 6;

// Gegenrand
rand_staerke = 2.5;
rand_tiefe   = 6;

// Feder
nf_breite  = 25;
nf_hoehe   = 3;
nf_tiefe   = 5;
nf_y       = (breite - nf_breite) / 2;
nf_z       = (hoehe  - nf_hoehe)  / 2;

// Bezel-Halter-Fuß
bezel_tiefe = 17;
bezel_hoehe = 5;

module grundkoerper() {
    hull() {
        cube([laenge, breite, 0.01]);

        translate([0, r, hoehe - r])
            rotate([0, 90, 0])
            cylinder(r=r, h=laenge);

        translate([0, breite - r, hoehe - r])
            rotate([0, 90, 0])
            cylinder(r=r, h=laenge);
    }
}

difference() {
    union() {
        grundkoerper();

        // ——— Gegenrand Y=0-Seite ———
        translate([0, 0, -rand_tiefe])
            cube([laenge, rand_staerke, rand_tiefe + 0.01]);

        // ——— Gegenrand Y=breite-Seite ———
        translate([0, breite - rand_staerke, -rand_tiefe])
            cube([laenge, rand_staerke, rand_tiefe + 0.01]);

        // ——— Feder vorne (X=0) → ragt in -X Richtung ———
        translate([-nf_tiefe, nf_y, nf_z])
            cube([nf_tiefe, nf_breite, nf_hoehe]);
    }

    // ——— Absatz: Rack-Ear ———
    // Z=-1 sicher → Y=2.5..33.5 überlappt NICHT mit hängenden Wänden (Y=0..2.5, Y=90.5..93)
    // entfernt Bodenfläche vollständig → keine Zwischenwand
    translate([-1, rand_staerke, -1])
        cube([laenge+2, absatz_y+1, absatz_z+1]);

    // ——— Bezel-Ausschnitt hinten (X=230) ———
    // Y nur zwischen hängenden Wänden → Wände bleiben durchgehend
    // Z=-1 → entfernt Bodenfläche vollständig (Y-Bereich schützt hängende Wände)
    translate([laenge-bezel_tiefe, rand_staerke, -1])
        cube([bezel_tiefe+1, breite-2*rand_staerke, bezel_hoehe+1]);

    // ——— Shoulder Screw Vertiefung Knopf 1 ———
    // 4.25cm (42.5mm) ab Vorderkante (X=230-42.5=187.5)
    // 29mm von Innenkante = 31.5mm von Außenkante (Y=61.5mm)
    // ⌀8.5mm, 3.5mm tief
    translate([187.5, 93-31.5, -1])
        cylinder(r=4.25, h=3.5+1);

    // Knopf 2: liegt bei 244.5mm ab Vorderkante → X=-14.5mm → gehört in Seg2!
}

echo("Segment 1 — Bezel v4");
echo("Außenbreite:", breite, "mm — Innenmaß: 88mm");
echo("Feder bei X=0 ragt in -X, Bezel-Ausschnitt bei X=230");
