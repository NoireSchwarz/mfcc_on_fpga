`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module SKEW_BUFRAM64 (
	DIN,
	DOUT
);
	parameter integer DATA_W = 16;
	input wire signed [(64 * DATA_W) - 1:0] DIN;
	output wire signed [(64 * DATA_W) - 1:0] DOUT;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < 8; _gv_i_1 = _gv_i_1 + 1) begin : GEN_ROW
			localparam i = _gv_i_1;
			genvar _gv_j_1;
			for (_gv_j_1 = 0; _gv_j_1 < 8; _gv_j_1 = _gv_j_1 + 1) begin : GEN_COL
				localparam j = _gv_j_1;
				localparam integer SRC_LANE = ((j % 2) == 0 ? (8 * j) + i : ((8 * j) + 7) - i);
				localparam integer DST_LANE = (8 * i) + j;
				assign DOUT[(63 - DST_LANE) * DATA_W+:DATA_W] = DIN[(63 - SRC_LANE) * DATA_W+:DATA_W];
			end
		end
	endgenerate
endmodule
