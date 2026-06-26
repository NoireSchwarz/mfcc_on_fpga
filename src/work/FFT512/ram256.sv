// DESCRIPTION	:	1-port synchronous RAM
`timescale 1 ns / 1 ps
  
module RAM256( 
              CLK, 
				  ED,
				  WE,
				  ADDR,
				  DI,
				  DO
				  );
				  
	parameter nb =16; 
	
	output [nb-1:0] DO ;
	input CLK ;
	input ED;
	input WE ;
	input [7:0] ADDR ;
	input [nb-1:0] DI ;
	
	logic CLK ;
	logic WE ;
	logic [7:0] ADDR ;
	logic [nb-1:0] DI ;
	logic [nb-1:0] mem [255:0];
	logic [7:0] addrrd;		  
	logic [nb-1:0] DO ;
	
	
	always_ff @ (posedge CLK) 
	begin
		if(ED) 
		begin
			if(WE)		
			mem[ADDR] <= DI;
			
			addrrd <= ADDR;	         //storing the address
			DO <= mem[addrrd];	   // registering the read datum
		end	  
		
	end
	
	
endmodule
