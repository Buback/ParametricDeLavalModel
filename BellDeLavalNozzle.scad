/*
DeLaval nozzle by buback
Bezier curve algorithm by donb @ http://www.thingiverse.com/thing:8931
Great Info here: http://www.braeunig.us/space/propuls.htm
*/

//Radii
Re = 20;	//Divergent nozzle exit radius. 
Rt = 1.5;	//Throat radius. Wierd shapes can happen at low expansion ratios
Rc = 10; 	//combution chamber radius. 

//expansion ratio is Area of Exit/Area of Throat
Pi= 3.14159;
Ae=Pi*pow(Re,2);
At=Pi*pow(Rt,2);
Expan=Ae/At;
echo("Area of Exit:",Ae,"Are of Throat:",At,"Expansion Ratio:",Expan);

//Angles
Da = 30; //Divergent section angle to throat. 
Ca = 30; //Convergent section angle to throat. typ 20-45 deg. Not as critical as Da.


Cn= 15; //conic approximation nozzle at 15 deg. typ 12-18 deg. smaller angle is more efficient but longer and therefore heavier. 15 is standard as a compromise.
Ln = (Re-Rt)*(sin(90)/sin (Cn));  //Conic Nozzle divergent section length, as determined by Da
Lc = (Rc-Rt)*(sin(90)/sin(Ca)); //Conic Nozzle convergent section length, as determined by Ca
Lf = 80/100; //Fractional length of bell compared to conic nozzle extension. length is typically 80% for best performance/weight/length

//Scalling factors for throat at Rt
x = 1.5*Rt; //convergent radius * throat radius.
y= .382*Rt; //divergent radius * throat radius. also defines thickess of most walls
z= (1.5-.382)*Rt;

//control points of bezier curve
p0= [0,0];
Hx= Re-(Rt+.382-(.382*cos(Da)));//height of p1 on x axis
p1= [Hx,Hx/tan(Da)];
p2= [Re-Rt,Ln*Lf];

//--------------Rendering-------------
rotate_extrude(convexity = 10, $fn = 100){
	translate([Rt,0,0]){//sets throat radius
	throat();
	convergent();
	difference(){
		divergent();
		trimflat();
	}
	//combustionChamber();
	//strutProfile(); //uncomment for solid support around the nozzle, instead of struts
}
}
struts(6); //produces X number of struts around the throat for support


//--------------Modules-------------
//Nozzle choke- M=1
module throat(){
	difference(){
		union(){
			translate([.382*Rt,0,0])
//the divergent throat
			circle(r=.382*Rt,$fn=80);
				intersection(){
				translate([1.5*Rt,0,0])
//the convergent throat
				circle(r=1.5*Rt,$fn=80);
//isolates convergent radius
				square(1.5*Rt); 
				}
		}
//trims off excess on conv throat
		translate([1.5*Rt,0,0])
		circle(r=(1.5-.382)*Rt,$fn=80); 
//trims off excess on combustion chamber bottom
		translate([x,0,0]){ 
			translate([-(cos(Ca)*z),sin(Ca)*z,0])
			rotate(a=-Ca)
			square([y*3,Rc*2]);
		}
//Trims off combustion chamber at Rc. also in CC module
		translate([Rc-Rt,0,0])
		square([Rc*5,Rc*5]);
	}
}

//---------------
//Nozzle entension- M>1
module divergent(){
	difference(){
		translate([y,0,0]){
		translate([-(cos(Da)*y),-sin(Da)*y,0])
		mirror([0,1,0])
		difference(){
		bezierBell(p0,p1,p2,30);
		translate([cos(Da)*y,-sin(Da)*y,0])
			bezierBell(p0,p1,p2,30);//creates a second bezier to shape the exterior of nozzle
		}
		}
//trims nozzle at Re
		translate([Re-Rt+y,-Re*25,0])
		square([Re*25,Re*25]);
	}
}

//---------------
// the bottom of the combustion chamber- M<1
module convergent(){
	difference(){
		translate([x,0,0]){
			translate([-(cos(Ca)*x),sin(Ca)*x,0])
			rotate(a=-Ca)
			square([y,Rc*5]);
		}
//Trims off combustion chamber at Rc. also in throat module.
		translate([Rc-Rt,0,0])
		square([Rc*5,Rc*5]);
	}
}
//---------------
//makes nozzle flat, for printing
module trimflat(){
	mirror([0,1,0])	
	translate([0,Ln*Lf-5,0])
	square([Re,y+5]);
}

//---------------
module combustionChamber(){
	translate([Rc-Rt,sin(Ca)*Rc+Rt,0])
	square([y,Rc]);
	translate([0-Rt,Rc+sin(Ca)*Rc+Rt,0])
	square ([Rc+y,y]);
}

//---------------
//adds reinforcement around throat
module struts(numbStruts){
	rotate (90, [1,0,0]){
		for ( i = [0 : (numbStruts-1)] ){
		   rotate( i * 360 / numbStruts, [0, 1, 0])
			translate([Rt,0,0])//translates to throat radius
			linear_extrude(height=y, center=true) 
				strutProfile();
		}
	}
}

module strutProfile(){
	difference(){
		hull(){
			polygon(points=[[Rc-Rt,(sin(90-Ca)*((Rc-Rt)/cos(90-Ca))+y)],[y,y+y],[Rc-Rt,y+y]]);
			mirror([0,1,0])
			difference(){
			polygon(points=[p0,[cos(Da)*y,-sin(Da)*y],p1]);
			translate([0,Rc,0])
			square([Rc,Rc]);
					translate([cos(Da)*y,-sin(Da)*y,0])
					bezierBell(p0,p1,p2,30);//creates a bezier to trim strut
			}
		}
		translate([Rc/(Rt*Rt),0,0])
		circle(r=1.5, $fn=20);
	}
}

//---------------
//Parabolic section, for the nozzle extension, as described by a bezier curve
module bezierBell(p0,p1,p2,steps=5) {

	stepsize1 = (p1-p0)/steps;
	stepsize2 = (p2-p1)/steps;

	for (i=[0:steps-1]) {
		assign(point1 = p0+stepsize1*i) 
		assign(point2 = p1+stepsize2*i) 
		assign(point3 = p0+stepsize1*(i+1))
		assign(point4 = p1+stepsize2*(i+1))  {
			assign( bpoint1 = point1+(point2-point1)*(i/steps) )
			assign( bpoint2 = point3+(point4-point3)*((i+1)/steps) ) {
				polygon(points=[bpoint1,bpoint2,p1]);
			}
		}
	}
	polygon(points=[p0,[cos(Da)*y,-sin(Da)*y],p1]);//adds thickness y to first tangent
	polygon(points=[p2,p2+[y,0],p1]);//adds thickness y to second tangent
}
