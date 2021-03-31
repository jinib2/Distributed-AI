/**
* Name: Model
* Based on the internal empty template. 
* Author: Admin
* Tags: 
*/


model Festival23

/* Insert your model definition here */

global
{
	/*init*/
	int no_guests <- 0;
	int no_guests_mem <- 20; 
	int no_bad_guests <- 1;
	list<string> products_type <- ["Book", "CD"];
	string AUCTION_KIND_INIT <- "Dutch";
	
	/*utils*/
	int distance_travelled <- 0;
	int guest_speed <- 2;
	int bad_speed <- 3;
	int guard_speed <- 5;
	int thirsty <- rnd(10, 10);
	int hungry <- rnd(10, 10);
	int tolerance <- 100;
	bool bad_guest <- false;
	bool security_alert <- false;
	bool auction_start_alert <- false;
	int idx_init <- 0;
	
	/* Locations */
	point bad_guest_loc;
	point infopoint_location <- {20,40} ;
	point water_location <- {50,40} ;
	point entrance_location <- {1,50} ;
	point food_truck_location <- {35,10} ;
	point vegan_restaurant_location <- {10, 15} ;
	point cafe_location <- {60,30} ;
	point guard_location <- {80,80};
	point auction_point_location_1 <- {30, 100};
	point auction_point_location_2 <- {70, 100};
	
	/* Output to display in chart */
	int displacement <- 0;
	int displacement_mem <- 0;
	
	init{
		create entrance number: 1
		{
			location <- {1,50};
		}
		
		create information_center number: 1
		{
			location <- {20,40};
		}
			
		create water_station number: 1
		{
			location <- {50,40};
		}
		
		create food_truck number: 1
		{
			location <- {35,10};
		}
		
		create vegan_restaurant number: 1
		{
			location <- {10, 15};
		}
		
		create cafe number: 1
		{
			location <- {60,30};
		}
		
		create auction_point number: 1{
			location <- auction_point_location_1;
			product <- "Book";
		}
		
		create auction_point number: 1{
			location <- auction_point_location_2;
			product <- "CD";
		}
		
		create security_guard number: 1
		{
			location <- {60,60};
			targetpoint <- {rnd(100), rnd(100)};
			security_alert <- false;
		}
		
		create festival_guest number: no_guests
		{
			location <- {rnd(100), rnd(100)};
			targetpoint <- {rnd(100), rnd(100)};
			knowledge <- false;
			wait <- 20;
		}
		
		create baddy_guest number: no_bad_guests
		{
			location <- {rnd(10), rnd(100)};
			targetpoint <- {rnd(100), rnd (100)};
			wait <- 15;
		}
		
		create guest_mem number: no_guests_mem
		{
			location <- {rnd(100), rnd(100)};
			targetpoint <- {rnd(100), rnd(100)};
			wait <- 20;
			knowledge_drink <- false;
			knowledge_food <- false;
		}
		
		
		create Initiator number: 2{
			auction_kind <- AUCTION_KIND_INIT;
		}
  
	}
}


species entrance{
	aspect default{
		draw box (2,15,2) at: location color: #orange lighted: bool(1);
	}
}

species information_center{
	aspect default{
		draw box(10,10,10) at: location color: #blue lighted: bool(1);
	}
}

species water_station{
	aspect default{
		draw box(5,5,2) at: location color: #cyan lighted: bool(1);
	}
}

species food_truck{
	aspect default{
		draw box(10,5,2) at: location color: #red lighted: bool(1);
	}
}

species vegan_restaurant{
	aspect default{
		draw box(10,5,2) at: location color: #green lighted: bool(1);
	}
}

species cafe{
	aspect default{
		draw box(10,7,5) at: location color: #yellow lighted: bool(1);
	}
}

species auction_point{
	
	string product;
	rgb color;
	
	reflex init{
		if (self.product = "Book"){
			self.color <- #orange;
		}
		else if(self.product = "CD"){
			self.color <- #cyan;
		}
	}
	
	aspect default{
		draw box(15,5,4) at: location color: self.color lighted: bool(1);
	}
}



