/**
* Name: Movement of the people agents
* Author:
* Description: third part of the tutorial: Road Traffic
* Tags: agent_movement
*/

model tutorial_gis_city_traffic

global {
	file shape_file_buildings <- file("../includes/buildings.shp");
	file shape_file_roads <- file("../includes/roads.shp");
	file shape_file_rail <- file("../includes/tram_trucks.shp");
	file shape_file_bounds <- file("../includes/bounds.shp");
	geometry shape <- envelope(shape_file_bounds);
	float step <- 1 #mn;
	date starting_date <- date("1919-08-10-00-00-00");
	int nb_people <- 1000;
	int nb_tram <- 200;
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16; 
	int max_work_end <- 20; 
	float min_speed <- 1.0 #km / #h;
	float max_speed <- 10.0 #km / #h;
	float min_tram_speed <- 1.0 #km / #h;
	float max_tram_speed <- 26.0 #km / #h;
	graph the_graph;
	graph tram_graph;
	
	init {
		create building from: shape_file_buildings with: [type::string(read ("type"))] {
			if type="public_building" or type="house"{
				color <- #blue ;
			}
		}
		create road from: shape_file_roads ;
		the_graph <- as_edge_graph(road);
		
		create rail from: shape_file_rail with: [type::string(read ("type"))];
		tram_graph <- as_edge_graph (rail where (each.type="tram"));
		
		list<building> residential_buildings <- building where (each.type="residential");
		list<building> industrial_buildings <- building  where (each.type="public_building") ;
		create people number: nb_people {
			speed <- rnd(min_speed, max_speed);
			start_work <- rnd (min_work_start, max_work_start);
			end_work <- rnd(min_work_end, max_work_end);
			living_place <- one_of(residential_buildings);
			working_place <- one_of(industrial_buildings);
			objective <- "resting";
			location <- any_location_in (living_place); 
		}
		
		create tram number: nb_tram {
			speed <- rnd(min_tram_speed, max_tram_speed);

	}
}

}


species building {
	string type; 
	rgb color <- #gray  ;
	
	aspect base {
		draw shape color: color ;
	}
}

species road  {
	rgb color <- #black ;
	aspect base {
		draw shape color: color ;
	}
}

species rail  {
	rgb color <- #red ;
	string type;
	aspect base {
		if(type="tram"){
			draw shape color:#blue ;
		}
		if(type="rail"){
			draw shape color:#green ;
		}
	}
}

species tram skills:[moving] {
	
	reflex move {
		do wander on: tram_graph;
	}

	aspect base {
		draw rectangle(20, 3) rotate: heading color: #green border: #black ;
		draw rectangle(10, 3) rotate: heading color: #white border: #black ;
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
		do goto target: the_target on: the_graph; 
		if the_target = location {
			the_target <- nil ;
		}
	}
	
	aspect base {
		draw circle(10) color: color border: #black;
	}
}


experiment road_traffic type: gui {
	parameter "Shapefile for the buildings:" var: shape_file_buildings category: "GIS" ;
	parameter "Shapefile for the roads:" var: shape_file_roads category: "GIS" ;
	parameter "Shapefile for the bounds:" var: shape_file_bounds category: "GIS" ;	
	parameter "Number of people agents" var: nb_people category: "People" ;
	parameter "Earliest hour to start work" var: min_work_start category: "People" min: 2 max: 8;
	parameter "Latest hour to start work" var: max_work_start category: "People" min: 8 max: 12;
	parameter "Earliest hour to end work" var: min_work_end category: "People" min: 12 max: 16;
	parameter "Latest hour to end work" var: max_work_end category: "People" min: 16 max: 23;
	parameter "minimal speed" var: min_speed category: "People" min: 0.1 #km/#h ;
	parameter "maximal speed" var: max_speed category: "People" max: 10 #km/#h;
	
	output {
		display city_display type: 3d {
			species building aspect: base ;
			species road aspect: base ;
			species rail aspect: base ;
			species people aspect: base ;
			species tram aspect: base ;
		}
	}
}