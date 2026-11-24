`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module RAM256 (
	CLK,
	ED,
	WE,
	ADDR,
	DI,
	DO
);
	parameter nb = 16;
	output reg [nb - 1:0] DO;
	input wire CLK;
	input ED;
	input wire WE;
	input wire [7:0] ADDR;
	input wire [nb - 1:0] DI;
	reg [nb - 1:0] mem [255:0];
	reg [7:0] addrrd;
	always @(posedge CLK)
		if (ED) begin
			if (WE)
				mem[ADDR] <= DI;
			addrrd <= ADDR;
			DO <= mem[addrrd];
		end
endmodule
