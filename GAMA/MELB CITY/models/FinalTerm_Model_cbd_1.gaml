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
	file shape_file_cbd_traffic <- file("../includes/GIS/ryan/cbd_pedestrian_network_custom.shp");
	file shape_file_bounds <- file("../includes/GIS/cbd_bounds.shp");
	file shape_file_sensors <- file("../includes/GIS/cbd_sensors.shp");
	file point_file_outside_cbd <- file("../includes/GIS/cbd_coming_from_outside.shp");
	file text_file_population <- file("../includes/data/Demographic_CBD.csv");
	file text_file_car <- file("../includes/data/car_cbd.csv");
	file shape_file_trees <- file("../includes/GIS/Tree/cbd_tree.shp");
	
	geometry shape <- envelope(shape_file_bounds);
	float step <- 1 #mn;
	field cell <- field(300,300);
	//date starting_date <- date("2023-07-09-00-00-00");
	date starting_date <- date([2023,7,9,6,0,0]);
	
	int nb_tram <- 50;
	int nb_bike <- 100;
	int nb_bus <- 48;
	float min_tram_speed <- 10.0 #km / #h;
	float max_tram_speed <- 26.0 #km / #h;
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16; 
	int max_work_end <- 20;
	float min_car_speed <- 5 #km / #h;
	float max_car_speed <- 40 #km / #h;

	graph car_network_graph;
	graph tram_network_graph;
	graph bike_network_graph;
	graph pedestrian_network_graph;
	
	float reducefactor<-0.1;
	
	map<int,string> grouptostring<-[1::"0-14", 2::"15-34",3::"35-64", 4::"65-84",5::"Above 85"];
	map<int,rgb> age_color<-[1::rgb(33, 158, 188), 2::rgb(33, 158, 188),3::rgb(33, 158, 188), 4::rgb(33, 158, 188),5::rgb(33, 158, 188),5::rgb(33, 158, 188),6::rgb(33, 158, 188)];
	map<int,float> grouptospeed<-[1::3.3 #km / #h, 2::4.5 #km / #h,3::4.5 #km / #h, 4::3.3 #km / #h,5::3.3 #km / #h];
   
	
	map<string,rgb> landuse_color<-["residential"::rgb(231, 111, 81),"university"::rgb(38, 70, 83), "mixed"::rgb(244, 162, 97), "office"::rgb(42, 157, 143), "retail"::rgb(233, 196, 106)
		, "entertainment"::rgb(33, 158, 188),"carpark"::rgb(92, 103, 125),"park"::rgb(153, 217, 140)];
	map<string,rgb> path_type_color<-["car"::rgb(car_color),"bike"::rgb(bike_color),"tram"::rgb(tram_color),"people"::rgb(people_color)];

   
	
	//UX/UI
	bool show_building<-false;
	bool show_landuse<-false;
	bool show_tram<-true;
	bool show_car<-true;
	bool show_bus<-true;
	bool show_bike<-true;
	bool show_people<-true;
	bool show_network<-true;
	
	//v2
	bool show_sensor<-false;
	bool show_heatmap<-false;
	bool show_tree<-false;
	bool show_tree_family<-false;
	
	
	//VISUAL
	rgb background_color<-rgb(0,0,0);
	rgb text_color<-rgb(255,255,255);
	rgb building_color<-rgb(102,102,102);
	rgb people_color<-rgb(255,222,94);
	rgb car_color<-rgb(244,40,41);
	rgb bus_color<-rgb(30,233,182);
	rgb bike_color<-rgb(217,111,248);
	rgb tram_color<-rgb(0,64,255);
	rgb tree_color<-rgb(0,255,209);
	float network_line_width<-1#px;
	
	
	
	//POLUTION COLOR
	list<rgb> pal <- palette([ #black, #green, #yellow, #orange, #orange, #red, #red, #red]);
	map<rgb,string> pollutions <- [#green::"Good",#yellow::"Average",#orange::"Bad",#red::"Hazardous"];
	map<rgb,string> legends <- [rgb(231, 111, 81)::"residential",rgb(42, 157, 143)::"office",rgb(244, 162, 97)::"mixed",rgb(233, 196, 106)::"retail",rgb(38, 70, 83)::"university", rgb(33, 158, 188)::"entertainment"];
	font text <- font("Arial", 14, #bold);
	font title <- font("Arial", 18, #bold);
	
	//TREE
	//map<string,rgb> uselif_color<-["61+ years"::rgb(161,106,69), "31-60 years"::#blue, "21-30 years"::#yellow, "11-20 years"::#orange, "6-10 years (>50% canopy)"::#red, "6-10 years (<50% canopy)"::#red];
    map<string,rgb> uselif_color<-["61+ years"::rgb(1,40,33), "31-60 years"::rgb(1,75,62), "21-30 years"::rgb(0,104,86), "11-20 years"::rgb(0,135,111), 
    "6-10 years (>50% canopy)"::rgb(0,195,160), "6-10 years (<50% canopy)"::rgb(30,233,182),"1-5 years (<50% canopy)"::rgb(0,255,209),"<1 year"::rgb(173,250,240),''::rgb(255,255,255)];
    map<string,rgb> family_color<- [];
	
	
	//PLOT
	map<rgb,string> legends_pie <- [rgb(71,42,22)::"car",rgb(161,106,69)::"bike", rgb(112,76,51)::"tram",rgb(237,179,140)::"bus",rgb(217,145,93)::"walk", rgb(244,169,160)::"other"];
	map<rgb,string> legend_path <- [rgb (car_color)::"car",rgb(bike_color)::"bike",rgb(tram_color)::"tram", rgb(people_color)::"people",rgb(bus_color)::"bus"];
	
	
	
	init {
		//create building
		create building from: shape_file_buildings with: [type::string(read ("type"))] ;
		
		list<building> residential_buildings <- building where (each.type="residential" or each.type="mixed");
		list<building> industrial_buildings <- building  where (each.type="work" or each.type="university" or each.type="mixed") ;
		list<building> carpark_cbd <- building  where (each.type="residential" or each.type="mixed" or each.type="carpark");
		
		//create traffic system
		create outside_gates from: point_file_outside_cbd;
		create traffic_network from: shape_file_cbd_traffic with: [type::string(read ("type"))];
		list<traffic_network> tramway <- traffic_network where (each.type="tram");
		tram_network_graph <- as_edge_graph (tramway);
		list<traffic_network> pedestrianway <- traffic_network where (each.type="pedestrain");
		pedestrian_network_graph <- as_edge_graph (pedestrianway);
		list<traffic_network> bikeway <- traffic_network where (each.type="pedestrain");
		bike_network_graph <- as_edge_graph (bikeway);
		list<traffic_network> carway <- traffic_network where (each.type="car");
		car_network_graph <- as_edge_graph (carway);
		
		
		
		//create tree_canopy from: shape_file_trees;
		create tree from: shape_file_trees;
		list<string> families <- remove_duplicates(tree collect each.family);
		loop f over:families{
			if (f!=nil){
			  family_color <+ string(f)::rnd_color(255);
			  	
			}
		}
		
		
		//create people from the demographic file
		matrix data_people <- matrix(text_file_population);
		loop i from: 0 to: data_people.rows -1{
			
			create people number:int(data_people[1,i])/10{
			age_group <- int(i+1);
			speed <- float(data_people[2,i]);
			if(age_group=6){
				location <- any_location_in (one_of(outside_gates));
			} else {
				location <- any_location_in (one_of(residential_buildings));
			}
			taffic_mode<<+ [int(data_people[3,i]),int(data_people[4,i]),int(data_people[5,i]),int(data_people[6,i]),int(data_people[7,i])];
			start_work <- int(data_people[8,i]);
			end_work <- int(data_people[9,i]);
			living_place <- one_of(residential_buildings);
			working_place <- one_of(industrial_buildings);
			objective <- "resting";
			}
		}	
		

		create tram number: nb_tram {
		// add loop break function to distribute tram

		}
		create bus number:nb_bus+24*cycle;

		//create car from the car file
		int ratio_of_car<-1000;
		matrix data_car <- matrix(text_file_car);
		loop i from: 0 to: data_car.rows -1{
			create car number: int(data_car[1,i])/ratio_of_car {
			car_group <- int(i+1);
			if(car_group=1){
				location <- any_location_in (one_of(carpark_cbd));
			} else {
				location <- any_location_in (one_of(outside_gates));
			}
			}
		}
		
		
		create bike number:nb_bike;
		
		create sensor from:shape_file_sensors;

		
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
	rgb color;
	
	aspect base {
		draw shape color:building_color;
	}
	
	aspect landuse{
		draw shape color:landuse_color[type];
	}
}

species tree_canopy {
	string type; 
	rgb color;
	
	aspect base {
		draw shape color:tree_color;
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
			draw circle(10) color:tree_color;
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

species traffic_network{
	string type;
	int path_group;
	
	//command display after right click
	user_command "change road type to car" action: change_type1;
	action change_type1{
	type <- "car";
	}
	user_command "change road type to pedestrian" action: change_type2;
	action change_type2{
	type <- "pedestain";
	}
	user_command "change road type to bike" action: change_type3;
	action change_type3{
	type <- "pedestain";
	}
	user_command "change road type to tram" action: change_type4;
	action change_type4{
	type <- "tram";
	}
	
	aspect base {
		draw shape color:path_type_color[type] width:network_line_width;
	}
}
species outside_gates;

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
		do goto target: the_target  on: pedestrian_network_graph ; 
		if the_target = location {
			the_target <- nil ;
		}
	}
	
	aspect base{
		draw circle(4) color: people_color ;
	}
	
	aspect age {
		draw circle(4) color: age_color[age_group] ;
	}
}

species tram skills:[advanced_driving] {
	int scale<-3;
	init {
		vehicle_length <- 33 #m;
		max_speed <- 40 #km / #h;
		max_acceleration <- 3.5;
	}
	
	reflex move when: current_date.hour between(5,24){
		do wander on: tram_network_graph;
	}

	aspect base {
		draw box(20*scale, 3*scale,2*scale) rotate: heading color: rgb(0,64,255) ;
		draw box(10*scale, 3*scale,2.5*scale) rotate: heading color: #white ;
	}
}

species bus skills:[advanced_driving]{
	int scale<-3;
	init{
		vehicle_length <- 15#m ;
		max_speed <- 40 #km / #h;
		max_acceleration <- 3.5;
	}
	int bus_group;
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
		draw rectangle(8*scale, 2*scale) rotate: heading color:bus_color;
	}
}
species car skills:[advanced_driving] {
	int scale<-3;
	init {
		vehicle_length <- 15#m ;
		max_speed <- 40 #km / #h;
		max_acceleration <- 3.5;
	}
	int car_group;
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
		draw rectangle(5*scale, 2*scale) rotate: heading color:car_color ;
	}
}

species bike skills:[advanced_driving] {

	//Reflex to move to the target building moving on the road network
	reflex move {
	do wander on:bike_network_graph;
	}

	aspect base {
		draw triangle(10) rotate: heading +90 color:bike_color ;
	}
}


experiment cbd_toolkit_virtual type: gui autorun:true virtual:true{	
	float minimum_cycle_duration<-0.05;
	output {
		
		display Screen1 type: 3d axes: false background:background_color virtual:true{
			rotation angle:-21;
			
			
			species building aspect: base visible:show_building;
			species building aspect: landuse visible:show_landuse;
			species traffic_network aspect: base visible:show_network;
			species people aspect: base visible:show_people;
			species tram aspect: base visible:show_tram;
			species sensor aspect:base visible:show_sensor;
			species car aspect: base visible:show_car;
			species bus aspect: base visible:show_bus;
			species bike aspect: base visible:show_bike;
			species tree aspect: useful_lif visible:show_tree;
		    species tree aspect: family visible:show_tree_family;
			mesh cell scale: 9 triangulation: true transparency: 0.4 smooth: 3 above: 0.8 color: pal visible:show_heatmap;
			
			event "e"  {show_tree<-!show_tree;}
			event "f"  {show_tree_family<-!show_tree_family;}
			event "l"  {show_landuse<-!show_landuse;}
			event "t"  {show_tram<-!show_tram;}
			event "c"  {show_car<-!show_car;}
			event "b"  {show_bike<-!show_bike;}
			event "u"  {show_bus<-!show_bus;}
			event "n"  {show_network<-!show_network;}
			event "p"  {show_people<-!show_people;}
			event "s"  {show_sensor<-!show_sensor;}
			event "h"  {show_heatmap<-!show_heatmap;}
			
			overlay position: { 50#px,50#px} size: { 1 #px, 1 #px } background: # black border: #black rounded: false
			{
				draw "CBD ToolKIT v1.0" at: {0,0} color: text_color font: font("Verdana", 50, #bold);
				
				draw "Date: " + current_date at: {0,50#px} color: text_color font: font("Helvetica", 20, #bold);
				
                
                point UX_Position<-{world.shape.width*1.25,0#px};
                float x<-UX_Position.x;
                float y<-UX_Position.y;
        
                float gapBetweenWord<-25#px;
                float uxTextSize<-20.0;
                
                draw "UI/UX" at: { x,y} color: text_color font: font("Helvetica", uxTextSize*2, #bold);
                y<-y+gapBetweenWord;
                draw "tr(e)e (" + show_tree + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(f)amily (" + show_tree + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                y<-y+gapBetweenWord;
                draw "(l)anduse (" + show_landuse + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(t)ram (" + show_tram + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(c)ar (" + show_car + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "b(u)s (" + show_bus + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                 draw "(b)ike (" + show_bike + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(n)etwork (" + show_network + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(p)eople (" + show_people + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                y<-y+gapBetweenWord;
                draw "(s)ensor (" + show_sensor + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(h)eatmap (" + show_heatmap + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                
                
                draw "MODE" at: { 60#px, y} color: text_color  font: font("Helvetica", 30, #bold);
                y <- y + 40#px;
                loop z over: legend_path.pairs
                {
                	draw circle(15#px) at: { 20#px, y} color: rgb(z.key, 0.8) ;
                	draw z.value at: { 60#px, y} color: rgb(z.key, 0.8)  font: font("Helvetica", 30, #bold);
                    y <- y + 40#px;
                }
                
                if (show_landuse){
                	y <- y + 40#px;
                	draw "LANDUSE" at: { 60#px, y} color: text_color  font: font("Helvetica", 30, #bold);
                	y <- y + 40#px;
                	loop l over: landuse_color.pairs
                    {
                	draw square(15#px) at: { 20#px, y} color: rgb(l.value, 0.8) ;
                	draw l.key at: { 60#px, y} color: rgb(l.value, 0.8)  font: font("Helvetica", 30, #bold);
                    y <- y + 40#px;
                    }
                	
                }
                
                if(show_tree){
                	y <- y + 40#px;
                	draw "TREE LIFESPAN" at: { 60#px, y} color: text_color font: font("Helvetica", 30, #bold);
                	y <- y + 40#px;
	            	//for each possible type, we draw a square with the corresponding color and we write the name of the type
	                loop type over: uselif_color.keys
	                {
	                    
	                    if(type=''){
	                     draw circle(10#px) at: { 20#px, y } color: uselif_color[type] border: #white;
	                     draw "Unknown" at: { 40#px, y + 4#px } color:text_color font: font("Helvetica", 18, #bold);
	                     y <- y + 25#px;	
	                    }else{
	                    	draw circle(10#px) at: { 20#px, y } color: uselif_color[type] border: #white;
	                        draw type at: { 40#px, y + 4#px } color:text_color font: font("Helvetica", 18, #bold);
	                        y <- y + 25#px;
	                    }
	                    
	                }
                }
                if (show_tree_family){
                	 y <- y + 40#px;
                	 draw "TREE SPECIES" at: { 60#px, y} color: text_color font: font("Helvetica", 32, #bold);
            		//for each possible type, we draw a square with the corresponding color and we write the name of the type
   					y <- y + 40#px;
	                loop type over: family_color.keys
	                {
	                    draw circle(5#px) at: { 20#px, y } color: family_color[type] border: #white;
	                    draw type at: { 40#px, y + 4#px } color: text_color font: font("Helvetica", 18, #bold);
	                    y <- y + 18#px;
	                }
                	
                }
               
                
			}	
		}
		
		
		
		display Screen2 type: 2d virtual:true background:background_color
		{
			overlay position: { 50#px,50#px} size: { 1 #px, 1 #px } background: # black border: #black rounded: false
			{
			    draw "CBD ToolKIT v1.0" at: {0,0} color: text_color font: font("Helvetica", 50, #bold);
			    draw "Date: " + current_date at: {0,50#px} color: text_color font: font("Helvetica", 20, #bold);
			}
			
			
			chart "Mode of Transport proportion" type: pie style: ring background: background_color color: rgb(236,102,45) label_text_color: rgb(236,102,45)  axes: #red  title_font: font( 'BrownPro', 32.0, #plain)
			tick_font: font('BrownPro' , 14, #plain) label_font: font('BrownPro', 32 #plain) x_label: 'Nice Xlabel' y_label:
			'Nice Ylabel' size:{0.42,0.42} position:{0,0.1}  label_background_color: background_color tick_line_color: rgb(255,255,255)
			legend_font: font('BrownPro' , 14, #plain) 
			
			{
				data "Car" value: (length(car)) color: rgb(71,42,22);
				data "Tram" value: (length(tram)) color: rgb(112,76,51);
				data "Bike" value: (-1) color: rgb(161,106,69);
				data "Walk" value: (length(people)) color: rgb(217,145,93);
				data "Bus" value: (-1) color: rgb(237,179,140);
				data "Other" value:(-1) color: rgb(244,216,189);
				
			}
			
			chart "Pollution Level" type:histogram   size:{0.42,0.42} position:{0.55,0.1} background: background_color color: rgb(236,102,45)
			tick_font: font('BrownPro' , 14, #plain) label_text_color: rgb(236,102,45) title_font: font( 'BrownPro', 32.0, #plain) 
			label_font: font('BrownPro', 14 #plain) legend_font: font('BrownPro' , 14, #plain) 
			x_serie_labels: ["categ1","Mode of Transport"]
			style:"3d"
			series_label_position: xaxis
			{
				data "Walk" value:(100+cycle)
				accumulate_values: true						
			    color:rgb(217,145,93);
			    
				data "Bike" value:(100+cycle)
				accumulate_values: true						
				color: rgb(161,106,69);
			    
				data "Tram" value:(24*55*1+cycle)
				accumulate_values: true						
				color: rgb(112,76,51);
				
				data "Car" value:(length(car)*3)
				accumulate_values: true						
				color: rgb(71,42,22);
				
				data "Reduced by Trees" value:(length(tree_canopy)*1)
				accumulate_values: true						
				color: rgb(244,216,189);
			}
			
			chart "Demography" type: pie style: ring background: background_color color: rgb(236,102,45) label_text_color: rgb(236,102,45)  axes: #red  title_font: font( 'BrownPro', 32.0, #plain)
			tick_font: font('BrownPro' , 14, #plain) label_font: font('BrownPro', 32 #plain) x_label: 'Nice Xlabel' y_label:
			'Nice Ylabel' size:{0.42,0.42} position:{0,0.55}  label_background_color: background_color tick_line_color: rgb(255,255,255)
			legend_font: font('BrownPro' , 14, #plain) 
			
			{
				data "Age 0-14" value: (length(people)*0.034) color: rgb(71,42,22);
				data "Age 15-34" value: (length(people)*0.7) color: rgb(112,76,51);
				data "Age 35-64" value: (length(people)*0.23) color: rgb(161,106,69);
				data "Age 65-84" value: (length(people)*0.029) color: rgb(217,145,93);
				data "Above 85" value: (length(people)*0.007) color: rgb(237,179,140);
				data "Living outside cbd" value:(length(people)*0.5+cycle) color: rgb(244,216,189);
				
			}
			
			chart "Tree Canopy Coverage" type:histogram   size:{0.42,0.42} position:{0.55,0.55} background: background_color color: rgb(236,102,45)
			tick_font: font('BrownPro' , 14, #plain) label_text_color: rgb(236,102,45) title_font: font( 'BrownPro', 32.0, #plain) 
			label_font: font('BrownPro', 14 #plain)  legend_font: font('BrownPro' , 14, #plain) 
			x_serie_labels: ["categ1","Mode of Transport"]
			style:"3d"
			series_label_position: xaxis
			{
				data "1743" value:(length(tree_canopy)*20)
				accumulate_values: true						
			    color:rgb(217,145,93);
			    
				data "1900" value:(length(tree_canopy)*3)
				accumulate_values: true						
				color: rgb(161,106,69);
			    
				data "Now" value:(length(tree_canopy)*5)
				accumulate_values: true						
				color: rgb(112,76,51);
				
				data "Try it!" value:(length(tree_canopy)*8)
				accumulate_values: true						
				color: rgb(71,42,22);
				
				data "2040" value:(length(tree_canopy)*10)
				accumulate_values: true						
				color: rgb(244,216,189);
			}


		}
	}
}


experiment cbd_toolkit_desktop type: gui autorun:true parent:cbd_toolkit_virtual{	
	float minimum_cycle_duration<-0.05;
	
	output{
		display table parent:Screen1{}
		display screen parent:Screen2{}
	}
}


experiment cbd_toolkit_demo type: gui autorun:true parent:cbd_toolkit_virtual{	
	float minimum_cycle_duration<-0.05;
	
	output{
		display table parent:Screen1 fullscreen:0{
			camera 'default' location: {1111.786,1109.9386,2688.8238} target: {1111.786,1109.8916,0.0};
		}
		display screen parent:Screen2 fullscreen:1{}
	}
}




/* Insert your model definition here */

