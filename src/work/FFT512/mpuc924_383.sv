// SystemVerilog generated from Verilog
 
module MPUC924_383(CLK,EI ,ED, MPYJ,C383,DR,DI ,DOR ,DOI);
	parameter nb =16; 
	
	input CLK ;
	logic CLK ;
	input EI ;
	logic EI ;
	input ED; 					//data strobe
	input MPYJ ;				//the result is multiplied by -j
	logic MPYJ ;
	input C383 ;				//the coefficient is 0.383
	logic C383 ;
	input [nb-1:0] DR ;
	logic signed [nb-1:0] DR ;
	input [nb-1:0] DI ;
	logic signed [nb-1:0] DI ;	   
	
	output [nb-1:0] DOR ;
	logic [nb-1:0] DOR ;	
	output [nb-1:0] DOI ;
	logic [nb-1:0] DOI ;	 
	
	logic signed [nb+1 :0] dx7;	 
	logic signed [nb :0] dx3;	 
	logic signed [nb-1 :0] dii;	 
	logic signed	[nb-1 : 0] dt;		   
	logic signed [nb+1 : 0]  dx5p; 
	logic signed  [nb+1 : 0] dot;	
	logic edd,edd2, edd3;        		//delayed data enable impulse        
	logic mpyjd,mpyjd2,mpyjd3,c3d,c3d2,c3d3;
	logic [nb-1:0] doo ;	
	logic [nb-1:0] droo ;	
	
	always_ff @ (posedge CLK)
		begin
			if (EI) begin	  
					edd<=ED;
					edd2<=edd;	
					edd3<=edd2;	
					mpyjd<=MPYJ;
					mpyjd2<=mpyjd;
					mpyjd3<=mpyjd2;		
					c3d<=C383;
					c3d2<=c3d;
					c3d3<=c3d2;
					if (ED)	 begin				   		//	 1_00T0_1100_1000_0011	
							dx7<=(DR<<2) - (DR >>>1);	 //multiply by 7 
							dx3<=DR+(DR >>>1);	 //multiply by 3, 
							dt<=DR;	  
							dii<=DI;
						end
					else	 begin
							dx7<=(dii<<2) - (dii >>>1);	 //multiply by 7
							dx3<=dii +(dii >>>1);	 //multiply by  3 
							dt<=dii;
					end	  
					if (c3d || c3d2)  	doo<=dot >>>2;	
					else			doo<=dot >>>2;		 
						
					droo<=doo;	
					if (edd3) 	 
						if (mpyjd3) begin
								DOR<=doo;
							DOI<= - droo; end
						else begin
								DOR<=droo;
							DOI<=  doo; end					
				end 
		end		
		
	assign dx5p=	(c3d || c3d2)? ((dt>>>5)+dx3)  : ( dx7+(dx3>>>3));		// multiply by  0_0110_001	
                     	//or  multiply by  1_00T0_11
	
	`ifdef FFT256bitwidth_coef_high 
	assign   dot=	(c3d || c3d2)? dx5p-(dt>>>11) :(dx5p+((dt>>>7) +(dx3>>>13)));// by 	0_0110_0010_0000_T 
	            //or  multiply by 	1_00T0_1100_1000_0011
	`else	                               
	assign    dot= (c3d || c3d2)?  	dx5p :  (dx5p+(dt>>>7));  
	                    //or multiply by 	1_00T0_1100_1	   
	`endif	 	
	
	
	
endmodule
