`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module signed_mult (
	a,
	b,
	y
);
	parameter A_WIDTH = 16;
	parameter B_WIDTH = 16;
	parameter FRAC_WIDTH = 15;
	parameter OUT_WIDTH = A_WIDTH + 1;
	input signed [A_WIDTH - 1:0] a;
	input signed [B_WIDTH - 1:0] b;
	output wire signed [OUT_WIDTH - 1:0] y;
	wire signed [(A_WIDTH + B_WIDTH) - 1:0] temp;
	assign temp = a * b;
	assign y = temp >>> FRAC_WIDTH;
endmodule
