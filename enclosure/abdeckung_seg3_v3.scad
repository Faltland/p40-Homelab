// Abdeckung R730 — Segment 3 (Wand) v3
// Sattel-Profil: beide Seiten 6mm heruntergezogen
// Nut bei X=230 → nimmt Feder von Segment 2 auf
// X=0 = freie Wandkante
// ——————————————————————————————————————————

$fn = 64;

laenge  = 230;
breite  = 93;    // 88mm Innenmaß + 2× 2.5mm Gegenrand
hoehe   = 23.6;
r       = 3;

// Absatz (Rack-Ear)
absatz_y = 31;
absatz_z = 6;

// Gegenrand
rand_staerke = 2.5;
rand_tiefe   = 6;

// Nut
nf_breite  = 25;
nf_hoehe   = 3;
nf_tiefe   = 5;
nut_breite = nf_breite + 0.6;
nut_hoehe  = nf_hoehe  + 0.6;
nut_tiefe  = nf_tiefe  + 1;
nut_y      = (breite - nut_breite) / 2;
nut_z      = (hoehe  - nut_hoehe)  / 2;

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
    }

    // ——— Absatz: Rack-Ear ———
    // Y=rand_staerke → hängende Wand (Y=0..2.5) bleibt erhalten
    translate([-1, rand_staerke, -1])
        cube([laenge+2, absatz_y+1, absatz_z+1]);

    // ——— Nut hinten (X=230) ———
    translate([laenge-nf_tiefe, nut_y, nut_z])
        cube([nut_tiefe, nut_breite, nut_hoehe]);

    // ——— Shoulder Screw Vertiefung Knopf 4 ———
    // 586.5mm ab Vorderkante → 126.5mm in Seg3 → X = 230-126.5 = 103.5mm
    // Y = 93-31.5 = 61.5mm (identisch K1-K3)
    translate([103.5, 93-31.5, -1])
        cylinder(r=4.25, h=3.5+1);
}

echo("Segment 3 — Wand v3");
echo("Nut bei X=230, freie Kante bei X=0");
echo("Außenbreite:", breite, "mm — Innenmaß: 88mm");
