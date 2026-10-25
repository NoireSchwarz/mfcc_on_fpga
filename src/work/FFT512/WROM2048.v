`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module WROM2048 (
	WI,
	WR,
	ADDR
);
	parameter TW = 16;
	parameter COS_FILE = "WROM2048_cos.mem";
	parameter SIN_FILE = "WROM2048_sin.mem";
	input wire [10:0] ADDR;
	output wire signed [TW - 1:0] WI;
	output wire signed [TW - 1:0] WR;
	reg [15:0] cosw [0:2047];
	reg [15:0] sinw [0:2047];
	initial begin
		$readmemh(COS_FILE, cosw);
		$readmemh(SIN_FILE, sinw);
	end
	wire [15:0] wri;
	wire [15:0] wii;
	assign wri = cosw[ADDR];
	assign wii = sinw[ADDR];
	wire [TW:0] wrt;
	wire [TW:0] wit;
	assign wrt = wri[15:16 - TW];
	assign wit = wii[15:16 - TW];
	assign WR = wrt[TW - 1:0];
	assign WI = wit[TW - 1:0];
endmodule
