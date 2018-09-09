cylinder(h=40,d=12);
translate([0, 0, -15]);
mirror([0, 0, 1])
linear_extrude(height=15, scale=.8) circle(d=12);