species Partecipant skills: [fipa] {

	string auction_kind;
	int part_offer <- rnd (100,400);
	float english_auc_bid <- part_offer /rnd(2,6);
	float english_offer <- english_auc_bid;
	
	/* 
	reflex attend {
		ask(Initiator){
			if( (self.location = myself.location) and !(myself in self.partecipants_list) ){
				add myself to: self.partecipants_list;
			}
		}
	}
	*/
	
	reflex reply_message when: (!empty(cfps)) {
			message request_from_initiator <- (cfps at 0);
			int div <- rnd(2,5);
			int offer <- int (request_from_initiator.contents) / div;
			
			if self.auction_kind = "Dutch" {
				if offer < self.part_offer {
					do propose with: (message: request_from_initiator, contents: [self.part_offer]);
				}
				else {
					do propose with: (message: request_from_initiator, contents: [0]);
				}
			}
			
			if self.auction_kind = "English" {
				if self.english_offer < self.part_offer {
					do propose with: (message: request_from_initiator, contents: [self.english_offer]);
					self.english_offer <- self.english_offer + self.english_auc_bid;
				}
				
				else {
					do propose with: (message: request_from_initiator, contents: [0]);
				}
			}
			
			if self.auction_kind = "Sealed bid" {
				write "Here you have: " + self.part_offer;
				do propose with: (message: request_from_initiator, contents: [self.part_offer]);
			}
		}
}
 
