`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module butterfly (
	sum,
	diff,
	x,
	y,
	en
);
	parameter IN_WIDTH = 16;
	parameter OUT_WIDTH = IN_WIDTH + 1;
	output reg signed [OUT_WIDTH - 1:0] sum;
	output reg signed [OUT_WIDTH - 1:0] diff;
	input signed [IN_WIDTH - 1:0] x;
	input signed [IN_WIDTH - 1:0] y;
	input en;
	always @(*)
		if (en) begin
			sum = {x[IN_WIDTH - 1], x} + {y[IN_WIDTH - 1], y};
			diff = {x[IN_WIDTH - 1], x} - {y[IN_WIDTH - 1], y};
		end
		else begin
			sum = 0;
			diff = 0;
		end
endmodule
