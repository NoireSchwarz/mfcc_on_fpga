`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module BUFRAM256C (
	CLK,
	RST,
	ED,
	START,
	DR,
	DI,
	RDY,
	DOR,
	DOI
);
	parameter nb = 16;
	output reg RDY;
	output wire [nb - 1:0] DOR;
	output wire [nb - 1:0] DOI;
	input wire CLK;
	input wire RST;
	input wire ED;
	input wire START;
	input wire [nb - 1:0] DR;
	input wire [nb - 1:0] DI;
	wire odd;
	wire we;
	wire [7:0] addrw;
	wire [7:0] addrr;
	reg [8:0] addr;
	reg [9:0] ct2;
	always @(posedge CLK)
		if (RST) begin
			addr <= 8'b00000000;
			ct2 <= 9'b100000001;
			RDY <= 1'b0;
		end
		else if (START) begin
			addr <= 8'b00000000;
			ct2 <= 8'b00000000;
			RDY <= 1'b0;
		end
		else if (ED) begin
			RDY <= 1'b0;
			addr <= addr + 1;
			if (ct2 != 257)
				ct2 <= ct2 + 1;
			if (ct2 == 256)
				RDY <= 1'b1;
		end
	assign addrw = addr[7:0];
	assign odd = addr[8];
	assign addrr = {addr[3:0], addr[7:4]};
	assign we = ED;
	RAM2x256C #(.nb(nb)) URAM(
		.CLK(CLK),
		.ED(ED),
		.WE(we),
		.ODD(odd),
		.ADDRW(addrw),
		.ADDRR(addrr),
		.DR(DR),
		.DI(DI),
		.DOR(DOR),
		.DOI(DOI)
	);
endmodule
