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
	file shape_file_trees <- file("../includes/trees-with-species-and-dimensions-urban-forest.shp");
	file shape_file_bounds <- file("../includes/bounds.shp");
	geometry shape <- envelope(shape_file_bounds);
	float step <- 1 #mn;
	date starting_date <- date("1919-08-10-00-00-00");
	
	map<string,rgb> uselif_color<-["61+ years"::#green, "31-60 years"::#blue, "21-30 years"::#yellow, "11-20 years"::#orange, "6-10 years (>50% canopy)"::#red, "6-10 years (<50% canopy)"::#red];
    map<string,rgb> family_color<- [];
	
	init {
		create building from: shape_file_buildings with: [type::string(read ("type"))] {
			if type="public_building" or type="house"{
				color <- #blue ;
			}
		}
		
		list<building> residential_buildings <- building where (each.type="residential");
		list<building> industrial_buildings <- building  where (each.type="public_building") ;
		
		create tree from: shape_file_trees;
		list<string> families <- remove_duplicates(tree collect each.family);
		loop f over:families{
			if (f!=nil){
			  family_color <+ string(f)::rnd_color(255);
			  	
			}
		}

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

species tree{
	rgb color;
	string family;
	int year_plant;
	int diameter_b;
	string useful_lif;
	aspect base{
		if(cycle+1899>year_plant){
			draw circle(10) color:#green;
		}
		
	}
	
	aspect useful_lif{
		draw circle(10) color:uselif_color[useful_lif];
	}
	aspect family{
		if (family !=nil){
		  draw circle(10) color:family_color[family];	
		}
		
	}
}


experiment Livability type: gui {

	output {
		display city_display_lifespan type: 3d {
			species building aspect: base ;
			species tree aspect: useful_lif ;
			overlay position: { 5, 5 } size: { 180 #px, 100 #px } background: # white  border: #white rounded: true
            {   draw "TREE LIFESPAN" at: { 40#px, 50#px} color: # black font: font("Helvetica", 32, #bold);
            	//for each possible type, we draw a square with the corresponding color and we write the name of the type
                float y <- 100#px;
                loop type over: uselif_color.keys
                {
                    draw circle(10#px) at: { 20#px, y } color: uselif_color[type] border: #white;
                    draw type at: { 40#px, y + 4#px } color: # black font: font("Helvetica", 18, #bold);
                    y <- y + 25#px;
                }

            }
		}
		display city_display_species type: 3d {
			species building aspect: base ;
			species tree aspect: family ;
			overlay position: { 5, 5 } size: { 180 #px, 100 #px } background: # white  border: #white rounded: true
            {   draw "TREE SPECIES" at: { 40#px, 50#px} color: # black font: font("Helvetica", 32, #bold);
            	//for each possible type, we draw a square with the corresponding color and we write the name of the type
                float y <- 100#px;
                loop type over: family_color.keys
                {
                    draw circle(5#px) at: { 20#px, y } color: family_color[type] border: #white;
                    draw type at: { 40#px, y + 4#px } color: # black font: font("Helvetica", 18, #bold);
                    y <- y + 12#px;
                }

            }
		}
	}
}