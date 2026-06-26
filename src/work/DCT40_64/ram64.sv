// DESCRIPTION	:	1-port synchronous RAM
`timescale 1 ns / 1 ps
  
module RAM64( 
              CLK, 
				  ED,
				  WE,
				  ADDR,
				  DI,
				  DO
				  );
				  
	parameter nb=16; 
	
	output [nb-1:0] DO ;
	input CLK ;
	input ED;
	input WE ;
	input [5:0] ADDR ;
	input [nb-1:0] DI ;
	
	wire CLK ;
	wire WE ;
	wire [5:0] ADDR ;
	wire [nb-1:0] DI ;
	reg [nb-1:0] mem [63:0];
	reg [5:0] addrrd;		  
	reg [nb-1:0] DO ;
	
	
	always @(posedge CLK) 
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
