 
`timescale 1 ns / 1 ps		 
 
module NORM #(
    parameter nb=16
) (
    input CLK,
    input ED,
    input START,
    input signed [nb+3:0] DIN,
    input [1:0] SHIFT,            //shift left code to 0,1,2,3 bits
    output reg OVF,
    output reg RDY,
    output signed [nb+1:0] DOUT
);
	
wire signed [nb+3:0]	 diri;
assign diri = DIN << SHIFT;

reg signed [nb+3:0]	dir;

`ifdef FFT256round 			//rounding
    always @( posedge CLK )    begin
			if (ED)	  begin
					dir<=diri;
		end 
	end  
	
`else								 //truncation	 
    always @( posedge CLK )    begin
		if (ED)	  begin	
			if (diri[nb+3] && ~diri[0])	// <0 with LSB=00 
				dir<=diri; 
			else   dir<=diri+2; 
		end 
	end  
	
	`endif
	
 always @( posedge CLK ) 	begin
		  	if (ED)	  begin
				RDY<=START;
				if (START) 
					OVF<=0;
				else   
					case (SHIFT) 
					2'b01 : OVF<= (DIN[nb+3] != DIN[nb+2]);
					2'b10 : OVF<= (DIN[nb+3] != DIN[nb+2]) ||
						(DIN[nb+3] != DIN[nb+1]);
					2'b11 : OVF<= (DIN[nb+3] != DIN[nb+2]) ||
						(DIN[nb+3] != DIN[nb]) ||
						(DIN[nb+3] != DIN[nb+1]);
					endcase						
				end
			end 
			
	assign DOUT= dir[nb+3:2];
	
endmodule
