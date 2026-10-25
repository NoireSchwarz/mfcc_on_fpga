`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module complex_twiddle_mul (
	x_re,
	x_im,
	w_re,
	w_im,
	y_re,
	y_im
);
	reg _sv2v_0;
	parameter signed [31:0] NB = 16;
	parameter signed [31:0] TW = 16;
	parameter signed [31:0] OUTW = 64;
	parameter signed [31:0] SHIFT = TW - 1;
	parameter [0:0] SHIFT_AFTER_SUM = 1'b1;
	input wire signed [NB - 1:0] x_re;
	input wire signed [NB - 1:0] x_im;
	input wire signed [TW - 1:0] w_re;
	input wire signed [TW - 1:0] w_im;
	output reg signed [OUTW - 1:0] y_re;
	output reg signed [OUTW - 1:0] y_im;
	localparam signed [31:0] MW = NB + TW;
	localparam signed [31:0] EXTW = (OUTW > MW ? OUTW : MW);
	reg signed [MW - 1:0] mul_rr;
	reg signed [MW - 1:0] mul_ii;
	reg signed [MW - 1:0] mul_ri;
	reg signed [MW - 1:0] mul_ir;
	reg signed [EXTW - 1:0] rr_ext;
	reg signed [EXTW - 1:0] ii_ext;
	reg signed [EXTW - 1:0] ri_ext;
	reg signed [EXTW - 1:0] ir_ext;
	always @(*) begin
		if (_sv2v_0)
			;
		mul_rr = x_re * w_re;
		mul_ii = x_im * w_im;
		mul_ri = x_re * w_im;
		mul_ir = x_im * w_re;
		rr_ext = {{EXTW - MW {mul_rr[MW - 1]}}, mul_rr};
		ii_ext = {{EXTW - MW {mul_ii[MW - 1]}}, mul_ii};
		ri_ext = {{EXTW - MW {mul_ri[MW - 1]}}, mul_ri};
		ir_ext = {{EXTW - MW {mul_ir[MW - 1]}}, mul_ir};
		if (SHIFT_AFTER_SUM) begin
			y_re = (rr_ext - ii_ext) >>> SHIFT;
			y_im = (ri_ext + ir_ext) >>> SHIFT;
		end
		else begin
			y_re = (rr_ext >>> SHIFT) - (ii_ext >>> SHIFT);
			y_im = (ri_ext >>> SHIFT) + (ir_ext >>> SHIFT);
		end
	end
	initial _sv2v_0 = 0;
endmodule
