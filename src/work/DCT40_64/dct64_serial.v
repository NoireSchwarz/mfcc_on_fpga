`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module dct64_serial (
	clk,
	rst,
	shift,
	s_data,
	s_valid,
	s_ready,
	m_data,
	m_index,
	m_valid,
	m_ready,
	ovf_skew,
	ovf_dct
);
	reg _sv2v_0;
	parameter signed [31:0] DATA_W = 16;
	parameter signed [31:0] SKEW_OUT_W = 24;
	parameter signed [31:0] C_OUT_W = SKEW_OUT_W + 2;
	input wire clk;
	input wire rst;
	input wire [3:0] shift;
	input wire signed [(64 * DATA_W) - 1:0] s_data;
	input wire s_valid;
	output wire s_ready;
	output wire signed [C_OUT_W - 1:0] m_data;
	output wire [5:0] m_index;
	output wire m_valid;
	input wire m_ready;
	output reg ovf_skew;
	output reg ovf_dct;
	localparam integer SKEW_NORM_W = SKEW_OUT_W - 2;
	localparam integer DCT_OUT_W = SKEW_NORM_W + 4;
	reg [2:0] state;
	wire signed [SKEW_NORM_W - 1:0] norm_skew_dout;
	wire norm_skew_ed;
	wire norm_skew_start;
	wire norm_skew_ovf;
	wire norm_skew_rdy;
	reg skew_norm_valid;
	reg skew_norm_last;
	wire signed [SKEW_NORM_W - 1:0] dct_s_data;
	wire dct_s_valid;
	wire dct_s_ready;
	reg [5:0] dct_norm_index;
	wire signed [SKEW_OUT_W - 1:0] norm_dct_dout;
	wire norm_dct_ed;
	wire norm_dct_start;
	wire norm_dct_ovf;
	wire norm_dct_rdy;
	reg dct_norm_valid;
	reg dct_norm_last;
	reg signed [(64 * SKEW_OUT_W) - 1:0] dct_norm_buf;
	reg signed [(64 * DATA_W) - 1:0] input_hold;
	wire signed [(64 * DATA_W) - 1:0] skew_input;
	wire skew_start;
	wire signed [SKEW_OUT_W - 1:0] skew_m_data;
	wire [5:0] skew_m_index;
	wire skew_m_valid;
	wire skew_m_ready;
	wire skew_rdy;
	wire dct_start;
	wire signed [DCT_OUT_W - 1:0] dct_m_data;
	wire [5:0] dct_m_index;
	wire dct_m_valid;
	wire dct_m_ready;
	wire dct_rdy;
	wire c64_start;
	wire c64_ready;
	wire c64_rdy;
	reg d_skew_start;
	reg q_skew_start;
	reg d_dct_start;
	reg q_dct_start;
	reg d_c64_start;
	reg q_c64_start;
	SKEW_BUFRAM64 #(.DATA_W(DATA_W)) U_SKEW_BUF(
		.DIN(input_hold),
		.DOUT(skew_input)
	);
	skewdct8_dctii_tdm_bank #(
		.DATA_W(DATA_W),
		.OUT_W(SKEW_OUT_W)
	) U_SKEW_TDM(
		.CLK(clk),
		.RST(rst),
		.ED(1'b1),
		.START(skew_start),
		.DIN(skew_input),
		.m_data(skew_m_data),
		.m_index(skew_m_index),
		.m_valid(skew_m_valid),
		.m_ready(skew_m_ready),
		.RDY(skew_rdy)
	);
	NORM #(.nb(SKEW_OUT_W - 4)) U_NORM_SKEW(
		.CLK(clk),
		.ED(norm_skew_ed),
		.START(norm_skew_start),
		.DIN(skew_m_data),
		.SHIFT(shift[1:0]),
		.OVF(norm_skew_ovf),
		.RDY(norm_skew_rdy),
		.DOUT(norm_skew_dout)
	);
	dct8_tdm_bank #(
		.IN_W(SKEW_NORM_W),
		.OUT_W(DCT_OUT_W)
	) U_DCT_TDM(
		.CLK(clk),
		.RST(rst),
		.ED(1'b1),
		.START(dct_start),
		.s_data(dct_s_data),
		.s_valid(dct_s_valid),
		.s_ready(dct_s_ready),
		.m_data(dct_m_data),
		.m_index(dct_m_index),
		.m_valid(dct_m_valid),
		.m_ready(dct_m_ready),
		.RDY(dct_rdy)
	);
	NORM #(.nb(DCT_OUT_W - 4)) U_NORM_DCT(
		.CLK(clk),
		.ED(norm_dct_ed),
		.START(norm_dct_start),
		.DIN(dct_m_data),
		.SHIFT(shift[3:2]),
		.OVF(norm_dct_ovf),
		.RDY(norm_dct_rdy),
		.DOUT(norm_dct_dout)
	);
	c64_8_postadd_serial #(
		.IN_W(SKEW_OUT_W),
		.OUT_W(C_OUT_W),
		.ORTHO_DCT8_INPUT(1)
	) U_C64_8(
		.CLK(clk),
		.RST(rst),
		.ED(1'b1),
		.START(c64_start),
		.DIN(dct_norm_buf),
		.m_data(m_data),
		.m_index(m_index),
		.m_valid(m_valid),
		.m_ready(c64_ready),
		.RDY(c64_rdy)
	);
	assign s_ready = state == 3'd0;
	assign skew_start = q_skew_start;
	assign skew_m_ready = state == 3'd2;
	assign norm_skew_ed = skew_m_valid && skew_m_ready;
	assign norm_skew_start = norm_skew_ed && (skew_m_index == 6'd0);
	assign dct_start = q_dct_start;
	assign dct_s_data = norm_skew_dout;
	assign dct_s_valid = skew_norm_valid;
	assign dct_m_ready = state == 3'd3;
	assign norm_dct_ed = dct_m_valid && dct_m_ready;
	assign norm_dct_start = norm_dct_ed && (dct_m_index == 6'd0);
	assign c64_start = q_c64_start;
	assign c64_ready = (state == 3'd4) && m_ready;
	always @(*) begin
		if (_sv2v_0)
			;
		d_skew_start = 1'b0;
		d_dct_start = 1'b0;
		d_c64_start = 1'b0;
		if (((state == 3'd0) && s_valid) && s_ready)
			d_skew_start = 1'b1;
		if ((state == 3'd1) && skew_m_valid)
			d_dct_start = 1'b1;
		if (((state == 3'd3) && dct_norm_valid) && dct_norm_last)
			d_c64_start = 1'b1;
	end
	always @(posedge clk)
		if (rst) begin
			state <= 3'd0;
			dct_norm_index <= 6'd0;
			skew_norm_valid <= 1'b0;
			skew_norm_last <= 1'b0;
			dct_norm_valid <= 1'b0;
			dct_norm_last <= 1'b0;
			q_skew_start <= 1'b0;
			q_dct_start <= 1'b0;
			q_c64_start <= 1'b0;
			ovf_skew <= 1'b0;
			ovf_dct <= 1'b0;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < 64; i = i + 1)
					begin
						input_hold[(63 - i) * DATA_W+:DATA_W] <= 1'sb0;
						dct_norm_buf[(63 - i) * SKEW_OUT_W+:SKEW_OUT_W] <= 1'sb0;
					end
			end
		end
		else begin
			q_skew_start <= d_skew_start;
			q_dct_start <= d_dct_start;
			q_c64_start <= d_c64_start;
			skew_norm_valid <= norm_skew_ed;
			if (norm_skew_ed)
				skew_norm_last <= skew_m_index == 6'd63;
			dct_norm_valid <= norm_dct_ed;
			if (norm_dct_ed) begin
				dct_norm_index <= dct_m_index;
				dct_norm_last <= dct_m_index == 6'd63;
			end
			case (state)
				3'd0: begin
					ovf_skew <= 1'b0;
					ovf_dct <= 1'b0;
					if (s_valid && s_ready) begin
						begin : sv2v_autoblock_2
							reg signed [31:0] i;
							for (i = 0; i < 64; i = i + 1)
								input_hold[(63 - i) * DATA_W+:DATA_W] <= s_data[(63 - i) * DATA_W+:DATA_W];
						end
						state <= 3'd1;
					end
				end
				3'd1:
					if (skew_m_valid)
						state <= 3'd2;
				3'd2:
					if (skew_norm_valid) begin
						ovf_skew <= ovf_skew | norm_skew_ovf;
						if (skew_norm_last)
							state <= 3'd3;
					end
				3'd3:
					if (dct_norm_valid) begin
						dct_norm_buf[(63 - dct_norm_index) * SKEW_OUT_W+:SKEW_OUT_W] <= norm_dct_dout;
						ovf_dct <= ovf_dct | norm_dct_ovf;
						if (dct_norm_last)
							state <= 3'd4;
					end
				3'd4:
					if (c64_rdy)
						state <= 3'd0;
				default: state <= 3'd0;
			endcase
		end
	initial _sv2v_0 = 0;
endmodule