species Initiator skills: [fipa]{
	
	bool initialized <- false;
	
	list<Partecipant> partecipants_list;
	Partecipant winner <- nil;
	string product;
	
	int start_auction <- 500;
	int waiting_for_partecipants <- 100;
	
	bool auction_begin <- false;
	bool auction_going <- false;
	
	string auction_kind;
	int part_offer <- rnd (100,400);
	float english_auc_bid <- part_offer /rnd(2,6);
	float english_offer <- english_auc_bid;
	int init_offer;
	int original_offer;
	int auction_time <- 0;
	bool next;
	bool speak <- true;
	bool auction_end_alert <- false;
	
	int price_sold;
	int dutch_auc_min <- 10;
	int sealed_bid_min <- rnd(90,120);
	
	reflex init when: !self.initialized{
		if (idx_init = 0){
			self.location <- auction_point_location_1;
			self.product <- products_type[idx_init];
			idx_init <- 1;
			self.initialized <- true;
		}
		else if (idx_init = 1){
			self.location <- auction_point_location_2;
			self.product <- products_type[idx_init];
			self.initialized <- true;
		}
		
		if (self.auction_kind = "Dutch") {
				//self.init_offer <- rnd(400,500);
				self.init_offer <- 100;
		}
			
		if (self.auction_kind = "English") {
				//self.init_offer <- rnd (50,100);
				self.init_offer <- 10;
		}
			
		if (self.auction_kind = "Sealed bid") {
				self.init_offer <- 0;
		}
			
		//Assigning the initial offer
		self.original_offer <- self.init_offer;
	}
	
	reflex countdown when: !auction_start_alert{
		self.start_auction <- self.start_auction - 1;
	} 
	
	reflex start_auction when: (self.start_auction <= 0) and !self.auction_begin and !self.auction_going{
		if self.speak {
			write "Auctions OPEN! Product:  " + self.product;
			self.speak <- false;
		}
		
		auction_start_alert <- true;
		
		self.waiting_for_partecipants <- self.waiting_for_partecipants - 1;
		
		if (self.waiting_for_partecipants <= 0){
			self.auction_begin <- true;
			self.auction_going <- true;
			auction_start_alert <- false;
			write "Auction STARTS: no more partecipants allowed!";
			self.next <- true;
			loop a over: self.partecipants_list {
				do start_conversation (to:: [a], protocol:: "fipa-request", performative:: "inform", contents :: ["Get ready for the auction!"]);
			}
		}
	}
	
	reflex send_request when: (partecipants_list != []) and auction_going and next{
		loop r over: self.partecipants_list {
			do start_conversation (to:: [r], protocol :: "fipa-request", performative ::"cfp", contents:: [self.init_offer]);
		}
		self.auction_time <- self.auction_time + 1;
		next <- false;	
	}
	
	/* 
	reflex dec_price when: (self.auction_going and self.auction_kind = "Dutch"){
		int decrement <- rnd (20,40);
		self.init_offer <- self.init_offer - decrement;
		//write "New offer: " +self.init_offer + " by " + self.type;
	}
	*/
	
	reflex read_reply_message when: (!(empty(proposes))) and self.auction_going{
		loop a over: proposes {
			do accept_proposal with: [message: a, contents: ["Nice proposal"]];
			int offer <- a.contents;
			
			if self.auction_kind = "Dutch" {
				if ((offer >= self.init_offer)) {
					self.price_sold <- offer;
					self.winner <- a.sender;
					write "We got a winner!!";
					self.auction_going <- false;
					break;
				}
				else {
					self.init_offer <- self.init_offer - 10;
				}
				
				if (self.price_sold < self.dutch_auc_min){
					self.auction_going <- false;
					write "No good bids... NO WINNERS! [Dutch]";
				}
			}
			
			if self.auction_kind = "English" {
				if ((offer > self.init_offer) and (offer > self.price_sold)) {
					self.price_sold <- offer;
					self.winner <- a.sender;
					write "We got a winner!!";
					self.auction_going <- false;
					break;
				}
				else if !( (offer > self.init_offer) and (offer > self.price_sold) ) {
					self.auction_going <- false; 
					
					if (self.original_offer > self.init_offer) {
						self.init_offer <- 0;
						self.price_sold <- 0;
						self.winner <- nil;
					}
				}
				else {
					self.init_offer <- self.price_sold;
				}
			}
				
			if self.auction_kind = "Sealed bid" {
				write "what an offer: " + offer;
					if offer > self.init_offer {
						self.price_sold <- offer;
						self.winner <- a.sender;
						write "We got a winner!!";
						self.auction_going <- false;
						break;
					}
			}
		}
			
			if !self.auction_going {
				self.auction_end_alert <- true;
				
				if self.winner != nil {
					do start_conversation (to :: [winner], protocol :: "fipa-request", performative :: "inform", contents :: ["You won!", self.price_sold]);
					
					if (self.auction_kind = "Dutch") {
						write "Dutch auction was profitable: " + 100.0*float(self.price_sold)/float(self.dutch_auc_min) + "%";
					}
					else if (self.auction_kind = "English") {
						write "English auction was profitable: " + 100.0*float(self.price_sold)/float (self.original_offer) + "%";
					}
					else if (self.auction_kind = "Sealed bid") {
						write "Sealed auction was profitable: " + (100.0*float(self.price_sold)/float(self.sealed_bid_min)) + "%";
					}
				}
				
				if self.winner = nil {
					write "No winners for this auctiopn ...  :(";
				}
				
				int n <- length(self.partecipants_list);
				create guest_mem number: n{
					location <- myself.location;
					knowledge_food <- true;
					knowledge_drink <- true;
					shopping_fever <- false;
				}
			}
				
			else {
					next <- true;
			}
		
		
	}

}



