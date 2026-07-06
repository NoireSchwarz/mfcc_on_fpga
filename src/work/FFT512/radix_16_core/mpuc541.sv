
// DESCRIPTION	:	 Complex Multiplier by 0.5411

module MPUC541 ( CLK,EI ,ED, MPYJ,DR,DI ,DOR ,DOI);
	parameter nb =16;
	
	input CLK ;
	logic CLK ;
	input EI ;
	logic EI ;
	input ED; 					//data strobe
	input MPYJ ;				//the result is multiplied by -j
	logic MPYJ ;
	input [nb-1:0] DR ;
	logic signed [nb-1:0] DR ;
	input [nb-1:0] DI ;
	logic signed [nb-1:0] DI ;	   
	
	output [nb-1:0] DOR ;
	logic [nb-1:0] DOR ;	
	output [nb-1:0] DOI ;
	logic [nb-1:0] DOI ;	 
	
	logic signed [nb :0] dx5;	 
	logic signed [nb :0] dx3;	 
	logic signed [nb-1 :0] dii;	 
	logic signed	[nb-1 : 0] dt;		   
	logic signed [nb+1 : 0]  dx5p; 
	logic signed  [nb+1 : 0] dot;	
	logic edd,edd2, edd3;        		//delayed data enable impulse        
	logic mpyjd,mpyjd2,mpyjd3;
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
					if (ED)	 begin				   		//	 0_1000_1010_1000_11 	
							dx5<=DR+(DR >>>2);	 //multiply by 5 
							dx3<=DR+(DR >>>1);	 //multiply by 3, 
							dt<=DR;	  
							dii<=DI;
						end
					else	 begin
							dx5<=dii+(dii >>>2);	 //multiply by 5
							dx3<=dii +(dii >>>1);	 //multiply by  3 
							dt<=dii;
						end
					doo<=dot >>>2;	
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
	
	assign	dx5p=(dt<<1)+(dx5>>>3);		// multiply by  0_1000_101 
	
	`ifdef FFT256bitwidth_coef_high 
	assign   dot=	(dx5p+(dt>>>7) +(dx3>>>11));// multiply by //	 0_1000_1010_1000_11 
	`else	                               
	assign    dot= 	dx5p+(dt>>>7);  	   
	`endif	 	
	
	
	
endmodule
