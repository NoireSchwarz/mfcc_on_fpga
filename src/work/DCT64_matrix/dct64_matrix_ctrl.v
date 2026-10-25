`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module dct64_matrix_ctrl (
	clk,
	rst,
	s_valid,
	s_ready,
	m_valid,
	m_ready,
	m_index,
	frame_load,
	sample_we,
	sample_waddr,
	operand_re,
	sample_raddr,
	coeff_raddr,
	product_en,
	accumulator_clear,
	accumulator_en,
	result_we,
	result_waddr,
	result_re,
	result_raddr
);
	input wire clk;
	input wire rst;
	input wire s_valid;
	output wire s_ready;
	output wire m_valid;
	input wire m_ready;
	output reg [5:0] m_index;
	output wire frame_load;
	output wire sample_we;
	output reg [5:0] sample_waddr;
	output wire operand_re;
	output reg [5:0] sample_raddr;
	output wire [11:0] coeff_raddr;
	output wire product_en;
	output wire accumulator_clear;
	output wire accumulator_en;
	output wire result_we;
	output reg [5:0] result_waddr;
	output wire result_re;
	output wire [5:0] result_raddr;
	localparam ST_IDLE = 0;
	localparam ST_LOAD = 1;
	localparam ST_PRIME = 2;
	localparam ST_MUL = 3;
	localparam ST_MAC = 4;
	localparam ST_STORE = 5;
	localparam ST_OUT_LOAD = 6;
	localparam ST_OUTPUT = 7;
	reg [2:0] state;
	reg [5:0] term_index;
	assign s_ready = state == ST_IDLE;
	assign m_valid = state == ST_OUTPUT;
	assign frame_load = s_valid && s_ready;
	assign sample_we = state == ST_LOAD;
	assign operand_re = ((state == ST_PRIME) || (state == ST_MUL)) || ((state == ST_MAC) && (term_index < 62));
	assign coeff_raddr = {result_waddr, sample_raddr};
	assign product_en = (state == ST_MUL) || (state == ST_MAC);
	assign accumulator_clear = state == ST_PRIME;
	assign accumulator_en = state == ST_MAC;
	assign result_we = state == ST_STORE;
	assign result_re = (state == ST_OUT_LOAD) || (((state == ST_OUTPUT) && m_ready) && (m_index != 63));
	assign result_raddr = (state == ST_OUT_LOAD ? 6'd0 : m_index + 6'd1);
	always @(*)
		if (state == ST_PRIME)
			sample_raddr = 0;
		else if (state == ST_MUL)
			sample_raddr = 1;
		else
			sample_raddr = term_index + 6'd2;
	always @(posedge clk)
		if (rst) begin
			state <= ST_IDLE;
			sample_waddr <= 0;
			result_waddr <= 0;
			term_index <= 0;
			m_index <= 0;
		end
		else
			case (state)
				ST_IDLE:
					if (frame_load) begin
						sample_waddr <= 0;
						result_waddr <= 0;
						state <= ST_LOAD;
					end
				ST_LOAD:
					if (sample_waddr == 63)
						state <= ST_PRIME;
					else
						sample_waddr <= sample_waddr + 6'd1;
				ST_PRIME: begin
					term_index <= 0;
					state <= ST_MUL;
				end
				ST_MUL: state <= ST_MAC;
				ST_MAC:
					if (term_index == 63)
						state <= ST_STORE;
					else
						term_index <= term_index + 6'd1;
				ST_STORE:
					if (result_waddr == 63)
						state <= ST_OUT_LOAD;
					else begin
						result_waddr <= result_waddr + 6'd1;
						state <= ST_PRIME;
					end
				ST_OUT_LOAD: begin
					m_index <= 0;
					state <= ST_OUTPUT;
				end
				ST_OUTPUT:
					if (m_ready) begin
						if (m_index == 63)
							state <= ST_IDLE;
						else
							m_index <= m_index + 6'd1;
					end
				default: state <= ST_IDLE;
			endcase
endmodule