species festival_guest skills: [moving]{
	aspect default {
		draw box(1,1,1) color: color lighted: bool(1);
	}
	
	rgb color <- #black;
	
	point targetpoint;
	point water_location;
	
	int i <- rnd (1,3);
	int wait;
	
	bool moving <- true;
	bool isthirsty <- false;
	bool ishungry <- false;
	bool speak <- true;
	bool chosen <- false;
	bool knowledge <- false;
	
	int thirst_level <- rnd(100,200);
	int hunger_level <- rnd(100,600);
	
	int thirst <- thirst_level;
	int hunger <- hunger_level;
	
	int thirst_dec <- rnd(5,15);
	int hunger_dec <- rnd(5,10);
	
	//point target <- information_center;
	
	/*reflex movearound when: (isthirsty and ishungry)
	{
		do goto target: targetpoint speed: guest_speed;
		displacement <- displacement + 1;
		if (location distance_to(targetpoint) < guest_speed)
		{
			targetpoint <- {rnd(100), rnd(100)};
		}
	}*/
	
	reflex reduce_level when: (!self.isthirsty and !self.ishungry) 
	{
		self.thirst_level <- self.thirst_level - self.thirst_dec;
		self.hunger_level <- self.hunger_level - self.hunger_dec;
		}
	
	reflex hungry_thirsty_alert
	{
		if (thirst_level < thirsty){
			self.color <- #red;
			self.isthirsty <- true;
			if speak{
				write self.name + " : I'm thirsty";
				speak <- false;	
			}
			
		}
		
		else if (hunger_level < hungry) {
			self.color <- #blue;
			self.ishungry <- true;
			if speak {
				write self.name + " : I'm hungry";
				speak <- false;	
			}
		}
		else {
			do wander;
			}
	}
	
	reflex gotoinfo_center when: ((self.thirst_level < thirsty) or (self.hunger_level < hungry)) and !knowledge
	{		
		self.moving <- false;
		
		if self.isthirsty = true{
			targetpoint <- {50,40};
		}	
		else if self.ishungry{
			if i = 1{
				targetpoint <- {35,10};  //foodtruck
			}
			else if i = 2{
				targetpoint <- {10,15}; //vegan restaurant
			}
			else{
				targetpoint <- {60,30}; //cafe
			}
		}
		
		do goto target: {20,40} speed: guest_speed; //go to information center for enquiring about location
		
		if (location != {20,40}){
			displacement <- displacement + 1;
		}
		
		if (location = {20,40}){
			if wait <= 0 {
				if (self.isthirsty){
					write self.name + " : I know the location (DRINK)";
					knowledge <- true;
					wait <- 2;	
				}
				else if (self.ishungry){
					write self.name + " : I know the location (FOOD)";
					knowledge <- true;
					wait <- 2;	
				}
			}
			wait <- wait - 1;
		}
	}
	
	reflex frominfocenter when: knowledge{
		if (self.isthirsty){
			self.water_location <- {50,40};
			targetpoint <- self.water_location;
			
			do goto target: targetpoint speed: guest_speed;
			
			if (location != targetpoint){
				displacement <- displacement + 1;
				}
			
			if (location = targetpoint){
				if wait <= 0{
					write self.name + " : Feeling great now!";
					self.color <- #black;
					knowledge <- false;
					speak <- true;
					thirst_level <- rnd (100,200);
					self.isthirsty <- false;
					wait <- 3;
				}
				wait <- wait - 1;
			}
		} 
		else if (self.ishungry){
			if !chosen{
				i <- rnd(1,4);
				if i = 1{
					targetpoint <- {35,10};  //foodtruck
					chosen <- true;
				}
				else if i = 2{
					targetpoint <- {10,15}; //vegan restaurant
					chosen <- true;
				}
				else{
					targetpoint <- {60,30}; //cafe
					chosen <- true;
				}	
			}
			else if chosen{
				do goto target: targetpoint speed: guest_speed;
				
				if(location != targetpoint){
					displacement <- displacement +1;
				}
				
				if (location = targetpoint){
					if (wait <= 0) {
						write self.name + " : Feeling great now!";
						self.color <- #black;
						speak <- true;
						knowledge <- false;
						hunger_level <- rnd (100,200);
						self.ishungry <- false;
						self.chosen <- false;
						wait <- 2;
					}
					wait <- wait - 1;
				}	
			}
		} 
		else{
			//do goto target: {rnd(100), rnd(100)} speed: guest_speed;
			do wander;
			displacement <- displacement + 1;
		}
  	}
}

