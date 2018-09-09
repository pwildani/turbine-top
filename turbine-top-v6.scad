total_height = 35; // mm

inch = 25.4;
qinch = inch/4;
epsilon = 0.01;



base_d = qinch; // mm
stem_d = qinch+1+epsilon; // mm
handle_d = 5; // mm
handle_h = 10; // mm


fin_count = 16;
fin_d1 = handle_d;
fin_h2 = 6; // middle bulge height from base
fin_d = 0; // mm, d2, middle_bulge size
fin_d3 = stem_d;
fin_l = .75;
fin_w = 30;
fin_resolution_z = 6;

shell_ratio = 2.2;

fin_r = fin_d/2;
twist = .8*360/fin_count;
fin_twist=0;

binding_height = 2;
binding_d = 0.250 * fin_w;


function finfn(x, y) = -x*8*cos((-y)*90) + 16*x*x*y*y;


module fin_shape() {
    scale([fin_w, fin_l]) square(1, center=true); 
    //circle($fn=8);
    
}

stem_height = total_height - base_d/2 - handle_h;
fin_h = total_height - base_d/2 - handle_h;
fin_scale = [
  for (x=steps(0, fin_resolution_z, fin_h))
     .06 + pow(1-x/fin_h, 2)
];
//echo(len(fin_scale));
  
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


module fin1(i) {
    
    fin_extrude(fin_curve, twist=twist) {
        translate([fin_d, 0, 0])

         {
            fin_shape();
 //   color([.75, .7, .8, 0.2])
 //           scale([fin_w, fin_l])
 //               circle($fn=8, 1);
        }
    };

}

module fin(i, height=1, $fn=8, scale=[fin_h, fin_w]) {
    
    //-.5*cos(.8*180*(x-y)) - cos(.8*180*(y-x));
    // 
    heightmap = [for (x = [0 : 1/$fn : 1], y = [0 : 1/$fn : 1]) finfn(x, y)];

    extrude_heightmap(heightmap, height, size=scale);

    
}



/*

heightmap must be a vector of length $fn*$fn. will be considered as z-heights applied in a square lattice over a size-square surface, in x-major order. 

The height parameter is the thickness of the output.
The size is the x by y square for a scalar, or [x, y] vector (or a [x, y, z-scale] vector if you need to scale the heightmap here instead of at generation time, but that's probably not what you want)

*/
 module extrude_heightmap(heightmap, height=1, size=1, convexity=10) {
    scale = len(size) == 3
        ? [[size[0], 0, 0], [0, size[1], 0], [0, 0, size[2]]]
        : len(size) == 2
        ? [[size[0], 0, 0], [0, size[1], 0], [0, 0, 1]]
        : len(size) == 1
        ? [[size[0], 0, 0], [0, 1, 0], [0, 0, 1]]
     // Scalar size is x by y, not z
        : [[size, 0, 0], [0, size, 0], [0, 0, 1]];
    
    function reverse(list) = [for (i = [len(list)-1:-1:0]) list[i]];
    function zoffset(t, vec) = [for (p = vec) [p[0], p[1], p[2] + t]];

    // point index
    function P(c, r, z) =  c + r*($fn+1) + z*($fn+1)*($fn+1);

    /*
        square facet:
          A: 0, 0     C: 0, 1  
          B: 1, 0     D: 1, 1      
        triangles: ABD ADC
          ABD = [0, 0], [1, 0], [1, 1]
          ADC = [0, 0], [1, 1], [0, 1]
        
    */
    function faces() =
        let(
            cw = [
              [[0, 0], [1, 0], [1, 1]],
              [[0, 0], [1, 1], [0, 1]]
            ],
            ccw = [for (f = cw) reverse(f)],
            bot   = [for (c = [0 : $fn-1], r = [0 : $fn-1], tri = ccw) 
                [for(p = tri) P(c + p[0], r + p[1], 1)]],
            top   = [for (c = [0 : $fn-1], r = [0:$fn-1], tri = cw) 
                [for (p = tri) P(c + p[0], r + p[1], 0)]],
            south = [for (c = [0 : $fn-1], r = [0], tri = ccw)
                [for (p = tri) P(c + p[0], r, p[1])]],
            north = [for (c = [0 : $fn-1], r = [$fn], tri = cw)
                [for (p = tri) P(c + p[0], r, p[1])]],        
            west  = [for (c = [0], r = [0 : $fn-1], tri = ccw)
                [for (p = tri) P(c, r+p[1], p[0])]],
            east = [for(c = [$fn], r = [0 : $fn-1], tri = cw)
                [for (p = tri) P(c, r+p[1], p[0])]]
       )
       concat(top, bot, south, north, east, west);

    function points(heightmap, height) = 
        let(
            bot = [for (c = [0 : $fn], r = [0 : $fn])
                let(x=c/$fn, y=r/$fn, z=heightmap[P(c, r, 0)])
                 scale * [x, y, z]]   
         )
         concat(zoffset(height, bot), bot);
     
    polyhedron(
        points=points(heightmap, height),
        faces=faces(),
        convexity=convexity
    );
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

module shell1() {
   
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
    translate([0, 0, 5])
    {
    d = fin_w+2;
    t = 1.4;
    th = stem_height;
    shell_height = stem_height/shell_ratio;
    h = shell_height;

    d2 = d/2-t;
    inset = h/th * d2 - t;
    
    rotate_extrude(){
        translate([0, 0])
    polygon([[d/2, 0],  [d/2-inset, h], [d2, 0]]);
    }
    
    mirror([0, 0, 1])
    rotate_extrude(){
    
    polygon([[d/2, 0],  [d/2-inset, h], [d2, 0]]);
    }
}
    
    
}

module shell2() {
    
    difference() {
        hull() fins();
        translate([0, 0, -epsilon])
        cylinder(total_height, r=fin_w*.8);
    }
}

module fins() {
    intersection() {
    rotate_extrude()
   union() {
        voff=.2;
        th=fin_h*1.2 + fin_h*voff;
        polygon([for (x = steps(0, 16, 1)) [fin_w*sin(x*x*180), (th- th*(x+voff))]]);
            
    }
            
    
    for(i=[0 : fin_count-1]) {
        translate([0, 0, fin_h]) rotate([0, 90, (i) * 360 / fin_count]) fin(i=i);
    }
    
    }
    

}


module spinner() {
    difference() {
        union() {
        stem();
        fins();

        shell2();
     
        // bracing

        //bracing();
    }

      // room for a bearing at the base
      translate([0, 0, 1]) sphere($fn=16, d=qinch+epsilon);
    }
}

spinner();

//finsfin(1);

module halfbase() {
translate([fin_w/2, fin_w/2,])
intersection() {
    translate([-base_d/2, -base_d/2, 0])
    cube([base_d, base_d, base_d/2]);
    base();
}
}

module bracing() {
b = fin_d-fin_w+(fin_h/fin_resolution_z)+.5;
//ring(d=b) polygon([[1, 0],[.5,.5],[0, 0]]);

d = fin_d+fin_w/2-(fin_h/fin_resolution_z);
ring(d=d) polygon([[1, 0],[-1,2],[0, 0]]);
}

