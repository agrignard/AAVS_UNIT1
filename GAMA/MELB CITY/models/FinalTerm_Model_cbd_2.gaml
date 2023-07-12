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
	file point_file_outside_cbd <- file("../includes/GIS/cbd_coming_from_outside.shp");
	file text_file_population <- file("../includes/data/Demographic_CBD.csv");
	file text_file_car <- file("../includes/data/car_cbd.csv");
	
	//CANOPY
	file shape_file_trees_2014 <- file("../includes/GIS/Tree/cbd_tree_canopy_2014.shp");
	file shape_file_trees_2016 <- file("../includes/GIS/Tree/cbd_tree_canopy_2016.shp");
	file shape_file_trees_2018 <- file("../includes/GIS/Tree/cbd_tree_canopy_2018.shp");
	file shape_file_trees_2021 <- file("../includes/GIS/Tree/cbd_tree_canopy_2021.shp");
	
	geometry shape <- envelope(shape_file_bounds);
	float step <- 1 #sec;
	field cell <- field(300,300);
	//date starting_date <- date("2023-07-09-00-00-00");
	date starting_date <- date([2023,7,9,6,0,0]);
	
	int nb_tram <- 0;
	int nb_bike <- 100;
	float min_tram_speed <- 10.0 #km / #h;
	float max_tram_speed <- 26.0 #km / #h;
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16; 
	int max_work_end <- 20;
	float min_car_speed <- 5 #km / #h;
	float max_car_speed <- 40 #km / #h;
	graph big_graph;
	graph footway_graph;
	graph tramway_graph;
	graph car_network_graph;
	float reducefactor<-0.1;
	
	map<int,string> grouptostring<-[1::"0-14", 2::"15-34",3::"35-64", 4::"65-84",5::"Above 85"];
	map<int,rgb> age_color<-[1::rgb(33, 158, 188), 2::rgb(33, 158, 188),3::rgb(33, 158, 188), 4::rgb(33, 158, 188),5::rgb(33, 158, 188),5::rgb(33, 158, 188),6::rgb(33, 158, 188)];
	map<int,float> grouptospeed<-[1::3.3 #km / #h, 2::4.5 #km / #h,3::4.5 #km / #h, 4::3.3 #km / #h,5::3.3 #km / #h];
   
	
	map<string,rgb> landuse_color<-["residential"::rgb(231, 111, 81),"university"::rgb(38, 70, 83), "mixed"::rgb(244, 162, 97), "office"::rgb(42, 157, 143), "retail"::rgb(233, 196, 106)
		, "entertainment"::rgb(33, 158, 188),"carpark"::rgb(92, 103, 125),"park"::rgb(153, 217, 140)];
   
	
	//UX/UI
	bool show_building<-false;
	bool show_tram<-true;
	bool show_car<-true;
	bool show_bike<-true;
	bool show_people<-true;
	bool show_network<-true;
	
	//v2
	bool show_sensor<-false;
	bool show_heatmap<-false;
	bool show_tree<-false;
	
	
	//VISUAL
	rgb background_color<-rgb(251,227,190);
	rgb text_color<-rgb(236,102,44);
	rgb building_color<-rgb(236,102,44);
	rgb people_color<-rgb(13,13,7);
	rgb car_color<-rgb(231, 44, 17);
	rgb bike_color<-rgb(22,121,171);
	rgb tram_color<-rgb(15,135,82);
	rgb tree_color<-rgb(173,255,47);
	float network_line_width<-4#px;
	
	//TREE CANOPY
	map<int,rgb> treeColor <- [2014::rgb(173,255,47),2016::rgb(0,250,150),2018::rgb(102,205,170),2021::rgb(0,139,139)];
	
	
	
	//POLUTION COLOR
	list<rgb> pal <- palette([ #black, #green, #yellow, #orange, #orange, #red, #red, #red]);
	map<rgb,string> pollutions <- [#green::"Good",#yellow::"Average",#orange::"Bad",#red::"Hazardous"];
	map<rgb,string> legends <- [rgb(231, 111, 81)::"residential",rgb(42, 157, 143)::"office",rgb(244, 162, 97)::"mixed",rgb(233, 196, 106)::"retail",rgb(38, 70, 83)::"university", rgb(33, 158, 188)::"entertainment"];
	font text <- font("Arial", 14, #bold);
	font title <- font("Arial", 18, #bold);
	
	
	//PLOT
	map<rgb,string> legends_pie <- [rgb(71,42,22)::"car",rgb(161,106,69)::"bike", rgb(112,76,51)::"tram",rgb(237,179,140)::"bus",rgb(217,145,93)::"walk", rgb(244,169,160)::"other"];
	map<rgb,string> legend_path <- [rgb (car_color)::"car",rgb(bike_color)::"bike",rgb(tram_color)::"tram", rgb(people_color)::"peoplel"];
	
	
	
	init {
		create building from: shape_file_buildings with: [type::string(read ("type"))] ;
		
		list<building> residential_buildings <- building where (each.type="residential" or each.type="mixed");
		list<building> industrial_buildings <- building  where (each.type="work" or each.type="university" or each.type="mixed") ;
		list<building> carpark_cbd <- building  where (each.type="residential" or each.type="mixed" or each.type="carpark");
		
		create outside_gates from: point_file_outside_cbd;
		
		create tree_canopy from: shape_file_trees_2014{
			year<-2021;
		}
		create tree_canopy from: shape_file_trees_2018{
			year<-2018;
		}
		create tree_canopy from: shape_file_trees_2016{
			year<-2016;
		}
		create tree_canopy from: shape_file_trees_2014{
			year<-2014;
		}
		
		
		
		create pedestrian_network from: shape_file_traffic with: [type::string(read ("highway"))];
		big_graph <- as_edge_graph (pedestrian_network);
		ask pedestrian_network where (each.type!="footway"){
			do die;
		}
		footway_graph <- as_edge_graph (pedestrian_network);
		
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
		
		create sensor from:shape_file_sensors with:[name:string(read ("name"))];
		
		create tram_network from: shape_file_traffic with: [type::string(read ("highway"))];
		ask tram_network where (each.type!="tramway"){
			do die;
		}
		tramway_graph <- as_edge_graph (tram_network);
		
		create tram number: nb_tram {
		// add loop break function to distribute tram

		}

		//create car from the car file
		matrix data_car <- matrix(text_file_car);
		loop i from: 0 to: data_car.rows -1{
			create car number: int(data_car[1,i])/100 {
			car_group <- int(i+1);
			if(car_group=1){
				location <- any_location_in (one_of(carpark_cbd));
			} else {
				location <- any_location_in (one_of(outside_gates));
			}
			}
		}
		
		create car_network from: shape_file_traffic with: [type::string(read ("highway"))];
		ask car_network where (each.type!="driveway"){
			do die;
		}
		car_network_graph <- as_edge_graph (car_network);
		
		
		create bike number:nb_bike;
		

		
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
}

species tree_canopy {
	string type; 
	rgb color;
	int year;
	
	aspect base {
		draw shape color:treeColor[year];
	}
}
species outside_gates;

species sensor{
	string name;
	aspect base {
		draw square(20) color:#black;
	}
}

species pedestrian_network{
	string type; 
	rgb color;
	
	aspect base {
		draw shape color:people_color width:network_line_width;
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
		if the_target = location {
			the_target <- nil ;
		}
	}
	
	aspect base{
		draw circle(5) color: people_color border: #black;
	}
	
	aspect age {
		draw circle(5) color: age_color[age_group] border: #black;
	}
}

species tram_network {
	string type; 
	rgb color <- #blue  ;
	
	aspect base {
		draw shape color: tram_color width:network_line_width;
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
		do wander on: tramway_graph;
	}

	aspect base {
		draw box(20*scale, 3*scale,2*scale) rotate: heading color: rgb(15,135,82) border: #black ;
		draw box(10*scale, 3*scale,2.5*scale) rotate: heading color: #white border: #black ;
	}
}

species car_network {
	string type; 
	rgb color;
	
	aspect base {
		draw shape color:car_color width:network_line_width;
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
		draw rectangle(5*scale, 2*scale) rotate: heading color:car_color border: #black ;
	}
}

species bike skills:[advanced_driving] {

	//Reflex to move to the target building moving on the road network
	reflex move {
	do wander on:car_network_graph;
	}

	aspect base {
		draw triangle(5) rotate: heading +90 color:bike_color border: #black ;
	}
}


experiment cbd_toolkit_virtual type: gui autorun:true virtual:true{	
	float minimum_cycle_duration<-0.05;
	output {
		
		display Screen1 type: 3d axes: false background:background_color virtual:true{
			rotation angle:-21;
			
			//image '../includes/background.png' refresh: false;
			species building aspect: base visible:show_building;
			species pedestrian_network aspect: base visible:show_network;
			species tram_network aspect: base visible:show_network;
			species car_network aspect: base visible:show_network;
			species people aspect: base visible:show_people;
			species tram aspect: base visible:show_tram;
			species sensor aspect:base visible:show_sensor;
			species car aspect: base visible:show_car;
			species bike aspect: base visible:show_bike;
			species tree_canopy aspect: base visible:show_tree;
			mesh cell scale: 9 triangulation: true transparency: 0.4 smooth: 3 above: 0.8 color: pal visible:show_heatmap;
			
			event "a"  {show_tree<-!show_tree;}
			event "l"  {show_building<-!show_building;}
			event "t"  {show_tram<-!show_tram;}
			event "c"  {show_car<-!show_car;}
			event "b"  {show_bike<-!show_bike;}
			event "n"  {show_network<-!show_network;}
			event "p"  {show_people<-!show_people;}
			event "s"  {show_sensor<-!show_sensor;}
			event "h"  {show_heatmap<-!show_heatmap;}
			
			overlay position: { 50#px,50#px} size: { 1 #px, 1 #px } background: # black border: #black rounded: false
			{
				draw "CBD ToolKIT v1.0" at: {0,0} color: text_color font: font("Helvetica", 50, #bold);
				
				draw "Date: " + current_date at: {0,50#px} color: text_color font: font("Helvetica", 20, #bold);
				
                
                point UX_Position<-{world.shape.width*1.25,0#px};
                float x<-UX_Position.x;
                float y<-UX_Position.y;
        
                float gapBetweenWord<-25#px;
                float uxTextSize<-20.0;
                
                draw "UI/UX" at: { x,y} color: text_color font: font("Helvetica", uxTextSize*2, #bold);
                y<-y+gapBetweenWord;
                draw "(a)rbre (" + show_tree + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(l)anduse (" + show_building + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(t)ram (" + show_tram + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(c)ar (" + show_car + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                 draw "(b)ike (" + show_bike + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(n)etwork (" + show_network + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(p)eople (" + show_people + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(s)ensor (" + show_people + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                draw "(h)eatmap (" + show_heatmap + ")" at: { x,y} color: text_color font: font("Helvetica", uxTextSize, #bold);
                y<-y+gapBetweenWord;
                
                loop z over: legend_path.pairs
                {
                	draw circle(15#px) at: { 20#px, y} color: rgb(z.key, 0.8) ;
                	draw z.value at: { 60#px, y} color: # white font: text;
                    y <- y + 40#px;
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
			'Nice Ylabel' size:{0.5,0.5} position:{0,0.1}  label_background_color: background_color tick_line_color: rgb(255,255,255)
			legend_font: font('BrownPro' , 14, #plain) 
			
			{
				data "Car" value: (length(car)) color: rgb(71,42,22);
				data "Tram" value: (length(tram)) color: rgb(112,76,51);
				data "Bike" value: (-1) color: rgb(161,106,69);
				data "Walk" value: (length(people)) color: rgb(217,145,93);
				data "Bus" value: (-1) color: rgb(237,179,140);
				data "Other" value:(-1) color: rgb(244,169,160);
				
			}
			
			chart "Polution Level" type:histogram   size:{0.5,0.5} position:{0.5,0.1} background: background_color 
			x_serie_labels: ["categ1","categ2"]
			style:"3d"
			series_label_position: xaxis
			{
				data "Hazardous" value:cell 
				accumulate_values: true						
				color: rgb(112,76,51);
				
				data "Bad" value:cycle*cycle 
				accumulate_values: true						
			    color:rgb(217,145,93);
			    
				data "Average" value:cycle+1
				accumulate_values: true						
				marker_shape:marker_circle ;
				
				data "Good" value:cycle+1
				accumulate_values: true						
				marker_shape:marker_circle ;
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
		display table parent:Screen1 fullscreen:1{
			camera 'default' location: {1111.786,1109.9386,2688.8238} target: {1111.786,1109.8916,0.0};
		}
		display screen parent:Screen2 fullscreen:2{}
	}
}




/* Insert your model definition here */

