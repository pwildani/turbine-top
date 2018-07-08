total_height = 16; // mm

base_d = 4; // mm
stem_d = 4; // mm
handle_d = 1; // mm
handle_h = 3; // mm

fin_count = 6;
fin_d1 = handle_d;
fin_h2 = 6; // middle bulge height from base
fin_d = 12; // mm, d2, middle_bulge size
fin_d3 = stem_d;

fin_r = fin_d/2;
twist = 1.8 / fin_count;

epsilon = 0.01;

stem_height = total_height - base_d/2 - handle_h;
fin_h = total_height - base_d/2 - handle_h;


module fin(i) {
    a1 = 0;
    a2 = 360 * twist;
    
    // test points
    color([0, 1, 0, .3]) {
        rotate([0, 0, a1])
        translate([fin_r, 0, fin_h]) {
            cube(.25);
            linear_extrude(.1) text(str(i), size=1);
        }
        
        rotate([0, 0, a2])
        translate([fin_r, 0, 0]) {
            cube(.25);
            linear_extrude(.1) text(str(i), size=1);
        }
    }

}




module base() {
    sphere($fn=32, d=base_d);
}


module stem() {
    // main body
    cylinder($fn=fin_count, d1=stem_d, d2=handle_d, h=stem_height);
    
    // handle
    translate([0, 0, total_height-handle_h-base_d/2-epsilon])
      cylinder($fn=16, d=handle_d, h=handle_h+epsilon);
}

module spinner() {
    base();
    stem();
    for(i=[0 : fin_count]) {
        rotate([0, 0, (i+.5) * 360 / fin_count]) fin(i=i);
    }
}

spinner();

