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
	file shape_file_rail <- file("../includes/Tram_bounds.shp");
	file shape_file_bounds <- file("../includes/bounds.shp");
	geometry shape <- envelope(shape_file_bounds);
	float step <- 1 #sec;
	date starting_date <- date("1919-08-10-00-00-00");
	int nb_tram <- 100;
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
		ask rail{
			if !(world.shape overlaps self ){
				do die;
			}
		}
		ask rail where (each.type="rail"){
			do die;
		}
		tram_graph <- as_edge_graph (rail where (each.type="tram"));
				
		create tram number: nb_tram {
			speed <- rnd(min_tram_speed, max_tram_speed);

	}
}

}


species building {
	string type; 
	rgb color <- #gray  ;
	
	aspect base {
		draw shape color: #gray border:#gray wireframe:true;
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
	int scale<-3;
	
	reflex move {
		do wander on: tram_graph;
	}

	aspect base {
		draw box(20*scale, 3*scale,2*scale) rotate: heading color: #green border: #black ;
		draw box(10*scale, 3*scale,2.5*scale) rotate: heading color: #white border: #black ;
	}
}




experiment Mobility type: gui {	
	float minimum_cycle_duration<-0.05;
	output {
		
		display city_display type: 3d {
			species building aspect: base ;
			species rail aspect: base ;
			species tram aspect: base ;
		}
	}
}