species guest_mem skills: [moving]{
	aspect default {
		draw sphere(1) color: color lighted: bool(1);
	}
	 
	rgb color <- #grey ;
	
	point targetpoint;
	point water_location;
	point bad_guest_loc;
	
	baddy_guest baddy;
	
	int i <- rnd (1,3);
	int wait;
	
	bool moving <- true;
	bool isthirsty <- false;
	bool ishungry <- false;
	bool knowledge_drink <- false;
	bool knowledge_food <- false;
	bool speak <- true;
	bool chosen <- false;
	bool auction_chosen <- false;
	bool product_chosen <- false;
	bool report <- false;
	
	bool shopping_fever <- false;
	int shopping_fever_level <- 0;
	string product_interested;
	
	int thirst_level <- rnd(100,200);
	int hunger_level <- rnd(300,400);
	
	int thirst <- thirst_level;
	int hunger <- hunger_level;
	
	int thirst_dec <- rnd(1,10);
	int hunger_dec <- rnd(1,5);
	
	//point target <- information_center;
	
	/*reflex movearound when: (isthirsty and ishungry)
	{
		do goto target: targetpoint speed: guest_speed;
		displacement <- displacement + 1;
		if (location distance_to(targetpoint) < guest_speed)
		{
			targetpoint <- {rnd(100), rnd(100)};
		}
	}*/
	
	reflex reduce_level when: (!self.isthirsty and !self.ishungry) and !report and !auction_start_alert
	{
		self.thirst_level <- self.thirst_level - self.thirst_dec;
		self.hunger_level <- self.hunger_level - self.hunger_dec;
		self.shopping_fever_level <- self.shopping_fever_level + 1;
	}
	
	reflex hungry_thirsty_shop_alert when: !auction_start_alert
	{
		if (thirst_level < thirsty){
			self.color <- #red;
			self.isthirsty <- true;
			if speak{
				write self.name + " : I'm thirsty";
				speak <- false;	
			}
		}
		
		else if (hunger_level < hungry) {
			self.color <- #blue;
			self.ishungry <- true;
			if speak {
				write self.name + " : I'm hungry";
				speak <- false;	
			}
		}
		else if (self.shopping_fever_level > 100 and !self.shopping_fever) {
			self.shopping_fever <- true;
			if self.speak {
				write self.name + " : i hope an auction starts soon... for: " + self.product_interested;
				self.speak <- false;	
			}
		}
		else {
			do wander;
		}
	}
	
	reflex gotoinfo_center when: ((self.thirst_level < thirsty and !self.knowledge_drink) 
							   or (self.hunger_level < hungry and !self.knowledge_food)) and !self.report and !auction_start_alert
	{		
		self.moving <- false;
		
		if self.isthirsty = true{
			targetpoint <- {50,40};
		}	
		else if self.ishungry{
			if i = 1{
				targetpoint <- {35,10};  //foodtruck
			}
			else if i = 2{
				targetpoint <- {10,15}; //vegan restaurant
			}
			else{
				targetpoint <- {60,30}; //cafe
			}
		}
		
		do goto target: {20,40} speed: guest_speed; //go to information center for enquiring about location
		
		if (location != {20,40}){
			displacement_mem <- displacement_mem + 1;
		}
		
		if (location = {20,40}){
			if wait <= 0 {
				if (self.isthirsty and !self.knowledge_drink){
					write self.name + " : I know the location (DRINK)";
					knowledge_drink <- true;
					wait <- 2;	
				}
				else if (self.ishungry and !self.knowledge_food){
					write self.name + " : I know the location (FOOD)";
					knowledge_food <- true;
					wait <- 2;	
				}
			}
			wait <- wait - 1;
		}
	}
	
	reflex frominfocenter when: (knowledge_drink or knowledge_food) and !report and !auction_start_alert{
		
		if (self.isthirsty and self.knowledge_drink){
			self.water_location <- {50,40};
			targetpoint <- self.water_location;	
			do goto target: targetpoint speed: guest_speed;
			
			if (location != targetpoint){
				displacement_mem <- displacement_mem + 1;
				}
			
			if (location = targetpoint){
				if wait <= 0{
					write self.name + " : Feeling great now!";
					self.color <- #grey;
					speak <- true;
					thirst_level <- rnd (100,200);
					self.isthirsty <- false;
					wait <- 3;
				}
				wait <- wait - 1;
			}
		} 
		else if (self.ishungry and self.knowledge_food){
			if !chosen{
				i <- rnd(1,4);
				if i = 1{
					targetpoint <- {35,10};  //foodtruck
					chosen <- true;
				}
				else if i = 2{
					targetpoint <- {10,15}; //vegan restaurant
					chosen <- true;
				}
				else{
					targetpoint <- {60,30}; //cafe
					chosen <- true;
				}	
			}
			else if chosen{
				do goto target: targetpoint speed: guest_speed;
				
				if(location != targetpoint){
					displacement_mem <- displacement_mem +1;
				}
				
				if (location = targetpoint){
					if (wait <= 0) {
						write self.name + " : Feeling great now!";
						self.color <- #grey;
						speak <- true;
						hunger_level <- rnd (100,200);
						self.ishungry <- false;
						self.chosen <- false;
						wait <- 2;
					}
					wait <- wait - 1;
				}	
			}
		} 
		else{
			//do goto target: {rnd(100), rnd(100)} speed: guest_speed;
			do wander;
			displacement_mem <- displacement_mem + 1;
		}
  	}
  	
  	reflex bad_alert when: bad_guest{
  		ask(baddy_guest){
  			if (myself.location distance_to(self.location) < 2){
  				write "I have found a Bad guy.";
  				myself.baddy <- self;
  				myself.report <- true;
  			}
  		}
  	}
  	
  	reflex report when: self.report and bad_guest{
  		point guard_position;
  		self.color <- #green;
  		
  		ask(security_guard){
  			guard_position <- self.location;
  		}
  		
  		do goto target: guard_position speed: guest_speed;
  		
  		if(self.location = guard_position){
  			ask(security_guard){
  				if( !(myself.baddy in self.targets) ) {
  					add myself.baddy to: self.targets;
  					write "Guard Informed";
  					security_alert <- true;
  					myself.report <- false;
  				} 
  				else {
  					write "Already informed.";
  					myself.report <- false;
  				}
  			}
  			report <- false;
  		}
  	}
  	
  	reflex choose_product when: !self.product_chosen and !auction_start_alert{
  		int idx <- rnd(0, 1);	
  		if (products_type[idx] = "Book"){
  			self.product_interested <- "Book";
  			self.product_chosen <- true;
  		}
  		else if (products_type[idx] = "CD"){
  			self.product_interested <- "CD";
  			self.product_chosen <- true;
  		}
  	}
  	
  	reflex shopping_time when: (self.shopping_fever and auction_start_alert and self.product_chosen){
  		if (!self.auction_chosen){
		  	if (self.product_interested = "Book"){
		  		targetpoint <- auction_point_location_1;
		  		self.auction_chosen <- true;
		  		self.color <- #orange;
		  	} else if(self.product_interested = "CD"){
		  		targetpoint <- auction_point_location_2;
		  		self.auction_chosen <- true;
		  		self.color <- #cyan;
		  	}
		} 
		else if (self.auction_chosen){	
	  		do goto target: targetpoint speed: guest_speed;
	  		if(self.location = targetpoint){
	  			write "I'm here!!";
	  			/* create Partecipant of auctions */
	  			create Partecipant number: 1 {
	  				location <- myself.location;
	  				auction_kind <- AUCTION_KIND_INIT;
	  			
	  				ask(Initiator){
						if( (self.location = myself.location) and !(myself in self.partecipants_list) ){
							add myself to: self.partecipants_list;
						}
					}	
	  			}
	  			
	  			
	  			
	  			do die;	
	  		}
  		}
  	}
}

