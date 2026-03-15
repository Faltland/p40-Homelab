// Abdeckung R730 — Segment 2 (Mitte) v3
// Sattel-Profil: beide Seiten 6mm heruntergezogen
// Y=0-Seite: Rack-Ear Absatz 31×6mm
// Y=88-Seite: Gegenrand 2.5mm × 6mm
// ——————————————————————————————————————————

$fn = 64;

laenge  = 230;
breite  = 93;    // 88mm Innenmaß + 2× 2.5mm Gegenrand
hoehe   = 23.6;
r       = 3;      // Rundungsradius Oberkanten

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

// Nut
nut_breite = nf_breite + 0.6;
nut_hoehe  = nf_hoehe  + 0.6;
nut_tiefe  = nf_tiefe  + 1;
nut_y      = (breite - nut_breite) / 2;
nut_z      = (hoehe  - nut_hoehe)  / 2;

module grundkoerper() {
    hull() {
        // Bodenfläche — eckig (Druckqualität)
        cube([laenge, breite, 0.01]);

        // Oberkante Y=0
        translate([0, r, hoehe - r])
            rotate([0, 90, 0])
            cylinder(r=r, h=laenge);

        // Oberkante Y=breite
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

        // ——— Feder vorne (X=0) → ragt in -X, Richtung Seg1 ———
        translate([-nf_tiefe, nf_y, nf_z])
            cube([nf_tiefe, nf_breite, nf_hoehe]);
    }

    // ——— Absatz: Rack-Ear (Y=0-Seite) ———
    // Beginnt bei Y=rand_staerke — hängende Wand (Y=0..2.5) NICHT berührt
    // Ghost Wall strukturell ausgeschlossen
    translate([-1, rand_staerke, -1])
        cube([laenge+2, absatz_y+1, absatz_z+1]);

    // ——— Nut hinten (X=230) → nimmt Feder von Seg3 auf ———
    translate([laenge-nf_tiefe, nut_y, nut_z])
        cube([nut_tiefe, nut_breite, nut_hoehe]);

    // ——— Shoulder Screw Vertiefung Knopf 2 ———
    // 244.5mm ab Vorderkante → 14.5mm in Seg2 → X = 230-14.5 = 215.5mm
    translate([215.5, 93-31.5, -1])
        cylinder(r=4.25, h=3.5+1);

    // ——— Shoulder Screw Vertiefung Knopf 3 ———
    // 396.5mm ab Vorderkante → 166.5mm in Seg2 → X = 230-166.5 = 63.5mm
    translate([63.5, 93-31.5, -1])
        cylinder(r=4.25, h=3.5+1);
}

echo("Segment 2 — Mitte v3");
echo("Außenbreite:", breite, "mm — Innenmaß: 88mm — je 2.5mm Gegenrand");
echo("Absatz Rack-Ear beginnt bei Y=", rand_staerke, "— kein Ghost Wall");
