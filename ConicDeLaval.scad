//Conic DeLaval nozzle by buback

//Great Info here: http://www.braeunig.us/space/propuls.htm


//Radii
Re = 40;		//Divergent nozzle exit radius. 
Rt = 5;	 	//Throat radius
Rc = 40; 	//combution chamber radius. 

//Angles
Da = 15; //Divergent section angle. typ 12-18 deg. smaller angle is more efficient but longer and therefore heavier. 15 is standard as a compromise.
Ca = 45; //Convergent section angle. typ 20-45 deg. Not as critical as Da.

Ln = (Re-Rt)*(sin(90)/sin (Da));  //Conic Nozzle divergent section length, as determined by Da
Lc = (Rc-Rt)*(sin(90)/sin(Ca)); //Connic Nozzle convergent section length, as determined by Ca
x = 1.5*Rt;
y= .382*Rt;
z= (1.5-.382)*Rt;

//attempt at bell nozzle
rotate_extrude(convexity = 10, $fn = 100){
translate([Rt,0,0]){//sets throat radius
//hull(){   //comment this out (and one of the brackets on the bottom) to just get the thin walled model
	union(){
	difference(){
		union(){
			translate([.382*Rt,0,0])circle(r=.382*Rt,$fn=80);//the divergent throat
			{
					intersection(){
						translate([1.5*Rt,0,0])circle(r=1.5*Rt,$fn=80);//the convergent throat
						square(1.5*Rt); //isolates convergent radius
					}
					translate([x,0,0]){// the bottom of the combustion chamber
						translate([-(cos(Ca)*x),sin(Ca)*x,0])
						rotate(a=-Ca)
						square([y,Rc*2]);
					}
			}
		}
		{translate([1.5*Rt,0,0])circle(r=(1.5-.382)*Rt,$fn=80); //trims off excess on conv throat
		translate([x,0,0]){ //trims off excess on combustion chamber bottom
			translate([-(cos(Ca)*z),sin(Ca)*z,0])
			rotate(a=-Ca)
			square([Rt/2,Rc*2]);
		}
		translate([Rc,0,0])//Trims off combustion chamber at Rc
		square([Rc,Rc*10]);
		}
	}
	difference(){
		translate([y,0,0]){//Nozzle entension
		translate([-(cos(Da)*y),-sin(Da)*y,0])
		rotate(a=-(90-Da))
		square([Re*5,y]);
		}
		translate([Re,-Re*5,0])//trims nozzle at Re
		square([Re*5,Re*5]);
	}
	}
}
}
//}