species baddy_guest skills: [moving]{
	aspect default {
		draw sphere(1) color: color lighted: bool(1);
	}
	
	rgb color <- #purple;
	point targetpoint;
	int wait;
	
	//bool isthirsty <- false;
	//bool ishungry <- false;
	//bool knowledge;
	bool active <- false;
	bool speak <- true;
	bool chosen <- false;
	
	int thirst_level <- rnd(100,200);
	int hunger_level <- rnd(100,200);
	
	int bad_level <- 0;
	int mess <- rnd(1,5);
	
	int thirst <- thirst_level;
	int hunger <- hunger_level;
	
	int thirst_dec <- rnd(5,10);
	int hunger_dec <- rnd(10,10);
	
	
	/*reflex move when: isthirsty= false and ishungry = false{
		//self.thirst_level <- self.thirst_level - self.thirst_dec;
		//self.hunger_level <- self.hunger_level - self.hunger_dec;
		self.bad_level <- self.bad_level + 2.0;
		do wander speed: 2.0;
	}*/
	
	reflex move when: !active{
		//self.thirst_level <- self.thirst_level - self.thirst_dec;
		//self.hunger_level <- self.hunger_level - self.hunger_dec;
		self.bad_level <- self.bad_level + self.mess;
		do wander speed: guest_speed;
	}

	reflex bad_begin when: (self.bad_level > tolerance) and !active and !bad_guest{
		bad_guest <- true;
		active <- true;
		self.color <- #yellow;
		write self.name + " : I am bad !!!";
		//bad_guest_loc <- self.location;
	}
	
	reflex messing when: active{
		if !chosen{
			int i <- rnd(1,10);
			switch i {	
				match 1 { targetpoint <- {35,10}; chosen <- true;}  //foodtruck 			
				match 2 { targetpoint <- {10,15}; chosen <- true;} //vegan restaurant 
				match 3 { targetpoint <- {60,30}; chosen <- true;}  //cafe 			
				match 4 { targetpoint <- {50,40}; chosen <- true;} //water 
				default { do wander speed: bad_speed;}
			}	
		}
		else if chosen {
			do goto target:targetpoint speed: bad_speed;
			if (self.location = targetpoint){
				chosen <- false;
			}
		}
	}
			
}

