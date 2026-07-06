// SystemVerilog generated from Verilog
 

module MPUC1307 ( CLK,EI ,ED, MPYJ,DR,DI ,DOR ,DOI  );
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
	
	output [nb:0] DOR ;
	logic [nb:0] DOR ;	
	output [nb:0] DOI ;
	logic [nb:0] DOI ;	 
	
	logic signed [nb+2 :0] dx5;	 
	logic signed [nb-1 :0] dx7;	 
	logic signed [nb-1 :0] dii;	 
	logic signed	[nb : 0] dt;		   
	logic signed [nb+3 : 0]  dx5p; 
	logic signed  [nb+3 : 0] dot;	
	logic edd,edd2, edd3;        		//delayed data enable impulse        
	logic mpyjd,mpyjd2,mpyjd3;
	logic [nb:0] doo ;	
	logic [nb:0] droo ;	
	
	always_ff @ (posedge CLK)
		begin
			if (EI) begin	  
					edd<=ED;
					edd2<=edd;	
					edd3<=edd2;	
					mpyjd<=MPYJ;
					mpyjd2<=mpyjd;
					mpyjd3<=mpyjd2;					 //1_0100_1110_0111_1011
					if (ED)	 begin				   		//	 1_0101_00T0_1000_0T0T	 	 
							dx5<=DR+(DR <<2);	 //multiply by 5 
							dx7<=DR-(DR>>>3);	 //multiply by 7, shifted right to 2 
							dt<=DR;	  
							dii<=DI;
						end
					else	 begin
							dx5<=dii+(dii <<2);	 //multiply by 5
							dx7<=dii-(dii>>>3);	 //multiply by 7, shifted right to 3 
							dt<=dii;
						end
					doo<=dot >>>3;	
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
	
	assign	dx5p=(dx5<<1)+(dx7>>>1);		// multiply by 1_0101_00T	 	
	
	`ifdef FFT256bitwidth_coef_high 
	assign   dot=	(dx5p+(dt>>>6) -(dx5>>>13));// multiply by 1_0101_00T0_1000_0T0T	 	      
	`else	                               
	assign    dot= 	dx5p+(dt>>>6);  	   
	`endif	 	
	
	
	
endmodule
