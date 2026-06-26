// DESCRIPTION	:	2-port RAM

`timescale 1 ns / 1 ps
  

module RAM2x64 #(
    parameter nb=16
) (
    input CLK,
    input ED,
    input WE,      //write enable
    input ODD,     // RAM part switshing
    input [5:0] ADDRW,
    input [5:0] ADDRR,
    input [nb-1:0] DIN,
    output [nb-1:0] DOUT
);
	
	reg	oddd,odd2;
	always @( posedge CLK) begin //switch which reswiches the RAM parts
			if (ED)	begin
					oddd<=ODD;
					odd2<=oddd;
				end
		end 
		
	wire [6:0] addrr2 = {ODD,ADDRR};
	wire [6:0] addrw2 = {~ODD,ADDRW};
	wire [nb-1:0] di= DIN ;	

	reg [nb-1:0] dout_reg;	
	
	reg [nb-1:0] ram [127:0];
	reg [6:0] read_addra;
	integer init_idx;

	initial begin
			oddd = 1'b0;
			odd2 = 1'b0;
			dout_reg = {nb{1'b0}};
			read_addra = 7'd0;
			for (init_idx = 0; init_idx < 128; init_idx = init_idx + 1)
					ram[init_idx] = {nb{1'b0}};
	end

	always @(posedge CLK) begin
			if (ED)
				begin
					if (WE)
						ram[addrw2] <= di;
					read_addra <= addrr2;	
				   dout_reg <= ram[read_addra];			
				end
		end
	
	assign	DOUT=dout_reg;		 // Read data 
	
	
	
endmodule