species security_guard skills: [moving] {
	rgb color <- #black;
	point targetpoint;
	
	aspect default{
		draw cylinder(2,2) at: location color: color;
	}
	
	list<baddy_guest> targets <- [];

	reflex take_out when: security_alert{
		
		if (self.targets != []){	
			point target <- self.targets[0].location;
			do goto target: target speed: 5.0;
			if (self.location distance_to(target) < 2){
				ask (baddy_guest){
					if (length(myself.targets) > 0 and self = myself.targets[0]){
						write "Removed";
						write "Total Distance: " + distance_travelled;
						remove first(myself.targets) from: myself.targets;
						do die;
					}
				}
			}
		}
		else {
			ask(guest_mem){
				self.report <- false;
			}
			bad_guest <- false;
			security_alert <- false;
			write "Baddy guest already addressed.";
		}
	}
	
	reflex at_base when: security_alert = false{
		do goto target: {80,80} speed: 5.0;
	}
}



experiment main type: gui{
	output {
		display map type: opengl
		{
			species entrance;
			species information_center;
			species water_station;
			species food_truck;
			species vegan_restaurant;
			species cafe;
			species auction_point;
			species Initiator;
			species Partecipant;
			species festival_guest;
			species security_guard;
			species baddy_guest;
			species guest_mem;
		}
		
		display chart
		{
			chart "Agent displacements with and without memory"
			{
				data "Distance for agents with memory" value: displacement_mem color: #pink;
				data "Distance for agents without memory" value: displacement color: #red;
			}
		}
	}
}