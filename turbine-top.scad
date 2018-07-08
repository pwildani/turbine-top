total_height = 16; // mm

base_d = 4; // mm
stem_d = 4; // mm
handle_d = 2; // mm
handle_h = 3; // mm

fin_count = 12;
fin_d1 = handle_d;
fin_h2 = 6; // middle bulge height from base
fin_d = 0; // mm, d2, middle_bulge size
fin_d3 = stem_d;
fin_l=.1;
fin_w=25;
fin_t=.1;
fin_resolution_z = 21;
fin_h = stem_height;

fin_r = fin_d/2;
twist = 1.8*360/fin_count;
fin_twist=0;

epsilon = 0.01;

module fin_shape() {
    scale([fin_w, fin_l]) square(1, center=true); //circle($fn=8);
    if(false)
    difference() {
        scale([fin_w, fin_l]) circle($fs=8);
        translate([0, -fin_t])
        scale([fin_w, fin_l]) circle($fs=8);

    }
}

stem_height = total_height - base_d/2 - handle_h;
fin_h = total_height - base_d/2 - handle_h;
fin_scale = [
  for (x=steps(0, fin_resolution_z, fin_h))
     .06 + pow(1-x/fin_h, 2)
];
echo(len(fin_scale));
  
function curve(vec, h, t) = [
  for(i=[0:len(vec)-1])
    [
  // layerheight
  h/len(vec)
  ,
  // scale
  //1//vec[i]
  [1-(i*1/len(vec)), 1-(i*.74/len(vec))],
  ,
  //[0,0,0]
  // rotate
  [0, 0, -t/len(vec)]
  ,
  // translate
  [-fin_d/len(vec), 0 ,0]
  ]
];
fin_curve = curve(fin_scale, fin_h, fin_twist);
  
//echo(fin_curve);
  
function steps(start, n, end) = [start : (end - start) / (n - 1) : end];
function sum(vec, i=0, a=0) = i < len(vec) ? sum(vec, i+1, a+vec[i]) : a;

module fin_extrude(stepdef, twist) {
    // [height, scale, rotate=[x, y, z], offset=[x, y]]
    numsteps = len(stepdef);
    totalheight = stepstart(numsteps);

    function stepheight(i) = i <= 0 ? 0 : stepdef[i][0];
    function stepscale(i) = i <= 0 ? 1 : stepdef[i][1];
    function stepoffx(i) = i <= 0 ? 0 : stepdef[i][3][0] ? stepdef[i][3][0] : 0;
    function stepoffy(i) = i <= 0 ? 0 : stepdef[i][3][1] ? stepdef[i][3][1] : 0;
    function stepr(i) = i <= 0 ? 0 : stepdef[i][2] ? stepdef[i][2]: [0, 0, 0];

    function stepstart(i) = i <= 0 ? 0 : sum([for(j = [0 : i-1]) stepheight(j)]);      
    function steptwist(i) = i <= 0 ? 0 : twist * (stepheight(i) / totalheight);
    function steptwiststart(i) = i <= 0 ? 0 : sum([for(j=[0 : i-1]) steptwist(j)]);
    function steprstart(i) = i <= 0 ? [0, 0, 0] : sum(a=[0,0,0], [for(j = [0: i-1]) stepr(i)]);
        
    function steptx(i) = i <= 0 ? 0 : sum(a=0, [for(j = [0 : i-1]) stepoffx(j)]);
    function stepty(i) = i <= 0 ? 0 : sum(a=0, [for(j=[0:i-1]) stepoffy(j)]);
    

        
    
    module step(i) {
        //echo("step", stepdef[i]);
        //echo(steptx(i), stepty(i));
        scalestart = stepscale(i-1);
        scaleend = stepscale(i) / stepscale(i-1);
        rotate([0, 0, -steptwiststart(i)])

        translate([0, 0, stepstart(i) + stepheight(i)/2])

        scale(scalestart)

            linear_extrude(
                    slices=2,
                    height=stepheight(i),
                    center=true,
                    twist=steptwist(i),
                    scale=[scaleend])

                rotate(steprstart(i))
                translate([steptx(i), stepty(i), 0])

                    children();
        
    }
      
    for (i = [1:numsteps-1]) hull() {step(i-1) children(); step(i) children();}
}


module ring(d) {
    /*difference() {
    cylinder(d=d1, h=h);
    translate([0, 0, -epsilon])
    cylinder(d=d2, h=h+epsilon*2);
    }*/
    
    rotate_extrude() {
        translate([d, 0, 0]) children();
    }
    
}


module fin(i) {
    
    fin_extrude(fin_curve, twist=twist) {
        translate([fin_d, 0, 0])

         {
            fin_shape();
 //   color([.75, .7, .8, 0.2])
 //           scale([fin_w, fin_l])
 //               circle($fn=8, 1);
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
    
    // binding / adapter
    module binding() {
    binding_height = 1;
    binding_d = 0.20 * fin_w;
    translate([0, 0, total_height-base_d/2-handle_h-epsilon-binding_height/2])
       linear_extrude(scale=(handle_d / binding_d), height=binding_height)
            circle($fn=fin_count, d=binding_d);
     translate([0, 0, total_height-base_d/2-handle_h-epsilon-binding_height/2])
       mirror([0, 0, 1])
       linear_extrude(scale=1, height=binding_height)
            circle($fn=fin_count, d=binding_d);
    
    translate([0, 0, total_height-base_d/2-handle_h-epsilon-binding_height*1.5])
       mirror([0, 0, 1])
       linear_extrude(scale=(handle_d / binding_d), height=binding_height)

            circle($fn=fin_count, d=binding_d);
    }
    
    translate([0, 0, -.45]) binding();

}

module shell() {
   
/*
 shell cross section diagram
           .
          /|
         / |
        /  |
       .   |
      /|   |
     /#/   |
    /##|   |
   /##/[h] | [th]
  /##|     | 
 /a1#/a2   |
.---.--.---.
 [t]  d2
  inset+t
    [d/2]
*/
    d = fin_w+2;
    t = 1.4;
    th = stem_height-3;
    h = th/2;
    
    a1 = atan2(th, d/2);
    hy = th / sin(a1);
    hy2 = h / sin(a1);
    inset = h * 1/tan(a1) - t;
    d2 = d/2-t;
    
    slope = 0;
    
    echo(inset=inset, d2=d2, d2alt = d/2-t, a2=a2, a1=a1);
    

    rotate_extrude(){
        translate([0, 0])
    polygon([[d/2, 0],  [d/2-inset, h], [d2, 0]]);
    }
    
    
}




module spinner() {
    //base();
    
    stem();
    
    for(i=[0 : fin_count-1]) {
        rotate([0, 0, (i+.5) * 360 / fin_count]) fin(i=i);
    }
    shell();
    
    // bracing
    b = fin_d-fin_w+(fin_h/fin_resolution_z)+.5;
    //ring(d=b) polygon([[1, 0],[.5,.5],[0, 0]]);
    
    d = fin_d+fin_w/2-(fin_h/fin_resolution_z);
    //ring(d=d) polygon([[1, 0],[.5,.5],[0, 0]]);
}

spinner();

translate([fin_w/2, fin_w/2,])
intersection() {
    translate([-base_d/2, -base_d/2, 0])
    cube([base_d, base_d, base_d/2]);
    base();
}

