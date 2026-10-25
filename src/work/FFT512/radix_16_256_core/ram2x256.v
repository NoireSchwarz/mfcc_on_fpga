`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module RAM2x256C (
	CLK,
	ED,
	WE,
	ODD,
	ADDRW,
	ADDRR,
	DR,
	DI,
	DOR,
	DOI
);
	parameter nb = 16;
	output wire [nb - 1:0] DOR;
	output wire [nb - 1:0] DOI;
	input wire CLK;
	input wire ED;
	input wire WE;
	input wire ODD;
	input wire [7:0] ADDRW;
	input wire [7:0] ADDRR;
	input wire [nb - 1:0] DR;
	input wire [nb - 1:0] DI;
	reg oddd;
	reg odd2;
	always @(posedge CLK)
		if (ED) begin
			oddd <= ODD;
			odd2 <= oddd;
		end
	wire [8:0] addrr2;
	wire [8:0] addrw2;
	wire [(2 * nb) - 1:0] di;
	assign addrr2 = {ODD, ADDRR};
	assign addrw2 = {~ODD, ADDRW};
	assign di = {DR, DI};
	reg [(2 * nb) - 1:0] doi;
	(* ram_style = "block", ramstyle = "M10K" *) reg [(2 * nb) - 1:0] ram [511:0];
	reg [8:0] read_addra;
	always @(posedge CLK)
		if (ED) begin
			if (WE)
				ram[addrw2] <= di;
			read_addra <= addrr2;
			doi <= ram[read_addra];
		end
	assign DOR = doi[(2 * nb) - 1:nb];
	assign DOI = doi[nb - 1:0];
endmodule
