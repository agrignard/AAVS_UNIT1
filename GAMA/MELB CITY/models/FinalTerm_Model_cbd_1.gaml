/**
* Name: FinalTermModelcbd1
* Based on the internal empty template. 
* Author
* Tags: digital twins
*/

model FinalTermModelcbd1

global {
	file shape_file_buildings <- file("../includes/cbd_buildings.shp");
	file shape_file_traffic <- file("../includes/cbd_traffic_system.shp");
	file shape_file_bounds <- file("../includes/cbd_bounds.shp");
	geometry shape <- envelope(shape_file_bounds);
	float step <- 1 #mn;
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
	graph footway_graph;
	graph tramway_graph;
	
	init {
		create building from: shape_file_buildings with: [type::string(read ("type"))] {
			if type="residential" {
				color <- rgb(231, 111, 81);
			}
			if type="university"{
				color <- rgb(38, 70, 83);
			}
			if type="mixed"{
				color <- rgb(244, 162, 97);
			}
			if type="office"{
				color <- rgb(42, 157, 143);
			}
			if type="retail"{
				color <- rgb(233, 196, 106);
			}
			if type="entertainment"{
				color <- rgb(33, 158, 188);
			}
			if type="carpark"{
				color <- rgb(92, 103, 125);
			}
			if type="park"{
				color <- rgb(153, 217, 140);
			}
		}	
		
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

		list<building> residential_buildings <- building where (each.type="residential"or each.type="mixed");
		list<building> industrial_buildings <- building  where (each.type="work" or each.type="university" or each.type="mixed") ;
		create people number: nb_people {
			speed <- rnd(min_people_speed, max_people_speed);
			start_work <- rnd (min_work_start, max_work_start);
			end_work <- rnd(min_work_end, max_work_end);
			living_place <- one_of(residential_buildings);
			working_place <- one_of(industrial_buildings);
			objective <- "resting";
			location <- any_location_in (living_place);
		}
	}
}

species building {
	string type; 
	rgb color <- rgb(229, 229, 229) ;
	
	aspect base {
		draw shape color: color;
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
		draw circle(5) color: color border: #black;
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


experiment cbd_digital_twins type: gui {	
	float minimum_cycle_duration<-0.05;
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
        	
		}
		
	}
}

/* Insert your model definition here */

