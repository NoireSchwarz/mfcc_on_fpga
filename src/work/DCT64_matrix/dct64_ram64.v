`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module dct64_ram64 (
	CLK,
	WE,
	ADDRW,
	DI,
	RE,
	ADDRR,
	DO
);
	parameter DATA_W = 16;
	input wire CLK;
	input wire WE;
	input wire [5:0] ADDRW;
	input wire [DATA_W - 1:0] DI;
	input wire RE;
	input wire [5:0] ADDRR;
	output reg signed [DATA_W - 1:0] DO;
	reg [DATA_W - 1:0] mem [0:63];
	always @(posedge CLK) begin
		if (WE)
			mem[ADDRW] <= DI;
		if (RE)
			DO <= mem[ADDRR];
	end
endmodule
