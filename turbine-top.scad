total_height = 16; // mm

base_d = 4; // mm
stem_d = 4; // mm
handle_d = 1; // mm
handle_h = 3; // mm

fin_count = 12;
fin_d1 = handle_d;
fin_h2 = 6; // middle bulge height from base
fin_d = 12; // mm, d2, middle_bulge size
fin_d3 = stem_d;
fin_l=.5;
fin_w=3;
fin_resolution_z = 16;
fin_h = stem_height;

fin_r = fin_d/2;
twist = 1.8 / fin_count;

epsilon = 0.01;

stem_height = total_height - base_d/2 - handle_h;
fin_h = total_height - base_d/2 - handle_h;
fin_scale = [
  for (x=steps(0, fin_resolution_z, fin_h))
     .06 + pow(1-x/fin_h, 2)
];
echo(len(fin_scale));
  
function curve(vec, h, t) = [
  for(i=[0:len(vec)-1])
    [h/len(vec)
  ,
  vec[i]
  ,
  //[0,0,0]
  [0, 0, t/len(vec)]
  ]
];
fin_curve = curve(fin_scale, fin_h, 80);
  
echo(fin_curve);
  
function steps(start, n, end) = [start : (end - start) / (n - 1) : end];
function sum(vec, i=0, a=0) = i < len(vec) ? sum(vec, i+1, a+vec[i]) : a;

module fin_extrude(stepdef, twist) {
    // [height, scale, rotate=[x, y, z]]
    numsteps = len(stepdef);
    totalheight = stepstart(numsteps);

    function stepheight(i) = i < 0 ? 0 : stepdef[i][0];
    function stepscale(i) = i < 0 ? 1 : stepdef[i][1];
    function steptx(i) = i < 0 ? 0 : stepdef[i][3][0] ? stepdef[i][3][0] : 0;
    function stepty(i) = i < 0 ? 0 : stepdef[i][3][1] ? stepdef[i][3][1] : 0;
    function stepr(i) = i < 0 ? 0 : stepdef[i][2] ? stepdef[i][2]: [0, 0, 0];

    function stepstart(i) = i <= 0 ? 0 : sum([for(j = [0 : i-1]) stepheight(j)]);      
    function steptwist(i) = i <= 0 ? 0 : twist * (stepheight(i) / totalheight);
    function steptwiststart(i) = i <= 0 ? 0 : sum([for(j=[0 : i-1]) steptwist(j)]);
    function steprstart(i) = i <= 0 ? [0, 0, 0] : sum(a=[0,0,0], [for(j = [0: i-1]) stepr(i)]);
        
    
    module step(i) {
        //echo("step", stepdef[i]);
        //echo(steprstart(i));
        scalestart = stepscale(i-1);
        scaleend = stepscale(i) / stepscale(i-1);
        rotate([0, 0, -steptwiststart(i)])
        translate([steptx(i), stepty(i), stepstart(i) + stepheight(i)/2])
        
        scale([scalestart, scalestart, 1])
            linear_extrude(
                    slices=2,
                    height=stepheight(i),
                    center=true,
                    twist=steptwist(i),
                    scale=scaleend)
                rotate(steprstart(i))
                    children();
        
    }
      
    for (i = [1:numsteps-1]) hull() {step(i-1) children(); step(i) children();}
}


module ring(d1,d2,h) {
    difference() {
    cylinder(d=d1, h=h);
    translate([0, 0, -epsilon])
    cylinder(d=d2, h=h+epsilon*2);
    }
    
}


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
    
    color([.75, .7, .8])
    fin_extrude(fin_curve, twist=twist) {
        translate([fin_d, 0, 0])
        scale([fin_w, fin_l])
        circle($fn=8, 1);
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
    
    // bracing
    ring(d1=32, d2=30, h=2);
}

spinner();

