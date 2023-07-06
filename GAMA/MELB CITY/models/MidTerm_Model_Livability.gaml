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
	file shape_file_tree_canopies <- file("../includes/tree-canopies-public-realm-2018-urban-forest.shp");
	file shape_file_bounds <- file("../includes/bounds.shp");
	geometry shape <- envelope(shape_file_bounds);
	float step <- 1 #mn;
	date starting_date <- date("1919-08-10-00-00-00");
	int nb_people <- 1000;
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16; 
	int max_work_end <- 20; 
	float min_speed <- 1.0 #km / #h;
	float max_speed <- 10.0 #km / #h; 
	graph the_graph;
	
	init {
		create building from: shape_file_buildings with: [type::string(read ("type"))] {
			if type="public_building" or type="house"{
				color <- #blue ;
			}
		}
		create road from: shape_file_roads ;
		the_graph <- as_edge_graph(road);
		
		list<building> residential_buildings <- building where (each.type="residential");
		list<building> industrial_buildings <- building  where (each.type="public_building") ;
		
		create tree_canopy from: shape_file_tree_canopies;

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
	rgb color <- #black;
	aspect base {
		draw shape color: color ;
	}
}

species tree_canopy{
	rgb color;
	aspect base{
		draw shape color:#green;
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
			species tree_canopy aspect: base ;
		}
	}
}