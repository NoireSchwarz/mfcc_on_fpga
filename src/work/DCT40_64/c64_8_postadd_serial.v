`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module c64_8_postadd_serial (
	CLK,
	RST,
	ED,
	START,
	DIN,
	m_data,
	m_index,
	m_valid,
	m_ready,
	RDY
);
	reg _sv2v_0;
	parameter integer IN_W = 24;
	parameter integer OUT_W = IN_W + 1;
	parameter integer ORTHO_DCT8_INPUT = 0;
	input wire CLK;
	input wire RST;
	input wire ED;
	input wire START;
	input wire signed [(64 * IN_W) - 1:0] DIN;
	output reg signed [OUT_W - 1:0] m_data;
	output reg [5:0] m_index;
	output reg m_valid;
	input wire m_ready;
	output reg RDY;
	localparam integer SQRT2_FRAC = 14;
	localparam signed [15:0] SQRT2_Q14 = 16'sd23170;
	localparam integer COMP_W = OUT_W + 16;
	reg running;
	reg [5:0] out_idx;
	reg signed [IN_W - 1:0] din_hold [0:63];
	function automatic signed [OUT_W - 1:0] calc_lane;
		input reg [5:0] idx;
		reg [2:0] q;
		reg [2:0] r;
		reg signed [31:0] a_idx;
		reg signed [31:0] b_idx;
		reg signed [COMP_W - 1:0] a_scaled_full;
		begin
			q = idx[5:3];
			r = idx[2:0];
			if (r == 3'd0)
				calc_lane = din_hold[q];
			else begin
				a_idx = (8 * r) + q;
				if (q < 3'd7) begin
					b_idx = ((8 * (8 - r)) + q) + 1;
					if (ORTHO_DCT8_INPUT && (q == 3'd0)) begin
						a_scaled_full = din_hold[a_idx] * SQRT2_Q14;
						calc_lane = (a_scaled_full >>> SQRT2_FRAC) + din_hold[b_idx];
					end
					else
						calc_lane = din_hold[a_idx] + din_hold[b_idx];
				end
				else
					calc_lane = din_hold[a_idx];
			end
		end
	endfunction
	always @(out_idx or din_hold[0] or din_hold[1] or din_hold[2] or din_hold[3] or din_hold[4] or din_hold[5] or din_hold[6] or din_hold[7] or din_hold[8] or din_hold[9] or din_hold[10] or din_hold[11] or din_hold[12] or din_hold[13] or din_hold[14] or din_hold[15] or din_hold[16] or din_hold[17] or din_hold[18] or din_hold[19] or din_hold[20] or din_hold[21] or din_hold[22] or din_hold[23] or din_hold[24] or din_hold[25] or din_hold[26] or din_hold[27] or din_hold[28] or din_hold[29] or din_hold[30] or din_hold[31] or din_hold[32] or din_hold[33] or din_hold[34] or din_hold[35] or din_hold[36] or din_hold[37] or din_hold[38] or din_hold[39] or din_hold[40] or din_hold[41] or din_hold[42] or din_hold[43] or din_hold[44] or din_hold[45] or din_hold[46] or din_hold[47] or din_hold[48] or din_hold[49] or din_hold[50] or din_hold[51] or din_hold[52] or din_hold[53] or din_hold[54] or din_hold[55] or din_hold[56] or din_hold[57] or din_hold[58] or din_hold[59] or din_hold[60] or din_hold[61] or din_hold[62] or din_hold[63] or _sv2v_0) begin
		if (_sv2v_0)
			;
		m_data = calc_lane(out_idx);
		m_index = out_idx;
	end
	always @(posedge CLK)
		if (RST) begin
			running <= 1'b0;
			out_idx <= 6'd0;
			m_valid <= 1'b0;
			RDY <= 1'b0;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < 64; i = i + 1)
					din_hold[i] <= 1'sb0;
			end
		end
		else if (ED) begin
			RDY <= 1'b0;
			if (START) begin
				running <= 1'b1;
				out_idx <= 6'd0;
				m_valid <= 1'b1;
				begin : sv2v_autoblock_2
					reg signed [31:0] i;
					for (i = 0; i < 64; i = i + 1)
						din_hold[i] <= DIN[(63 - i) * IN_W+:IN_W];
				end
			end
			else if ((running && m_valid) && m_ready) begin
				if (out_idx == 6'd63) begin
					running <= 1'b0;
					m_valid <= 1'b0;
					RDY <= 1'b1;
				end
				else
					out_idx <= out_idx + 6'd1;
			end
		end
	initial _sv2v_0 = 0;
endmodule
