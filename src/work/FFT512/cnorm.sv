// SystemVerilog generated from Verilog
 
`timescale 1 ns / 1 ps		 
 
module CNORM ( CLK ,ED ,START ,DR ,DI ,SHIFT ,OVF ,RDY ,DOR ,DOI );
	parameter nb =16;
	
	output OVF ;
	logic OVF ;
	output RDY ;
	logic RDY ;
	output [nb+1:0] DOR ;
	logic [nb+1:0] DOR ;
	output [nb+1:0] DOI ;
	logic [nb+1:0] DOI ;
	
	input CLK ;
	logic CLK ;
	input ED ;
	logic ED ;
	input START ;
	logic START ;
	input [nb+3:0] DR ;
	logic [nb+3:0] DR ;
	input [nb+3:0] DI ;
	logic [nb+3:0] DI ;
	input [1:0] SHIFT ;			  //shift left code to 0,1,2,3 bits
	logic [1:0] SHIFT ;
	
logic signed [nb+3:0]	 diri,diii;
assign diri = DR << SHIFT;
assign diii = DI << SHIFT;	 

logic [nb+3:0]	dir,dii;

`ifdef FFT256round 			//rounding
    always_ff @ (posedge CLK)    begin
			if (ED)	  begin
					dir<=diri;
     				dii<=diii;
		end 
	end  
	
`else								 //truncation	 
    always_ff @ (posedge CLK)    begin
		if (ED)	  begin	
			if (diri[nb+3] && ~diri[0])	// <0 with LSB=00 
				dir<=diri; 
			else   dir<=diri+2; 
			if (diii[nb+3] && ~diii[0])
				dii<=diii; 
			else   dii<=diii+2; 
		end 
	end  
	
	`endif
	
 always_ff @ (posedge CLK) 	begin
		  	if (ED)	  begin
				RDY<=START;
				if (START) 
					OVF<=0;
				else   
					case (SHIFT) 
					2'b01 : OVF<= (DR[nb+3] != DR[nb+2]) || (DI[nb+3] != DI[nb+2]);
					2'b10 : OVF<= (DR[nb+3] != DR[nb+2]) || (DI[nb+3] != DI[nb+2]) ||
						(DR[nb+3] != DR[nb+1]) || (DI[nb+3] != DI[nb+1]);
					2'b11 : OVF<= (DR[nb+3] != DR[nb+2]) || (DI[nb+3] != DI[nb+2])||
						(DR[nb+3] != DR[nb]) || (DI[nb+3] != DI[nb]) ||
						(DR[nb+3] != DR[nb+1]) || (DI[nb+3] != DI[nb+1]);
					endcase						
				end
			end 
			
	assign DOR= dir[nb+3:2];
	assign DOI= dii[nb+3:2];
	
endmodule
