`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module dct64_matrix_datapath (
	clk,
	rst,
	s_data,
	shift,
	frame_load,
	sample_we,
	sample_wdata,
	sample_rdata,
	coeff_rdata,
	product_en,
	accumulator_clear,
	accumulator_en,
	result_we,
	result_wdata,
	ovf_dct
);
	parameter DATA_W = 16;
	parameter C_OUT_W = 26;
	parameter COEF_W = 20;
	parameter COEF_FRAC = 14;
	parameter ACC_W = (DATA_W + COEF_W) + 6;
	input wire clk;
	input wire rst;
	input wire [(64 * DATA_W) - 1:0] s_data;
	input wire [3:0] shift;
	input wire frame_load;
	input wire sample_we;
	output wire [DATA_W - 1:0] sample_wdata;
	input wire signed [DATA_W - 1:0] sample_rdata;
	input wire signed [COEF_W - 1:0] coeff_rdata;
	input wire product_en;
	input wire accumulator_clear;
	input wire accumulator_en;
	input wire result_we;
	output wire signed [C_OUT_W - 1:0] result_wdata;
	output reg ovf_dct;
	localparam PROD_W = DATA_W + COEF_W;
	localparam SCALE_W = ACC_W + 6;
	localparam signed [ACC_W - 1:0] ONE = {{ACC_W - 1 {1'b0}}, 1'b1};
	localparam signed [ACC_W - 1:0] HALF_LSB = (COEF_FRAC == 0 ? 0 : ONE << (COEF_FRAC - 1));
	reg [(64 * DATA_W) - 1:0] frame_shift;
	reg [3:0] shift_hold;
	reg signed [PROD_W - 1:0] product_q;
	reg signed [ACC_W - 1:0] accumulator;
	wire [2:0] left_shift;
	wire signed [ACC_W - 1:0] product_ext;
	wire signed [ACC_W - 1:0] biased;
	wire signed [ACC_W - 1:0] rounded;
	wire signed [SCALE_W - 1:0] rounded_ext;
	wire signed [SCALE_W - 1:0] scaled;
	wire signed [SCALE_W - 1:0] restored;
	assign sample_wdata = frame_shift[DATA_W - 1:0];
	assign left_shift = {1'b0, shift_hold[1:0]} + {1'b0, shift_hold[3:2]};
	assign product_ext = {{ACC_W - PROD_W {product_q[PROD_W - 1]}}, product_q};
	assign biased = (COEF_FRAC == 0 ? accumulator : (accumulator + HALF_LSB) - (accumulator[ACC_W - 1] ? ONE : 0));
	assign rounded = biased >>> COEF_FRAC;
	assign rounded_ext = {{SCALE_W - ACC_W {rounded[ACC_W - 1]}}, rounded};
	assign scaled = (rounded_ext <<< left_shift) >>> 4;
	assign result_wdata = scaled;
	assign restored = result_wdata;
	always @(posedge clk)
		if (rst) begin
			frame_shift <= 0;
			shift_hold <= 0;
		end
		else if (frame_load) begin
			frame_shift <= s_data;
			shift_hold <= shift;
		end
		else if (sample_we)
			frame_shift <= frame_shift >> DATA_W;
	always @(posedge clk)
		if (product_en)
			product_q <= sample_rdata * coeff_rdata;
	always @(posedge clk)
		if (rst)
			accumulator <= 0;
		else if (accumulator_clear)
			accumulator <= 0;
		else if (accumulator_en)
			accumulator <= accumulator + product_ext;
	always @(posedge clk)
		if (rst)
			ovf_dct <= 1'b0;
		else if (frame_load)
			ovf_dct <= 1'b0;
		else if (result_we)
			ovf_dct <= ovf_dct || (restored != scaled);
endmodule
