// -----------------------------------------------------------------------------
// dct8_parallel_bank.sv
// -----------------------------------------------------------------------------
// Parallel 8-point DCT-II blocks for the DCT64 radix-8 flow.
//
// dct8_parallel is the combinational arithmetic core from src/DCT/dct_module.v
// without the serial write/read wrapper.  dct8_parallel_bank instantiates eight
// cores so it can consume the transposed outputs of skewdct8_dctii_bank:
//
//   x00..x07 -> DCT8 block 0
//   x10..x17 -> DCT8 block 1
//   ...
//   x70..x77 -> DCT8 block 7
// -----------------------------------------------------------------------------

`ifndef DCT8_PARALLEL_BANK_V
`define DCT8_PARALLEL_BANK_V

`timescale 1ns / 1ps

module dct8_parallel #(
    parameter integer IN_W  = 24,
    parameter integer OUT_W = IN_W + 4
)(
    input  signed [IN_W-1:0] x0,
    input  signed [IN_W-1:0] x1,
    input  signed [IN_W-1:0] x2,
    input  signed [IN_W-1:0] x3,
    input  signed [IN_W-1:0] x4,
    input  signed [IN_W-1:0] x5,
    input  signed [IN_W-1:0] x6,
    input  signed [IN_W-1:0] x7,
    output signed [OUT_W-1:0] y0,
    output signed [OUT_W-1:0] y1,
    output signed [OUT_W-1:0] y2,
    output signed [OUT_W-1:0] y3,
    output signed [OUT_W-1:0] y4,
    output signed [OUT_W-1:0] y5,
    output signed [OUT_W-1:0] y6,
    output signed [OUT_W-1:0] y7
);

    localparam integer COEFF_W  = 16;
    localparam integer FRAC_W   = 15;
    localparam integer STAGE1_W = IN_W + 1;
    localparam integer STAGE2_W = IN_W + 2;
    localparam integer STAGE3_W = IN_W + 3;

    wire signed [STAGE1_W-1:0] x01, x11, x21, x31, x41, x51, x61, x71;
    wire signed [STAGE2_W-1:0] x02, x12, x22, x32, x42, x52, x62, x72;
    wire signed [STAGE3_W-1:0] x03, x13, x23, x33, x43, x53, x63, x73;
    wire signed [OUT_W-1:0] x04, x14, x24, x34, x44, x54, x55, x64, x65, x75;
    wire signed [STAGE2_W-1:0] xx1, xx2, xx3, xx4, yy1, yy2, yy3, yy4;
    wire signed [STAGE3_W-1:0] xx5, xx6, yy5, yy6;
    wire signed [OUT_W-1:0] x23_ext, x33_ext, x43_ext, x53_ext, x63_ext, x73_ext;

    wire signed [COEFF_W-1:0] c5 = 16'sd18205;       // 0.55557 * 2^15
    wire signed [COEFF_W-1:0] c6 = 16'sd12540;       // 0.38268 * 2^15
    wire signed [COEFF_W-1:0] c7 = 16'sd6393;        // 0.19509 * 2^15
    wire signed [COEFF_W-1:0] s5 = 16'sd27246;       // 0.83147 * 2^15
    wire signed [COEFF_W-1:0] s6 = 16'sd30274;       // 0.92388 * 2^15
    wire signed [COEFF_W-1:0] s7 = 16'sd32138;       // 0.98079 * 2^15
    wire signed [COEFF_W-1:0] sqrt8_inv = 16'sd11585; // 0.35355 * 2^15
    wire signed [COEFF_W-1:0] sqrt8 = 16'sd23170;     // 0.70710 * 2^15

    butterfly #(IN_W, STAGE1_W) b1(x01, x71, x0, x7, 1'b1);
    butterfly #(IN_W, STAGE1_W) b2(x11, x61, x1, x6, 1'b1);
    butterfly #(IN_W, STAGE1_W) b3(x21, x51, x2, x5, 1'b1);
    butterfly #(IN_W, STAGE1_W) b4(x31, x41, x3, x4, 1'b1);

    butterfly #(STAGE1_W, STAGE2_W) b5(x02, x32, x01, x31, 1'b1);
    butterfly #(STAGE1_W, STAGE2_W) b6(x12, x22, x11, x21, 1'b1);

    signed_mult #(STAGE1_W, COEFF_W, FRAC_W, STAGE2_W) sm1(.a(x41), .b(c7), .y(xx1));
    signed_mult #(STAGE1_W, COEFF_W, FRAC_W, STAGE2_W) sm2(.a(x41), .b(s7), .y(xx2));
    signed_mult #(STAGE1_W, COEFF_W, FRAC_W, STAGE2_W) sm3(.a(x71), .b(c7), .y(yy1));
    signed_mult #(STAGE1_W, COEFF_W, FRAC_W, STAGE2_W) sm4(.a(x71), .b(s7), .y(yy2));

    assign x42 = xx1 + yy2;
    assign x72 = -xx2 + yy1;

    signed_mult #(STAGE1_W, COEFF_W, FRAC_W, STAGE2_W) sm5(.a(x51), .b(c5), .y(xx3));
    signed_mult #(STAGE1_W, COEFF_W, FRAC_W, STAGE2_W) sm6(.a(x51), .b(s5), .y(xx4));
    signed_mult #(STAGE1_W, COEFF_W, FRAC_W, STAGE2_W) sm7(.a(x61), .b(c5), .y(yy3));
    signed_mult #(STAGE1_W, COEFF_W, FRAC_W, STAGE2_W) sm8(.a(x61), .b(s5), .y(yy4));

    assign x52 = xx3 + yy4;
    assign x62 = yy3 - xx4;

    butterfly #(STAGE2_W, STAGE3_W) b9(x03, x13, x02, x12, 1'b1);

    signed_mult #(STAGE2_W, COEFF_W, FRAC_W, STAGE3_W) sm9(.a(x22), .b(c6), .y(xx5));
    signed_mult #(STAGE2_W, COEFF_W, FRAC_W, STAGE3_W) sm10(.a(x22), .b(s6), .y(xx6));
    signed_mult #(STAGE2_W, COEFF_W, FRAC_W, STAGE3_W) sm11(.a(x32), .b(c6), .y(yy5));
    signed_mult #(STAGE2_W, COEFF_W, FRAC_W, STAGE3_W) sm12(.a(x32), .b(s6), .y(yy6));

    assign x23 = xx5 + yy6;
    assign x33 = -xx6 + yy5;

    butterfly #(STAGE2_W, STAGE3_W) b11(x43, x53, x42, x52, 1'b1);
    butterfly #(STAGE2_W, STAGE3_W) b12(x63, x73, x62, x72, 1'b1);

    signed_mult #(STAGE3_W, COEFF_W, FRAC_W + 1, OUT_W) sm13(.a(x03), .b(sqrt8), .y(x04));
    signed_mult #(STAGE3_W, COEFF_W, FRAC_W, OUT_W) sm14(.a(x13), .b(sqrt8_inv), .y(x14));

    assign x23_ext = {{(OUT_W-STAGE3_W){x23[STAGE3_W-1]}}, x23};
    assign x33_ext = {{(OUT_W-STAGE3_W){x33[STAGE3_W-1]}}, x33};
    assign x43_ext = {{(OUT_W-STAGE3_W){x43[STAGE3_W-1]}}, x43};
    assign x53_ext = {{(OUT_W-STAGE3_W){x53[STAGE3_W-1]}}, x53};
    assign x63_ext = {{(OUT_W-STAGE3_W){x63[STAGE3_W-1]}}, x63};
    assign x73_ext = {{(OUT_W-STAGE3_W){x73[STAGE3_W-1]}}, x73};

    assign x24 = x23_ext >>> 1;
    assign x34 = x33_ext >>> 1;
    assign x44 = x43_ext >>> 1;

    assign x54 = x53_ext + x63_ext;
    assign x64 = x53_ext - x63_ext;
    signed_mult #(OUT_W, COEFF_W, FRAC_W + 1, OUT_W) sm15(.a(x54), .b(sqrt8), .y(x55));
    signed_mult #(OUT_W, COEFF_W, FRAC_W, OUT_W) sm16(.a(x64), .b(sqrt8_inv), .y(x65));

    assign x75 = (-x73_ext) >>> 1;

    assign y0 = x04;
    assign y1 = x44;
    assign y2 = x24;
    assign y3 = x55;
    assign y4 = x14;
    assign y5 = x65;
    assign y6 = x34;
    assign y7 = x75;

endmodule

`endif
