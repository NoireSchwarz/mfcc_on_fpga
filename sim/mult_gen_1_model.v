`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module mult_gen_1 (
	CLK,
	A,
	B,
	P
);
	input wire CLK;
	input wire [31:0] A;
	input wire [15:0] B;
	output reg [31:0] P;
	wire [47:0] product;
	assign product = A * B;
	always @(posedge CLK) P <= product >> 15;
endmodule
