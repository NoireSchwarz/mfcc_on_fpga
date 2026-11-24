`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module CNORM (
	CLK,
	ED,
	START,
	DR,
	DI,
	SHIFT,
	OVF,
	RDY,
	DOR,
	DOI
);
	parameter nb = 16;
	output reg OVF;
	output reg RDY;
	output wire [nb + 1:0] DOR;
	output wire [nb + 1:0] DOI;
	input wire CLK;
	input wire ED;
	input wire START;
	input wire [nb + 3:0] DR;
	input wire [nb + 3:0] DI;
	input wire [1:0] SHIFT;
	wire signed [nb + 3:0] diri;
	wire signed [nb + 3:0] diii;
	assign diri = DR << SHIFT;
	assign diii = DI << SHIFT;
	reg [nb + 3:0] dir;
	reg [nb + 3:0] dii;
	always @(posedge CLK)
		if (ED) begin
			if (diri[nb + 3] && ~diri[0])
				dir <= diri;
			else
				dir <= diri + 2;
			if (diii[nb + 3] && ~diii[0])
				dii <= diii;
			else
				dii <= diii + 2;
		end
	always @(posedge CLK)
		if (ED) begin
			RDY <= START;
			if (START)
				OVF <= 0;
			else
				case (SHIFT)
					2'b01: OVF <= (DR[nb + 3] != DR[nb + 2]) || (DI[nb + 3] != DI[nb + 2]);
					2'b10: OVF <= (((DR[nb + 3] != DR[nb + 2]) || (DI[nb + 3] != DI[nb + 2])) || (DR[nb + 3] != DR[nb + 1])) || (DI[nb + 3] != DI[nb + 1]);
					2'b11: OVF <= (((((DR[nb + 3] != DR[nb + 2]) || (DI[nb + 3] != DI[nb + 2])) || (DR[nb + 3] != DR[nb])) || (DI[nb + 3] != DI[nb])) || (DR[nb + 3] != DR[nb + 1])) || (DI[nb + 3] != DI[nb + 1]);
				endcase
		end
	assign DOR = dir[nb + 3:2];
	assign DOI = dii[nb + 3:2];
endmodule
