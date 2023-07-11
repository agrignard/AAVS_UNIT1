/**
* Name: FinalTermModelcbd1
* Based on the internal empty template. 
* Author
* Tags: digital twins
*/

model FinalTermModelcbd1

global {
	file shape_file_buildings <- file("../includes/GIS/cbd_buildings.shp");
	file shape_file_traffic <- file("../includes/GIS/cbd_networks.shp");
	file shape_file_bounds <- file("../includes/GIS/cbd_bounds.shp");
	file shape_file_sensors <- file("../includes/GIS/cbd_sensors.shp");
	file text_file_population <- file("../includes/data/Demographic_CBD.csv");
	geometry shape <- envelope(shape_file_bounds);
	float step <- 10 #sec;
	field cell <- field(300,300);
	//date starting_date <- date("2023-07-09-00-00-00");
	date starting_date <- date([2023,7,9,6,0,0]);
	
	int nb_tram <- 0;
	float min_tram_speed <- 10.0 #km / #h;
	float max_tram_speed <- 26.0 #km / #h;
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16; 
	int max_work_end <- 20;
	float min_people_speed <- 4.8 #km / #h;
	float max_people_speed <- 8.8 #km / #h;
	int nb_car <- 100;
	float min_car_speed <- 5 #km / #h;
	float max_car_speed <- 40 #km / #h;
	graph big_graph;
	graph footway_graph;
	graph tramway_graph;
	graph car_network_graph;
	float reducefactor<-0.1;
	
	map<int,string> grouptostring<-[1::"0-14", 2::"15-34",3::"35-64", 4::"65-84",5::"Above 85"];
	map<int,rgb> age_color<-[1::#red, 2::#green,3::#blue, 4::#pink,5::#yellow,5::#black];
	map<int,float> grouptospeed<-[1::3.3 #km / #h, 2::4.5 #km / #h,3::4.5 #km / #h, 4::3.3 #km / #h,5::3.3 #km / #h];
   
	
	map<string,rgb> landuse_color<-["residential"::rgb(231, 111, 81),"university"::rgb(38, 70, 83), "mixed"::rgb(244, 162, 97), "office"::rgb(42, 157, 143), "retail"::rgb(233, 196, 106)
		, "entertainment"::rgb(33, 158, 188),"carpark"::rgb(92, 103, 125),"park"::rgb(153, 217, 140)];
   
	
	//UX/UI
	bool show_building<-true;
	bool show_tram<-true;
	bool show_car<-true;
	bool show_people<-true;
	bool show_network<-true;
	bool show_sensor<-true;
	bool show_heatmap<-true;
	
	
	init {
		create building from: shape_file_buildings with: [type::string(read ("type"))] ;
		
		list<building> residential_buildings <- building where (each.type="residential" or each.type="mixed");
		list<building> industrial_buildings <- building  where (each.type="work" or each.type="university" or each.type="mixed") ;	
		
		create pedestrian_network from: shape_file_traffic with: [type::string(read ("highway"))];
		big_graph <- as_edge_graph (pedestrian_network);
		ask pedestrian_network where (each.type!="footway"){
			do die;
		}
		footway_graph <- as_edge_graph (pedestrian_network);
		
		//create people from the demographic file
		matrix data <- matrix(text_file_population);
		//loop on the matrix rows (skip the first header line)
		loop i from: 0 to: data.rows -1{
			
			create people number:int(data[1,i])/10{
			age_group <- int(i+1);
			speed <- float(data[2,i]);
			location <- any_location_in (one_of(residential_buildings));
			taffic_mode<<+ [int(data[3,i]),int(data[4,i]),int(data[5,i]),int(data[6,i]),int(data[7,i])];
			start_work <- int(data[8,i]);
			end_work <- int(data[9,i]);
			living_place <- one_of(residential_buildings);
			working_place <- one_of(industrial_buildings);
			objective <- "resting";
			}
		}	
		
		create sensor from:shape_file_sensors with:[name:string(read ("name"))];
		
		create tram_network from: shape_file_traffic with: [type::string(read ("highway"))];
		ask tram_network where (each.type!="tramway"){
			do die;
		}
		tramway_graph <- as_edge_graph (tram_network);
		
		create tram number: nb_tram {
			speed <- rnd(min_tram_speed, max_tram_speed);

		}

		create car number: nb_car {
			speed <- rnd(min_car_speed, max_car_speed);
			location <- any_location_in(one_of(building));
			state <- flip(0.75) ? "ok" : "notok";

		}
		create car_network from: shape_file_traffic with: [type::string(read ("highway"))];
		ask car_network where (each.type!="driveway"){
			do die;
		}
		car_network_graph <- as_edge_graph (car_network);
		

		
	}
	
	reflex pollution_evolution {
		//ask all cells to decrease their level of pollution
		cell <- cell * 0.95;
	
		//diffuse the pollutions to neighbor cells
		diffuse var: pollution on: cell proportion: 0.9;
	}
}

species building {
	string type; 
	rgb color <- rgb(229, 229, 229) ;
	
	aspect base {
		draw shape color: landuse_color[type];
	}
}

species pedestrian_network{
	string type; 
	rgb color <- rgb(229, 229, 229)  ;
	
	aspect base {
		draw shape color: color;
	}
}


species sensor{
	string name;
	aspect base {
		draw square(20) color:#black;
	}
}
species people skills:[moving] {
	rgb color <- #yellow ;
	building living_place <- nil ;
	building working_place <- nil ;
	int start_work ;
	int end_work  ;
	string objective ; 
	point the_target <- nil ;
	int age_group;
	list<int> taffic_mode;
		
	reflex time_to_work when: current_date.hour = start_work and objective = "resting"{
		objective <- "working" ;
		the_target <- any_location_in (working_place);
	}
		
	reflex time_to_go_home when: current_date.hour = end_work and objective = "working"{
		objective <- "resting" ;
		the_target <- any_location_in (living_place); 
	} 
	 
	reflex move when: the_target != nil {
		do goto target: the_target  on: big_graph ;
		write "ok it s time to move to " + speed; 
		if the_target = location {
			the_target <- nil ;
		}
	}
	
	aspect age {
		draw circle(5) color: age_color[age_group] border: #black;
	}
}

species tram_network {
	string type; 
	rgb color <- #blue  ;
	
	aspect base {
		draw shape color: color;
	}
}
species tram skills:[moving] {
	int scale<-3;
	
	reflex move when: current_date.hour between(5,24){
		do wander on: tramway_graph;
	}

	aspect base {
		draw box(20*scale, 3*scale,2*scale) rotate: heading color: #green border: #black ;
		draw box(10*scale, 3*scale,2.5*scale) rotate: heading color: #white border: #black ;
	}
}

species car_network {
	string type; 
	rgb color <- #black  ;
	
	aspect base {
		draw shape color: color;
	}
}
species car skills:[moving] {
	int scale<-3;
	point target;
	float leaving_proba <- 0.05;
	string state;
	
	reflex leave when: (target = nil) and (flip(leaving_proba)) {
		target <- any_location_in(one_of(building));
	}
	//Reflex to move to the target building moving on the road network
	reflex move when: target != nil {
	//we use the return_path facet to return the path followed
		path path_followed <- goto(target: target, on: car_network_graph, recompute_path: false, return_path: true);

		//if the path followed is not nil (i.e. the agent moved this step), we use it to increase the pollution level of overlapping cell
		if (path_followed != nil and path_followed.shape != nil) {
			cell[path_followed.shape.location] <- cell[path_followed.shape.location] + 10;					
		}

		if (location = target) {
			target <- nil;
		} }

	aspect base {
		draw box(5*scale, 1*scale,2*scale) rotate: heading color: #blue border: #black ;
	}
}

experiment cbd_digital_twins type: gui autorun:true{	
	float minimum_cycle_duration<-0.05;
	list<rgb> pal <- palette([ #black, #green, #yellow, #orange, #orange, #red, #red, #red]);
	map<rgb,string> pollutions <- [#green::"Good",#yellow::"Average",#orange::"Bad",#red::"Hazardous"];
	map<rgb,string> legends <- [rgb(231, 111, 81)::"residential",rgb(42, 157, 143)::"office",rgb(244, 162, 97)::"mixed",rgb(233, 196, 106)::"retail",rgb(38, 70, 83)::"university", rgb(33, 158, 188)::"entertainment"];
	font text <- font("Arial", 14, #bold);
	font title <- font("Arial", 18, #bold);
	
	output {
		
		display city_display type: 3d axes: false background: rgb(151, 157, 172) {
			

			rotation angle:-21+180;
			camera 'default' location: {1111.786,1109.9386,2688.8238} target: {1111.786,1109.8916,0.0};
			species building aspect: base visible:show_building;
			species pedestrian_network aspect: base visible:show_network;
			species tram_network aspect: base visible:show_network;
			species car_network aspect: base visible:show_network;
			species people aspect: age visible:show_people;
			species tram aspect: base visible:show_tram;
			species sensor aspect:base visible:show_sensor;
			species car aspect: base visible:show_car;
			mesh cell scale: 9 triangulation: true transparency: 0.4 smooth: 3 above: 0.8 color: pal visible:show_heatmap;
			
			
			event "b"  {show_building<-!show_building;}
			event "t"  {show_tram<-!show_tram;}
			event "c"  {show_car<-!show_car;}
			event "n"  {show_network<-!show_network;}
			event "p"  {show_people<-!show_people;}
			event "s"  {show_sensor<-!show_sensor;}
			event "h"  {show_heatmap<-!show_heatmap;}
			
			overlay position: { 50#px,50#px} size: { 1 #px, 1 #px } background: # black border: #black rounded: false
			{
				draw "CBD ToolKIT v1.0" at: {0,0} color: #white font: font("Helvetica", 50, #bold);
				
				draw "Date: " + current_date at: {0,50#px} color: #white font: font("Helvetica", 20, #bold);
				
				float y <- 200#px;
				
				draw "Building LandUse" at: {0, y} anchor: #top_left  color: #white font: title;
				y <- y + 50#px;
                draw rectangle(40#px, 240#px) at: {20#px, y + 100#px} wireframe: true color: #white;
                loop p over: legends.pairs
                {
                    draw square(40#px) at: { 20#px, y } color: rgb(p.key, 0.8) ;
                    draw p.value at: { 60#px, y} anchor: #left_center color: # white font: text;
                    y <- y + 40#px;
                }
                
                float x<-0#px;
                float gapBetweenWord<-100#px;
                
                draw "UI/UX (Press the following button)" at: { x,world.shape.height+75#px} color: #white font: font("Helvetica", 20, #bold);
              
                draw "(b)uilding (" + show_building + ")" at: { x,world.shape.height+100#px} color: #white font: font("Helvetica", 10, #bold);
                x<-x+gapBetweenWord;
                draw "(t)ram (" + show_tram + ")" at: { x,world.shape.height+100#px} color: #white font: font("Helvetica", 10, #bold);
                x<-x+gapBetweenWord;
                draw "(c)ar (" + show_car + ")" at: { x,world.shape.height+100#px} color: #white font: font("Helvetica", 10, #bold);
                x<-x+gapBetweenWord;
                draw "(n)etwork (" + show_network + ")" at: { x,world.shape.height+100#px} color: #white font: font("Helvetica", 10, #bold);
                x<-x+gapBetweenWord;
                draw "(p)eople (" + show_people + ")" at: { x,world.shape.height+100#px} color: #white font: font("Helvetica", 10, #bold);
                x<-x+gapBetweenWord;
                draw "(s)ensor (" + show_people + ")" at: { x,world.shape.height+100#px} color: #white font: font("Helvetica", 10, #bold);
                x<-x+gapBetweenWord;
                draw "(h)eatmap (" + show_heatmap + ")" at: { x,world.shape.height+100#px} color: #white font: font("Helvetica", 10, #bold);
                x<-x+gapBetweenWord;
			}
        	
        	
		}
		
	}
}

/* Insert your model definition here */

