/*
DeLaval nozzle by buback
Version 3.0
Bezier curve algorithm by donb @ http://www.thingiverse.com/thing:8931
Great Info here: http://www.braeunig.us/space/propuls.htm
*/

//Radii
//Re = 10;							//Divergent nozzle exit radius. 
Rt = 5;	 						//Throat radius. Wierd shapes can happen at low expansion ratios
Rc = 10; 							//combution chamber radius. 

er = 30; //Expansion ratio
Re = Rt*sqrt(er); 						//Define exit radius by expansion ratio. comment out Re def above
echo("Radius of Exit",Re);

//expansion ratio is Area of Exit/Area of Throat
Pi= 3.14159265359;
Ae=Pi*pow(Re,2);
At=Pi*pow(Rt,2);
Expan=Ae/At;						//calculated expansion ratio, for echo verification only
echo("Area of Exit:",Ae);
echo("Area of Throat:",At);
echo("Expansion Ratio:",Expan);

//Angles
Da = 35; 							//Divergent section angle.
Ca = 35; 							//Convergent section angle. typ 20-45 deg. Not as critical as Da.

//other dimensions
Cn= 15; 							//conic approximation nozzle at 15 deg.  typ 12-18 deg. smaller angle is more efficient but longer and therefore heavier. 15 is standard as a compromise.
Ln = (Re-Rt)*(sin(90)/sin (Cn));  				//Conic Nozzle divergent section length, as determined by Da

Lc = (Rc-Rt)*(sin(90)/sin(Ca)); 				//Conic Nozzle convergent section length, as determined by Ca
Lf = 80/100; 							//Fractional length of bell compared to conic nozzle extension

Lcc = exp((.029*ln(pow(Rt*2,2)))+(.47*ln(Rt*2))+1.94); 		//Length of the combustion chamber

//Convergent/divergent radius variables at Radius Rt. y also is the wall thickness 
x = 1.5*Rt;
y= .382*Rt;
z= (1.5-.382)*Rt;

Tcc= 2*y; //thickness of CC walls
w= 2; 		//thickness of struts, so that they print cleanly
h= 1.5; 	//radius of holes in struts

//control points of bezier curve
p0= [0,0];
Hx= Re-(Rt+.382-(.382*cos(Da)));				//height of p1 on x axis
p1= [Hx,Hx/tan(Da)];
p2= [Re-Rt,Ln];

//--------------Rendering-------------

rotate_extrude(convexity = 10, $fn = 100){
	2dEngine();	
}
intersection(){
	rotate_extrude(convexity = 10, $fn = 100)
	translate([Rt,0,0])//sets throat radius
	strutProfile(); 					
	struts(6); 						//produces X number of struts around the throat for support

}


//--------------Modules-------------
//the 2d profile fo the engine
module 2dEngine(){
	translate([Rt,0,0]){					//sets throat radius
		throat();
		convergent();
		if(Tcc>y){
			throatThickness();
		}
		difference(){
			divergent();
			trimflat();
		}
		combustionChamber();
	}
}

//Nozzle throat- M=1
module throat(){
	difference(){
		union(){
			translate([y,0,0])
//the divergent throat
			circle(r=y,$fn=80);
				intersection(){
				translate([x,0,0])
//the convergent throat
				circle(r=x,$fn=80);
//isolates convergent radius
				square(x); 
				}
		}
//trims off excess on conv throat
		translate([x,0,0])
		circle(r=z,$fn=80); 
//trims off excess on combustion chamber bottom
		translate([x,0,0]){ 
			translate([-(cos(Ca)*z),sin(Ca)*z,0])
			rotate(a=-Ca)
			square([y*3,Rc*2]);
		}
		trimCCedge();
	}
}
//---------------
//Trims off combustion chamber at Rc.
module trimCCedge(){
		translate([Rc-Rt+Tcc,0,0])			//+y here connects CC to convergent section
		square([Rc*5,Rc*5]);
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
			bezierBell(p0,p1,p2,30);		//creates a second bezier to shape the exterior of nozzle
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
			square([Tcc,Rc*5]);
		
		}
		trimCCedge();
	}
}

//---------------
//makes nozzle flat, for printing
module trimflat(){
	mirror([0,1,0])	
	translate([0,Ln*Lf,0])
	square([Re,y+Ln-(Ln*Lf)]);
}

//---------------
//the combustion chamber sidewalls
//the CC volume includes the convergent cone. volume depends on combustion time, which depends on propellants used. Length is set by Rt. Rc is not calculated, and therefore the volume is not correct. This is just a placeholder for a proper combustion chamber module.
module combustionChamber(){
thToCC=sin(90-Ca)*((Rt-Rc)/cos(90-Ca));
	translate([Rc-Rt,-thToCC+y,0])
	square([Tcc,Lcc+thToCC]);					//sidewall
	translate([0-Rt,-thToCC+(y/1.001)+(Lcc+thToCC),0])	//1.001 is fudge factor so that CSG generates correctly. Remove when bug goes away.
	square ([Rc+Tcc,Tcc]);//ceiling
}

//---------------
//adds reinforcement struts around throat
module struts(numbStruts){
	rotate (90, [1,0,0]){
		for ( i = [0 : (numbStruts-1)] ){
		   rotate( i * 360 / numbStruts, [0, 1, 0])
			translate([Rt,0,0])			//translates to throat radius
			linear_extrude(height=w, center=true) 
				difference(){
					strutProfile();
					translate([y+(Rc/2),0,0])	//Hole position
					circle(r=h, $fn=20);	//Holes in struts
				}
		}
	}
}

//---------------
////sets throat wall thickness to Tcc+y/2
module throatThickness(){

	intersection(){
					strutProfile();
					translate([y/2,-(Rc*Rt)/2,0])
					square([Tcc,Rc*Rt]);	//sets throat wall thickness to Tcc+y/2
	}
}

module strutProfile(){
	hull(){
		polygon(points=[[Rc-Rt+Tcc,(sin(90-Ca)*((Rc-Rt)/cos(90-Ca))+y+y)],[y,y+y],[Rc-Rt+Tcc,y+y]]);	//Tcc here makes strut 
		mirror([0,1,0])
		difference(){
		polygon(points=[p0,[cos(Da)*y,-sin(Da)*y],p1]);
		translate([cos(Da)*y,-sin(Da)*y+y,0])
		bezierBell(p0,p1,p2,30);	//creates a bezier to trim strut
		}
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
	polygon(points=[p0,[cos(Da)*y,-sin(Da)*y],p1]);		//adds thickness y to first tangent
	polygon(points=[p2,p2+[y,0],p1]);			//adds thickness y to second tangent
}
