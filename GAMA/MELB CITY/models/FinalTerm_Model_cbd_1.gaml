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
	file text_file_population <- file("../includes/data/Demographic_CBD.csv");
	geometry shape <- envelope(shape_file_bounds);
	float step <- 1 #mn;
	field cell <- field(300,300);
	date starting_date <- date("2023-07-09-00-00-00");
	int nb_tram <- 50;
	float min_tram_speed <- 10.0 #km / #h;
	float max_tram_speed <- 26.0 #km / #h;
	int nb_people <- 1000;
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16; 
	int max_work_end <- 20;
	float min_people_speed <- 4.8 #km / #h;
	float max_people_speed <- 8.8 #km / #h;
	int nb_car <- 100;
	float min_car_speed <- 5 #km / #h;
	float max_car_speed <- 40 #km / #h;
	graph footway_graph;
	graph tramway_graph;
	graph car_network_graph;
	float reducefactor<-0.1;
	
	map<int,string> grouptostring<-[1::"0-14", 2::"15-34",3::"35-64", 4::"65-84",5::"Above 85"];
	map<int,rgb> grouptocolor<-[1::#red, 2::#green,3::#blue, 4::#pink,5::#yellow];
	map<int,float> grouptospeed<-[1::3.3 #km / #h, 2::4.5 #km / #h,3::4.5 #km / #h, 4::3.3 #km / #h,5::3.3 #km / #h];
   
	
	map<string,rgb> landuse_color<-["residential"::rgb(231, 111, 81),"university"::rgb(38, 70, 83), "mixed"::rgb(244, 162, 97), "office"::rgb(42, 157, 143), "retail"::rgb(233, 196, 106)
		, "entertainment"::rgb(33, 158, 188),"carpark"::rgb(92, 103, 125),"park"::rgb(153, 217, 140)];
   
	
	init {
		create building from: shape_file_buildings with: [type::string(read ("type"))] ;	
		
		create footway from: shape_file_traffic with: [type::string(read ("highway"))];
		ask footway where (each.type!="footway"){
			do die;
		}
		footway_graph <- as_edge_graph (footway);
		
		create tramway from: shape_file_traffic with: [type::string(read ("highway"))];
		ask tramway where (each.type!="tramway"){
			do die;
		}
		tramway_graph <- as_edge_graph (tramway);
		
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

		list<building> residential_buildings <- building where (each.type="residential" or each.type="mixed");
		list<building> industrial_buildings <- building  where (each.type="work" or each.type="university" or each.type="mixed") ;
		

		//convert the file into a matrix
		matrix data <- matrix(text_file_population);
		//loop on the matrix rows (skip the first header line)
		loop i from: 1 to: data.rows -1{
			//loop on the matrix columns
			loop j from: 0 to: data.columns -1{
				write "data rows:"+ i +" colums:" + j + " = " + data[j,i];
			}	
		}		
	}
	
	reflex pollution_evolution {
		//ask all cells to decrease their level of pollution
		cell <- cell * 0.8;
	
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

species footway{
	string type; 
	rgb color <- rgb(229, 229, 229)  ;
	
	aspect base {
		draw shape color: color;
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
		
	reflex time_to_work when: current_date.hour = start_work and objective = "resting"{
		objective <- "working" ;
		the_target <- any_location_in (working_place);
	}
		
	reflex time_to_go_home when: current_date.hour = end_work and objective = "working"{
		objective <- "resting" ;
		the_target <- any_location_in (living_place); 
	} 
	 
	reflex move when: the_target != nil {
		do goto target: the_target on: footway_graph ; 
		if the_target = location {
			the_target <- nil ;
		}
	}
	
	aspect base {
		draw circle(5) color: grouptocolor[age_group] border: #black;
	}
}

species tramway {
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
		path path_followed <- goto(target: target, on: car_network, recompute_path: false, return_path: true);

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

experiment cbd_digital_twins type: gui {	
	float minimum_cycle_duration<-0.05;
	list<rgb> pal <- palette([ #black, #green, #yellow, #orange, #orange, #red, #red, #red]);
	map<rgb,string> pollutions <- [#green::"Good",#yellow::"Average",#orange::"Bad",#red::"Hazardous"];
	map<rgb,string> legends <- [rgb(231, 111, 81)::"residential",rgb(42, 157, 143)::"office",rgb(244, 162, 97)::"mixed",rgb(233, 196, 106)::"retail",rgb(38, 70, 83)::"university", rgb(33, 158, 188)::"entertainment"];
	font text <- font("Arial", 14, #bold);
	font title <- font("Arial", 18, #bold);
	
	output {
		
		display city_display type: 3d axes: false background: rgb(151, 157, 172) {
			species building aspect: base ;
			species footway aspect: base;
			species people aspect: base;
			species tramway aspect: base;
			species tram aspect: base;
			species car_network aspect: base;
			species car aspect: base;
			
			overlay position: { 50#px,50#px} size: { 1 #px, 1 #px } background: # black border: #black rounded: false
			{
				float y <- 50#px;
				
				draw "legend" at: {0, y} anchor: #top_left  color: #white font: title;
				y <- y + 50#px;
                draw rectangle(40#px, 240#px) at: {20#px, y + 100#px} wireframe: true color: #white;
                loop p over: legends.pairs
                {
                    draw square(40#px) at: { 20#px, y } color: rgb(p.key, 0.8) ;
                    draw p.value at: { 60#px, y} anchor: #left_center color: # white font: text;
                    y <- y + 40#px;
                }
			}
        	
        	mesh cell scale: 9 triangulation: true transparency: 0.4 smooth: 3 above: 0.8 color: pal;
		}
		
	}
}

/* Insert your model definition here */

