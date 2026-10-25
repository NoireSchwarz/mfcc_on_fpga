`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module skewdct8_dctii_tdm_bank (
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
	parameter integer DATA_W = 16;
	parameter integer COEF_W = 20;
	parameter integer COEF_FRAC = 14;
	parameter integer ACC_W = 48;
	parameter integer OUT_W = 24;
	input wire CLK;
	input wire RST;
	input wire ED;
	input wire START;
	input wire signed [(64 * DATA_W) - 1:0] DIN;
	output reg signed [OUT_W - 1:0] m_data;
	output reg [5:0] m_index;
	output wire m_valid;
	input wire m_ready;
	output reg RDY;
	reg [1:0] state;
	reg [2:0] block_idx;
	reg issue_done;
	wire core_valid;
	wire [2:0] core_tag;
	wire issue_valid = (state == 2'd1) && !issue_done;
	reg [5:0] out_idx;
	reg signed [OUT_W - 1:0] dout_hold [0:63];
	wire signed [(8 * DATA_W) - 1:0] skew_x;
	wire signed [(8 * OUT_W) - 1:0] skew_y;
	genvar _gv_gi_1;
	generate
		for (_gv_gi_1 = 0; _gv_gi_1 < 8; _gv_gi_1 = _gv_gi_1 + 1) begin : GEN_SKEW_X
			localparam gi = _gv_gi_1;
			assign skew_x[(7 - gi) * DATA_W+:DATA_W] = DIN[(63 - {block_idx, gi[2:0]}) * DATA_W+:DATA_W];
		end
	endgenerate
	skewdct8_dctii_dyn #(
		.DATA_W(DATA_W),
		.COEF_W(COEF_W),
		.COEF_FRAC(COEF_FRAC),
		.ACC_W(ACC_W),
		.OUT_W(OUT_W)
	) U_SKEW_DYN(
		.CLK(CLK), .RST(RST), .ED(ED),
		.in_valid(issue_valid), .in_tag(block_idx),
		.out_valid(core_valid), .out_tag(core_tag),
		.BLOCK(block_idx),
		.X(skew_x),
		.Y(skew_y)
	);
	assign m_valid = state == 2'd2;
	always @(*) begin
		if (_sv2v_0)
			;
		m_index = out_idx;
		m_data = dout_hold[out_idx];
	end
	always @(posedge CLK)
		if (RST) begin
			state <= 2'd0;
			block_idx <= 3'd0;
			issue_done <= 1'b0;
			out_idx <= 6'd0;
			RDY <= 1'b0;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < 64; i = i + 1)
					dout_hold[i] <= 1'sb0;
			end
		end
		else if (ED) begin
			RDY <= 1'b0;
			case (state)
				2'd0:
					if (START) begin
						block_idx <= 3'd0;
						issue_done <= 1'b0;
						state <= 2'd1;
					end
				2'd1: begin
					// Issue eight groups consecutively, then drain the pipeline.
					if (!issue_done) begin
						if (block_idx == 3'd7) issue_done <= 1'b1;
						else block_idx <= block_idx + 3'd1;
					end
					if (core_valid) begin : write_completed_group
						reg signed [31:0] k;
						for (k = 0; k < 8; k = k + 1)
							dout_hold[{k[2:0], core_tag}] <= skew_y[(7 - k) * OUT_W+:OUT_W];
						if (core_tag == 3'd7) begin
						out_idx <= 6'd0;
						state <= 2'd2;
						end
					end
				end
				2'd2:
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
module skewdct8_dctii_coeff_rom (
	BLOCK,
	C
);
	reg _sv2v_0;
	parameter integer COEF_W = 20;
	parameter COEFF_FILE = "skewdct8_coeff_rom.mem";
	input wire [2:0] BLOCK;
	output reg signed [(64 * COEF_W) - 1:0] C;
	localparam integer ROM_W = 20;
	reg signed [ROM_W - 1:0] coeff_mem [0:511];
	initial $readmemh(COEFF_FILE, coeff_mem);
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	function automatic signed [31:0] coeff_addr;
		input reg [2:0] block;
		input reg signed [31:0] row;
		input reg signed [31:0] col;
		coeff_addr = ((sv2v_cast_32_signed(block) * 64) + (row * 8)) + col;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] row;
			for (row = 0; row < 8; row = row + 1)
				begin : sv2v_autoblock_2
					reg signed [31:0] col;
					for (col = 0; col < 8; col = col + 1)
						C[(((7 - row) * 8) + (7 - col)) * COEF_W+:COEF_W] = coeff_mem[coeff_addr(BLOCK, row, col)];
				end
		end
	end
	initial _sv2v_0 = 0;
endmodule
module skewdct8_dctii_dyn (
	CLK, RST, ED, in_valid, in_tag, out_valid, out_tag,
	BLOCK,
	X,
	Y
);
	parameter integer DATA_W = 16;
	parameter integer COEF_W = 20;
	parameter integer COEF_FRAC = 14;
	parameter integer ACC_W = 48;
	parameter integer OUT_W = 24;
	input wire CLK, RST, ED, in_valid;
	input wire [2:0] in_tag;
	output wire out_valid;
	output wire [2:0] out_tag;
	input wire [2:0] BLOCK;
	input wire signed [(8 * DATA_W) - 1:0] X;
	output wire signed [(8 * OUT_W) - 1:0] Y;
	wire signed [(64 * COEF_W) - 1:0] coeff;
	skewdct8_dctii_coeff_rom #(.COEF_W(COEF_W)) U_COEFF_ROM(
		.BLOCK(BLOCK),
		.C(coeff)
	);
	skewdct8 #(
		.DATA_W(DATA_W),
		.COEF_W(COEF_W),
		.COEF_FRAC(COEF_FRAC),
		.ACC_W(ACC_W),
		.OUT_W(OUT_W),
		.USE_COEFF_PORT(1)
	) U_SKEWDCT8(
		.CLK(CLK), .RST(RST), .ED(ED),
		.in_valid(in_valid), .in_tag(in_tag),
		.out_valid(out_valid), .out_tag(out_tag),
		.x0(X[7 * DATA_W+:DATA_W]),
		.x1(X[6 * DATA_W+:DATA_W]),
		.x2(X[5 * DATA_W+:DATA_W]),
		.x3(X[4 * DATA_W+:DATA_W]),
		.x4(X[3 * DATA_W+:DATA_W]),
		.x5(X[2 * DATA_W+:DATA_W]),
		.x6(X[DATA_W+:DATA_W]),
		.x7(X[0+:DATA_W]),
		.y0(Y[7 * OUT_W+:OUT_W]),
		.y1(Y[6 * OUT_W+:OUT_W]),
		.y2(Y[5 * OUT_W+:OUT_W]),
		.y3(Y[4 * OUT_W+:OUT_W]),
		.y4(Y[3 * OUT_W+:OUT_W]),
		.y5(Y[2 * OUT_W+:OUT_W]),
		.y6(Y[OUT_W+:OUT_W]),
		.y7(Y[0+:OUT_W]),
		.c_in(coeff)
	);
endmodule
