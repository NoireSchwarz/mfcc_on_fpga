`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module MPUC541 (
	CLK,
	EI,
	ED,
	MPYJ,
	DR,
	DI,
	DOR,
	DOI
);
	parameter nb = 16;
	input wire CLK;
	input wire EI;
	input ED;
	input wire MPYJ;
	input wire signed [nb - 1:0] DR;
	input wire signed [nb - 1:0] DI;
	output reg [nb - 1:0] DOR;
	output reg [nb - 1:0] DOI;
	reg signed [nb:0] dx5;
	reg signed [nb:0] dx3;
	reg signed [nb - 1:0] dii;
	reg signed [nb - 1:0] dt;
	wire signed [nb + 1:0] dx5p;
	wire signed [nb + 1:0] dot;
	reg edd;
	reg edd2;
	reg edd3;
	reg mpyjd;
	reg mpyjd2;
	reg mpyjd3;
	reg [nb - 1:0] doo;
	reg [nb - 1:0] droo;
	always @(posedge CLK)
		if (EI) begin
			edd <= ED;
			edd2 <= edd;
			edd3 <= edd2;
			mpyjd <= MPYJ;
			mpyjd2 <= mpyjd;
			mpyjd3 <= mpyjd2;
			if (ED) begin
				dx5 <= DR + (DR >>> 2);
				dx3 <= DR + (DR >>> 1);
				dt <= DR;
				dii <= DI;
			end
			else begin
				dx5 <= dii + (dii >>> 2);
				dx3 <= dii + (dii >>> 1);
				dt <= dii;
			end
			doo <= dot >>> 2;
			droo <= doo;
			if (edd3) begin
				if (mpyjd3) begin
					DOR <= doo;
					DOI <= -droo;
				end
				else begin
					DOR <= droo;
					DOI <= doo;
				end
			end
		end
	assign dx5p = (dt << 1) + (dx5 >>> 3);
	assign dot = dx5p + (dt >>> 7);
endmodule
