`timescale 1ns / 1ps

module complex_twiddle_mul #(
    parameter int NB = 16,
    parameter int TW = 16,
    parameter int OUTW = 64,
    parameter int SHIFT = TW - 1,
    parameter bit SHIFT_AFTER_SUM = 1'b1
)(
    input  logic signed [NB-1:0]  x_re,
    input  logic signed [NB-1:0]  x_im,
    input  logic signed [TW-1:0]  w_re,
    input  logic signed [TW-1:0]  w_im,
    output logic signed [OUTW-1:0] y_re,
    output logic signed [OUTW-1:0] y_im
);

    localparam int MW = NB + TW;
    localparam int EXTW = (OUTW > MW) ? OUTW : MW;

    logic signed [MW-1:0] mul_rr;
    logic signed [MW-1:0] mul_ii;
    logic signed [MW-1:0] mul_ri;
    logic signed [MW-1:0] mul_ir;
    logic signed [EXTW-1:0] rr_ext;
    logic signed [EXTW-1:0] ii_ext;
    logic signed [EXTW-1:0] ri_ext;
    logic signed [EXTW-1:0] ir_ext;

    always_comb begin
        mul_rr = x_re * w_re;
        mul_ii = x_im * w_im;
        mul_ri = x_re * w_im;
        mul_ir = x_im * w_re;

        rr_ext = {{(EXTW-MW){mul_rr[MW-1]}}, mul_rr};
        ii_ext = {{(EXTW-MW){mul_ii[MW-1]}}, mul_ii};
        ri_ext = {{(EXTW-MW){mul_ri[MW-1]}}, mul_ri};
        ir_ext = {{(EXTW-MW){mul_ir[MW-1]}}, mul_ir};

        if (SHIFT_AFTER_SUM) begin
            y_re = (rr_ext - ii_ext) >>> SHIFT;
            y_im = (ri_ext + ir_ext) >>> SHIFT;
        end else begin
            y_re = (rr_ext >>> SHIFT) - (ii_ext >>> SHIFT);
            y_im = (ri_ext >>> SHIFT) + (ir_ext >>> SHIFT);
        end
    end

endmodule
