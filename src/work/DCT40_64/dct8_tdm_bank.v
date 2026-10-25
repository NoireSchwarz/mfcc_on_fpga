`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module dct8_tdm_bank (
	CLK,
	RST,
	ED,
	START,
	s_data,
	s_valid,
	s_ready,
	m_data,
	m_index,
	m_valid,
	m_ready,
	RDY
);
	reg _sv2v_0;
	parameter integer IN_W = 24;
	parameter integer OUT_W = IN_W + 4;
	input wire CLK;
	input wire RST;
	input wire ED;
	input wire START;
	input wire signed [IN_W - 1:0] s_data;
	input wire s_valid;
	output wire s_ready;
	output reg signed [OUT_W - 1:0] m_data;
	output reg [5:0] m_index;
	output wire m_valid;
	input wire m_ready;
	output reg RDY;
	reg [1:0] state;
	reg [5:0] input_idx;
	reg [2:0] block_idx;
	reg issue_done;
	wire core_valid;
	wire [2:0] core_tag;
	wire issue_valid = (state == 2'd2) && !issue_done;
	reg [5:0] out_idx;
	reg signed [IN_W - 1:0] din_hold [0:63];
	reg signed [OUT_W - 1:0] dout_hold [0:63];
	wire signed [IN_W - 1:0] dct_x [0:7];
	wire signed [OUT_W - 1:0] dct_y [0:7];
	genvar _gv_gi_2;
	generate
		for (_gv_gi_2 = 0; _gv_gi_2 < 8; _gv_gi_2 = _gv_gi_2 + 1) begin : GEN_DCT_X
			localparam gi = _gv_gi_2;
			assign dct_x[gi] = din_hold[{block_idx, gi[2:0]}];
		end
	endgenerate
	dct8_parallel #(
		.IN_W(IN_W),
		.OUT_W(OUT_W)
	) U_DCT8(
		.CLK(CLK), .RST(RST), .ED(ED),
		.in_valid(issue_valid), .in_tag(block_idx),
		.out_valid(core_valid), .out_tag(core_tag),
		.x0(dct_x[0]),
		.x1(dct_x[1]),
		.x2(dct_x[2]),
		.x3(dct_x[3]),
		.x4(dct_x[4]),
		.x5(dct_x[5]),
		.x6(dct_x[6]),
		.x7(dct_x[7]),
		.y0(dct_y[0]),
		.y1(dct_y[1]),
		.y2(dct_y[2]),
		.y3(dct_y[3]),
		.y4(dct_y[4]),
		.y5(dct_y[5]),
		.y6(dct_y[6]),
		.y7(dct_y[7])
	);
	assign s_ready = state == 2'd1;
	assign m_valid = state == 2'd3;
	always @(*) begin
		if (_sv2v_0)
			;
		m_index = out_idx;
		m_data = dout_hold[out_idx];
	end
	always @(posedge CLK)
		if (RST) begin
			state <= 2'd0;
			input_idx <= 6'd0;
			block_idx <= 3'd0;
			issue_done <= 1'b0;
			out_idx <= 6'd0;
			RDY <= 1'b0;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < 64; i = i + 1)
					begin
						din_hold[i] <= 1'sb0;
						dout_hold[i] <= 1'sb0;
					end
			end
		end
		else if (ED) begin
			RDY <= 1'b0;
			case (state)
				2'd0:
					if (START) begin
						input_idx <= 6'd0;
						state <= 2'd1;
					end
				2'd1:
					if (s_valid && s_ready) begin
						din_hold[input_idx] <= s_data;
						if (input_idx == 6'd63) begin
							input_idx <= 6'd0;
							block_idx <= 3'd0;
							issue_done <= 1'b0;
							state <= 2'd2;
						end
						else
							input_idx <= input_idx + 6'd1;
					end
				2'd2: begin
					// Keep issuing while prior groups advance through the core.
					if (!issue_done) begin
						if (block_idx == 3'd7) issue_done <= 1'b1;
						else block_idx <= block_idx + 3'd1;
					end
					if (core_valid) begin : write_completed_group
						reg signed [31:0] k;
						for (k = 0; k < 8; k = k + 1)
							dout_hold[{core_tag, k[2:0]}] <= dct_y[k];
						if (core_tag == 3'd7) begin
						out_idx <= 6'd0;
						state <= 2'd3;
						end
					end
				end
				2'd3:
					if (m_valid && m_ready) begin
						if (out_idx == 6'd63) begin
							out_idx <= 6'd0;
							RDY <= 1'b1;
							state <= 2'd0;
						end
						else
							out_idx <= out_idx + 6'd1;
					end
				default: state <= 2'd0;
			endcase
		end
	initial _sv2v_0 = 0;
endmodule
