// SystemVerilog generated from Verilog
 

module MPUC707 ( CLK,EI ,ED, MPYJ,DR,DI ,DOR ,DOI);
	parameter nb =16; 
	
	input CLK ;
	logic CLK ;
	input EI ;					//slowdown
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
	
	logic signed [nb+1 :0] dx5;	 
	logic signed	[nb : 0] dt;		   
	logic signed	[nb-1 : 0] dii;		   
	logic signed [nb+2 : 0]  dx5p; 
	logic signed  [nb+3 : 0] dot;	
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
					if (ED)	 begin
							dx5<=DR+(DR <<2);	 //multiply by 5 
							dt<=DR;	  
							dii<=DI;
						end
					else	 begin
							dx5<=dii+(dii <<2);	 //multiply by 5
							dt<=dii;
						end
					doo<=(dot >>>4) ;	
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
		
	assign	dx5p=(dx5<<1)+(dx5>>>2);		// multiply by 101101		 	
	
	`ifdef FFT256bitwidth_coef_high
	assign   dot=	dx5p+(dt>>>4)+(dx5>>>13);	   // multiply by 10110101000000101	      
	`else	                               
	assign    dot=		dx5p+(dt>>>4)	;  // multiply by 10110101	   
	`endif	 	
	
	
	
endmodule
