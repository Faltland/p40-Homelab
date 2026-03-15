// Kufe v16 — DRUCKVERSION
// Innenmaß: 88mm (Server Y 87.3mm + 0.7mm Luft)
// Gesamtlänge: 230mm
// Material: PETG, 40-50% Infill, 3-4 Perimeter, liegend drucken
// 2× identisch drucken

r = 4;
$fn = 32;

// --- Quader mit Ausschnitt (Rack-Ear Aufnahme) ---
difference() {
    cube([90, 50, 40]);
    translate([0, -1, 34])
    cube([31, 52, 7]);
}

// --- Keil links (70mm) ---
hull() {
    translate([1,   0, 0]) cube([0.01, 50, 0.01]);
    translate([-70, 0, 0]) cube([0.01, 50, 0.01]);

    translate([1, r, r]) rotate([0,90,0]) cylinder(r=r, h=0.01);
    translate([1, 50-r, r]) rotate([0,90,0]) cylinder(r=r, h=0.01);

    translate([1, r, 150-r]) rotate([0,90,0]) cylinder(r=r, h=0.01);
    translate([1, 50-r, 150-r]) rotate([0,90,0]) cylinder(r=r, h=0.01);
}

// --- Keil rechts (70mm) ---
translate([90, 0, 0])
hull() {
    translate([-1,  0, 0]) cube([0.01, 50, 0.01]);
    translate([70,  0, 0]) cube([0.01, 50, 0.01]);

    translate([-1, r, r]) rotate([0,90,0]) cylinder(r=r, h=0.01);
    translate([-1, 50-r, r]) rotate([0,90,0]) cylinder(r=r, h=0.01);

    translate([-1, r, 150-r]) rotate([0,90,0]) cylinder(r=r, h=0.01);
    translate([-1, 50-r, 150-r]) rotate([0,90,0]) cylinder(r=r, h=0.01);
}

echo("Innenmaß:", 90-2, "mm — Server Y: 87.3mm — Luft: 0.7mm");
echo("Gesamtlänge:", 70+90+70, "mm");
