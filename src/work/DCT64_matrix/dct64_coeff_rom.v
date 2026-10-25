`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module dct64_coeff_rom (
	CLK,
	ED,
	ADDR,
	DOUT
);
	parameter DATA_W = 20;
	parameter COEFF_FILE = "dct64_coeff_q14.mem";
	input wire CLK;
	input wire ED;
	input wire [11:0] ADDR;
	output reg signed [DATA_W - 1:0] DOUT;
	reg signed [DATA_W - 1:0] coeff_mem [0:4095];
	initial $readmemh(COEFF_FILE, coeff_mem);
	always @(posedge CLK)
		if (ED)
			DOUT <= coeff_mem[ADDR];
endmodule
