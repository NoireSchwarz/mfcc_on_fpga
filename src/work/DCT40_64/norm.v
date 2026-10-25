`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module NORM (
	CLK,
	ED,
	START,
	DIN,
	SHIFT,
	OVF,
	RDY,
	DOUT
);
	parameter nb = 16;
	input CLK;
	input ED;
	input START;
	input signed [nb + 3:0] DIN;
	input [1:0] SHIFT;
	output reg OVF;
	output reg RDY;
	output wire signed [nb + 1:0] DOUT;
	wire signed [nb + 3:0] diri;
	assign diri = DIN << SHIFT;
	reg signed [nb + 3:0] dir;
	always @(posedge CLK)
		if (ED) begin
			if (diri[nb + 3] && ~diri[0])
				dir <= diri;
			else
				dir <= diri + 2;
		end
	always @(posedge CLK)
		if (ED) begin
			RDY <= START;
			if (START)
				OVF <= 0;
			else
				case (SHIFT)
					2'b01: OVF <= DIN[nb + 3] != DIN[nb + 2];
					2'b10: OVF <= (DIN[nb + 3] != DIN[nb + 2]) || (DIN[nb + 3] != DIN[nb + 1]);
					2'b11: OVF <= ((DIN[nb + 3] != DIN[nb + 2]) || (DIN[nb + 3] != DIN[nb])) || (DIN[nb + 3] != DIN[nb + 1]);
				endcase
		end
	assign DOUT = dir[nb + 3:2];
endmodule
