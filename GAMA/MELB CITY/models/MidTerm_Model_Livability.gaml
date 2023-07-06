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
	file shape_file_tree_canopies <- file("../includes/tree-canopies-bounds.shp");
	file shape_file_bounds <- file("../includes/bounds.shp");
	geometry shape <- envelope(shape_file_bounds);
	float step <- 1 #mn;
	date starting_date <- date("1919-08-10-00-00-00");

	
	init {
		create building from: shape_file_buildings with: [type::string(read ("type"))] {
			if type="public_building" or type="house"{
				color <- #blue ;
			}
		}
		
		list<building> residential_buildings <- building where (each.type="residential");
		list<building> industrial_buildings <- building  where (each.type="public_building") ;
		
		create tree_canopy from: shape_file_tree_canopies;

	}
}


species building {
	string type; 
	rgb color <- #gray  ;
	
	aspect base {
		draw shape color: #gray wireframe:true border:#gray ;
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


experiment Livability type: gui {

	output {
		display city_display type: 3d {
			species building aspect: base ;
			species tree_canopy aspect: base ;
		}
	}
}