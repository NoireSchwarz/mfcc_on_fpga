`timescale 1ns/1ps
// Six registered stages: input/coefficient selection, products, three adder levels, rounding.
// ED freezes data, tags and validity together; RST flushes validity independently of ED.
module skewdct8 (
	CLK, RST, ED, in_valid, in_tag, out_valid, out_tag,
	x0,
	x1,
	x2,
	x3,
	x4,
	x5,
	x6,
	x7,
	y0,
	y1,
	y2,
	y3,
	y4,
	y5,
	y6,
	y7,
	c_in
);
	parameter integer DATA_W = 16;
	parameter integer COEF_W = 16;
	parameter integer COEF_FRAC = 14;
	parameter integer ACC_W = 40;
	parameter integer OUT_W = 24;
	parameter integer USE_COEFF_PORT = 0;
	parameter signed [COEF_W - 1:0] C00 = 16'sd16384;
	parameter signed [COEF_W - 1:0] C01 = 16'sd16069;
	parameter signed [COEF_W - 1:0] C02 = 16'sd15137;
	parameter signed [COEF_W - 1:0] C03 = 16'sd13623;
	parameter signed [COEF_W - 1:0] C04 = 16'sd11585;
	parameter signed [COEF_W - 1:0] C05 = 16'sd9102;
	parameter signed [COEF_W - 1:0] C06 = 16'sd6270;
	parameter signed [COEF_W - 1:0] C07 = 16'sd3196;
	parameter signed [COEF_W - 1:0] C10 = 16'sd16384;
	parameter signed [COEF_W - 1:0] C11 = 16'sd13623;
	parameter signed [COEF_W - 1:0] C12 = 16'sd6270;
	parameter signed [COEF_W - 1:0] C13 = -16'sd3196;
	parameter signed [COEF_W - 1:0] C14 = -16'sd11585;
	parameter signed [COEF_W - 1:0] C15 = -16'sd16069;
	parameter signed [COEF_W - 1:0] C16 = -16'sd15137;
	parameter signed [COEF_W - 1:0] C17 = -16'sd9102;
	parameter signed [COEF_W - 1:0] C20 = 16'sd16384;
	parameter signed [COEF_W - 1:0] C21 = 16'sd9102;
	parameter signed [COEF_W - 1:0] C22 = -16'sd6270;
	parameter signed [COEF_W - 1:0] C23 = -16'sd16069;
	parameter signed [COEF_W - 1:0] C24 = -16'sd11585;
	parameter signed [COEF_W - 1:0] C25 = 16'sd3196;
	parameter signed [COEF_W - 1:0] C26 = 16'sd15137;
	parameter signed [COEF_W - 1:0] C27 = 16'sd13623;
	parameter signed [COEF_W - 1:0] C30 = 16'sd16384;
	parameter signed [COEF_W - 1:0] C31 = 16'sd3196;
	parameter signed [COEF_W - 1:0] C32 = -16'sd15137;
	parameter signed [COEF_W - 1:0] C33 = -16'sd9102;
	parameter signed [COEF_W - 1:0] C34 = 16'sd11585;
	parameter signed [COEF_W - 1:0] C35 = 16'sd13623;
	parameter signed [COEF_W - 1:0] C36 = -16'sd6270;
	parameter signed [COEF_W - 1:0] C37 = -16'sd16069;
	parameter signed [COEF_W - 1:0] C40 = 16'sd16384;
	parameter signed [COEF_W - 1:0] C41 = -16'sd3196;
	parameter signed [COEF_W - 1:0] C42 = -16'sd15137;
	parameter signed [COEF_W - 1:0] C43 = 16'sd9102;
	parameter signed [COEF_W - 1:0] C44 = 16'sd11585;
	parameter signed [COEF_W - 1:0] C45 = -16'sd13623;
	parameter signed [COEF_W - 1:0] C46 = -16'sd6270;
	parameter signed [COEF_W - 1:0] C47 = 16'sd16069;
	parameter signed [COEF_W - 1:0] C50 = 16'sd16384;
	parameter signed [COEF_W - 1:0] C51 = -16'sd9102;
	parameter signed [COEF_W - 1:0] C52 = -16'sd6270;
	parameter signed [COEF_W - 1:0] C53 = 16'sd16069;
	parameter signed [COEF_W - 1:0] C54 = -16'sd11585;
	parameter signed [COEF_W - 1:0] C55 = -16'sd3196;
	parameter signed [COEF_W - 1:0] C56 = 16'sd15137;
	parameter signed [COEF_W - 1:0] C57 = -16'sd13623;
	parameter signed [COEF_W - 1:0] C60 = 16'sd16384;
	parameter signed [COEF_W - 1:0] C61 = -16'sd13623;
	parameter signed [COEF_W - 1:0] C62 = 16'sd6270;
	parameter signed [COEF_W - 1:0] C63 = 16'sd3196;
	parameter signed [COEF_W - 1:0] C64 = -16'sd11585;
	parameter signed [COEF_W - 1:0] C65 = 16'sd16069;
	parameter signed [COEF_W - 1:0] C66 = -16'sd15137;
	parameter signed [COEF_W - 1:0] C67 = 16'sd9102;
	parameter signed [COEF_W - 1:0] C70 = 16'sd16384;
	parameter signed [COEF_W - 1:0] C71 = -16'sd16069;
	parameter signed [COEF_W - 1:0] C72 = 16'sd15137;
	parameter signed [COEF_W - 1:0] C73 = -16'sd13623;
	parameter signed [COEF_W - 1:0] C74 = 16'sd11585;
	parameter signed [COEF_W - 1:0] C75 = -16'sd9102;
	parameter signed [COEF_W - 1:0] C76 = 16'sd6270;
	parameter signed [COEF_W - 1:0] C77 = -16'sd3196;
	input wire CLK, RST, ED, in_valid;
	input wire [2:0] in_tag;
	output wire out_valid;
	output wire [2:0] out_tag;
	input signed [DATA_W - 1:0] x0;
	input signed [DATA_W - 1:0] x1;
	input signed [DATA_W - 1:0] x2;
	input signed [DATA_W - 1:0] x3;
	input signed [DATA_W - 1:0] x4;
	input signed [DATA_W - 1:0] x5;
	input signed [DATA_W - 1:0] x6;
	input signed [DATA_W - 1:0] x7;
	output wire signed [OUT_W - 1:0] y0;
	output wire signed [OUT_W - 1:0] y1;
	output wire signed [OUT_W - 1:0] y2;
	output wire signed [OUT_W - 1:0] y3;
	output wire signed [OUT_W - 1:0] y4;
	output wire signed [OUT_W - 1:0] y5;
	output wire signed [OUT_W - 1:0] y6;
	output wire signed [OUT_W - 1:0] y7;
	input signed [(64 * COEF_W) - 1:0] c_in;
	localparam signed [ACC_W - 1:0] ROUND_BIAS = (COEF_FRAC == 0 ? {ACC_W {1'b0}} : {{ACC_W - 1 {1'b0}}, 1'b1} <<< (COEF_FRAC - 1));
	wire signed [COEF_W - 1:0] K00 = (USE_COEFF_PORT ? c_in[63 * COEF_W+:COEF_W] : C00);
	wire signed [COEF_W - 1:0] K01 = (USE_COEFF_PORT ? c_in[62 * COEF_W+:COEF_W] : C01);
	wire signed [COEF_W - 1:0] K02 = (USE_COEFF_PORT ? c_in[61 * COEF_W+:COEF_W] : C02);
	wire signed [COEF_W - 1:0] K03 = (USE_COEFF_PORT ? c_in[60 * COEF_W+:COEF_W] : C03);
	wire signed [COEF_W - 1:0] K04 = (USE_COEFF_PORT ? c_in[59 * COEF_W+:COEF_W] : C04);
	wire signed [COEF_W - 1:0] K05 = (USE_COEFF_PORT ? c_in[58 * COEF_W+:COEF_W] : C05);
	wire signed [COEF_W - 1:0] K06 = (USE_COEFF_PORT ? c_in[57 * COEF_W+:COEF_W] : C06);
	wire signed [COEF_W - 1:0] K07 = (USE_COEFF_PORT ? c_in[56 * COEF_W+:COEF_W] : C07);
	wire signed [COEF_W - 1:0] K10 = (USE_COEFF_PORT ? c_in[55 * COEF_W+:COEF_W] : C10);
	wire signed [COEF_W - 1:0] K11 = (USE_COEFF_PORT ? c_in[54 * COEF_W+:COEF_W] : C11);
	wire signed [COEF_W - 1:0] K12 = (USE_COEFF_PORT ? c_in[53 * COEF_W+:COEF_W] : C12);
	wire signed [COEF_W - 1:0] K13 = (USE_COEFF_PORT ? c_in[52 * COEF_W+:COEF_W] : C13);
	wire signed [COEF_W - 1:0] K14 = (USE_COEFF_PORT ? c_in[51 * COEF_W+:COEF_W] : C14);
	wire signed [COEF_W - 1:0] K15 = (USE_COEFF_PORT ? c_in[50 * COEF_W+:COEF_W] : C15);
	wire signed [COEF_W - 1:0] K16 = (USE_COEFF_PORT ? c_in[49 * COEF_W+:COEF_W] : C16);
	wire signed [COEF_W - 1:0] K17 = (USE_COEFF_PORT ? c_in[48 * COEF_W+:COEF_W] : C17);
	wire signed [COEF_W - 1:0] K20 = (USE_COEFF_PORT ? c_in[47 * COEF_W+:COEF_W] : C20);
	wire signed [COEF_W - 1:0] K21 = (USE_COEFF_PORT ? c_in[46 * COEF_W+:COEF_W] : C21);
	wire signed [COEF_W - 1:0] K22 = (USE_COEFF_PORT ? c_in[45 * COEF_W+:COEF_W] : C22);
	wire signed [COEF_W - 1:0] K23 = (USE_COEFF_PORT ? c_in[44 * COEF_W+:COEF_W] : C23);
	wire signed [COEF_W - 1:0] K24 = (USE_COEFF_PORT ? c_in[43 * COEF_W+:COEF_W] : C24);
	wire signed [COEF_W - 1:0] K25 = (USE_COEFF_PORT ? c_in[42 * COEF_W+:COEF_W] : C25);
	wire signed [COEF_W - 1:0] K26 = (USE_COEFF_PORT ? c_in[41 * COEF_W+:COEF_W] : C26);
	wire signed [COEF_W - 1:0] K27 = (USE_COEFF_PORT ? c_in[40 * COEF_W+:COEF_W] : C27);
	wire signed [COEF_W - 1:0] K30 = (USE_COEFF_PORT ? c_in[39 * COEF_W+:COEF_W] : C30);
	wire signed [COEF_W - 1:0] K31 = (USE_COEFF_PORT ? c_in[38 * COEF_W+:COEF_W] : C31);
	wire signed [COEF_W - 1:0] K32 = (USE_COEFF_PORT ? c_in[37 * COEF_W+:COEF_W] : C32);
	wire signed [COEF_W - 1:0] K33 = (USE_COEFF_PORT ? c_in[36 * COEF_W+:COEF_W] : C33);
	wire signed [COEF_W - 1:0] K34 = (USE_COEFF_PORT ? c_in[35 * COEF_W+:COEF_W] : C34);
	wire signed [COEF_W - 1:0] K35 = (USE_COEFF_PORT ? c_in[34 * COEF_W+:COEF_W] : C35);
	wire signed [COEF_W - 1:0] K36 = (USE_COEFF_PORT ? c_in[33 * COEF_W+:COEF_W] : C36);
	wire signed [COEF_W - 1:0] K37 = (USE_COEFF_PORT ? c_in[32 * COEF_W+:COEF_W] : C37);
	wire signed [COEF_W - 1:0] K40 = (USE_COEFF_PORT ? c_in[31 * COEF_W+:COEF_W] : C40);
	wire signed [COEF_W - 1:0] K41 = (USE_COEFF_PORT ? c_in[30 * COEF_W+:COEF_W] : C41);
	wire signed [COEF_W - 1:0] K42 = (USE_COEFF_PORT ? c_in[29 * COEF_W+:COEF_W] : C42);
	wire signed [COEF_W - 1:0] K43 = (USE_COEFF_PORT ? c_in[28 * COEF_W+:COEF_W] : C43);
	wire signed [COEF_W - 1:0] K44 = (USE_COEFF_PORT ? c_in[27 * COEF_W+:COEF_W] : C44);
	wire signed [COEF_W - 1:0] K45 = (USE_COEFF_PORT ? c_in[26 * COEF_W+:COEF_W] : C45);
	wire signed [COEF_W - 1:0] K46 = (USE_COEFF_PORT ? c_in[25 * COEF_W+:COEF_W] : C46);
	wire signed [COEF_W - 1:0] K47 = (USE_COEFF_PORT ? c_in[24 * COEF_W+:COEF_W] : C47);
	wire signed [COEF_W - 1:0] K50 = (USE_COEFF_PORT ? c_in[23 * COEF_W+:COEF_W] : C50);
	wire signed [COEF_W - 1:0] K51 = (USE_COEFF_PORT ? c_in[22 * COEF_W+:COEF_W] : C51);
	wire signed [COEF_W - 1:0] K52 = (USE_COEFF_PORT ? c_in[21 * COEF_W+:COEF_W] : C52);
	wire signed [COEF_W - 1:0] K53 = (USE_COEFF_PORT ? c_in[20 * COEF_W+:COEF_W] : C53);
	wire signed [COEF_W - 1:0] K54 = (USE_COEFF_PORT ? c_in[19 * COEF_W+:COEF_W] : C54);
	wire signed [COEF_W - 1:0] K55 = (USE_COEFF_PORT ? c_in[18 * COEF_W+:COEF_W] : C55);
	wire signed [COEF_W - 1:0] K56 = (USE_COEFF_PORT ? c_in[17 * COEF_W+:COEF_W] : C56);
	wire signed [COEF_W - 1:0] K57 = (USE_COEFF_PORT ? c_in[16 * COEF_W+:COEF_W] : C57);
	wire signed [COEF_W - 1:0] K60 = (USE_COEFF_PORT ? c_in[15 * COEF_W+:COEF_W] : C60);
	wire signed [COEF_W - 1:0] K61 = (USE_COEFF_PORT ? c_in[14 * COEF_W+:COEF_W] : C61);
	wire signed [COEF_W - 1:0] K62 = (USE_COEFF_PORT ? c_in[13 * COEF_W+:COEF_W] : C62);
	wire signed [COEF_W - 1:0] K63 = (USE_COEFF_PORT ? c_in[12 * COEF_W+:COEF_W] : C63);
	wire signed [COEF_W - 1:0] K64 = (USE_COEFF_PORT ? c_in[11 * COEF_W+:COEF_W] : C64);
	wire signed [COEF_W - 1:0] K65 = (USE_COEFF_PORT ? c_in[10 * COEF_W+:COEF_W] : C65);
	wire signed [COEF_W - 1:0] K66 = (USE_COEFF_PORT ? c_in[9 * COEF_W+:COEF_W] : C66);
	wire signed [COEF_W - 1:0] K67 = (USE_COEFF_PORT ? c_in[8 * COEF_W+:COEF_W] : C67);
	wire signed [COEF_W - 1:0] K70 = (USE_COEFF_PORT ? c_in[7 * COEF_W+:COEF_W] : C70);
	wire signed [COEF_W - 1:0] K71 = (USE_COEFF_PORT ? c_in[6 * COEF_W+:COEF_W] : C71);
	wire signed [COEF_W - 1:0] K72 = (USE_COEFF_PORT ? c_in[5 * COEF_W+:COEF_W] : C72);
	wire signed [COEF_W - 1:0] K73 = (USE_COEFF_PORT ? c_in[4 * COEF_W+:COEF_W] : C73);
	wire signed [COEF_W - 1:0] K74 = (USE_COEFF_PORT ? c_in[3 * COEF_W+:COEF_W] : C74);
	wire signed [COEF_W - 1:0] K75 = (USE_COEFF_PORT ? c_in[2 * COEF_W+:COEF_W] : C75);
	wire signed [COEF_W - 1:0] K76 = (USE_COEFF_PORT ? c_in[COEF_W+:COEF_W] : C76);
	wire signed [COEF_W - 1:0] K77 = (USE_COEFF_PORT ? c_in[0+:COEF_W] : C77);

    localparam integer PRODUCT_W = DATA_W + COEF_W;
    localparam integer PIPE_STAGES = 6;
    localparam signed [ACC_W-1:0] NEG_ROUND_BIAS = ROUND_BIAS - 1'b1;
    wire signed [DATA_W-1:0] x_in [0:7];
    wire signed [COEF_W-1:0] coeff_in [0:63];
    reg signed [DATA_W-1:0] x_q [0:7];
    reg signed [COEF_W-1:0] coeff_q [0:63];
    reg signed [PRODUCT_W-1:0] product_q [0:63];
    reg signed [ACC_W-1:0] pair_q [0:31];
    reg signed [ACC_W-1:0] quad_q [0:15];
    reg signed [ACC_W-1:0] sum_q [0:7];
    reg signed [ACC_W-1:0] round_q [0:7];
    reg [PIPE_STAGES-1:0] valid_q;
    reg [2:0] tag_q [0:PIPE_STAGES-1];
    integer i;
    function signed [ACC_W-1:0] extend_product;
        input signed [PRODUCT_W-1:0] value;
        begin extend_product = value; end
    endfunction
    assign x_in[0] = x0;
    assign x_in[1] = x1;
    assign x_in[2] = x2;
    assign x_in[3] = x3;
    assign x_in[4] = x4;
    assign x_in[5] = x5;
    assign x_in[6] = x6;
    assign x_in[7] = x7;
    assign coeff_in[0] = K00;
    assign coeff_in[1] = K01;
    assign coeff_in[2] = K02;
    assign coeff_in[3] = K03;
    assign coeff_in[4] = K04;
    assign coeff_in[5] = K05;
    assign coeff_in[6] = K06;
    assign coeff_in[7] = K07;
    assign coeff_in[8] = K10;
    assign coeff_in[9] = K11;
    assign coeff_in[10] = K12;
    assign coeff_in[11] = K13;
    assign coeff_in[12] = K14;
    assign coeff_in[13] = K15;
    assign coeff_in[14] = K16;
    assign coeff_in[15] = K17;
    assign coeff_in[16] = K20;
    assign coeff_in[17] = K21;
    assign coeff_in[18] = K22;
    assign coeff_in[19] = K23;
    assign coeff_in[20] = K24;
    assign coeff_in[21] = K25;
    assign coeff_in[22] = K26;
    assign coeff_in[23] = K27;
    assign coeff_in[24] = K30;
    assign coeff_in[25] = K31;
    assign coeff_in[26] = K32;
    assign coeff_in[27] = K33;
    assign coeff_in[28] = K34;
    assign coeff_in[29] = K35;
    assign coeff_in[30] = K36;
    assign coeff_in[31] = K37;
    assign coeff_in[32] = K40;
    assign coeff_in[33] = K41;
    assign coeff_in[34] = K42;
    assign coeff_in[35] = K43;
    assign coeff_in[36] = K44;
    assign coeff_in[37] = K45;
    assign coeff_in[38] = K46;
    assign coeff_in[39] = K47;
    assign coeff_in[40] = K50;
    assign coeff_in[41] = K51;
    assign coeff_in[42] = K52;
    assign coeff_in[43] = K53;
    assign coeff_in[44] = K54;
    assign coeff_in[45] = K55;
    assign coeff_in[46] = K56;
    assign coeff_in[47] = K57;
    assign coeff_in[48] = K60;
    assign coeff_in[49] = K61;
    assign coeff_in[50] = K62;
    assign coeff_in[51] = K63;
    assign coeff_in[52] = K64;
    assign coeff_in[53] = K65;
    assign coeff_in[54] = K66;
    assign coeff_in[55] = K67;
    assign coeff_in[56] = K70;
    assign coeff_in[57] = K71;
    assign coeff_in[58] = K72;
    assign coeff_in[59] = K73;
    assign coeff_in[60] = K74;
    assign coeff_in[61] = K75;
    assign coeff_in[62] = K76;
    assign coeff_in[63] = K77;
    assign y0 = round_q[0] >>> COEF_FRAC;
    assign y1 = round_q[1] >>> COEF_FRAC;
    assign y2 = round_q[2] >>> COEF_FRAC;
    assign y3 = round_q[3] >>> COEF_FRAC;
    assign y4 = round_q[4] >>> COEF_FRAC;
    assign y5 = round_q[5] >>> COEF_FRAC;
    assign y6 = round_q[6] >>> COEF_FRAC;
    assign y7 = round_q[7] >>> COEF_FRAC;
    assign out_valid = valid_q[PIPE_STAGES-1];
    assign out_tag = tag_q[PIPE_STAGES-1];

    // Only valid/tag need reset. Uninitialized datapath words are never consumed
    // until their matching valid reaches the output. Avoid resetting DSP data.
    always @(posedge CLK) begin
        if (RST) begin
            valid_q <= 0;
            for (i=0; i<PIPE_STAGES; i=i+1) tag_q[i] <= 0;
        end else if (ED) begin
            valid_q <= {valid_q[PIPE_STAGES-2:0], in_valid};
            tag_q[0] <= in_tag;
            for (i=1; i<PIPE_STAGES; i=i+1) tag_q[i] <= tag_q[i-1];
            // Stage 0: isolate bank selection and coefficient ROM from multiply.
            if (in_valid) begin
                for (i=0; i<8; i=i+1) x_q[i] <= x_in[i];
                for (i=0; i<64; i=i+1) coeff_q[i] <= coeff_in[i];
            end
            // Stage 1: all 64 full signed products, with no following add here.
            if (valid_q[0])
                for (i=0; i<64; i=i+1)
                    product_q[i] <= x_q[i%8] * coeff_q[i];
            // Stages 2/3/4: balanced reduction, retaining ACC_W arithmetic.
            if (valid_q[1])
                for (i=0; i<32; i=i+1)
                    pair_q[i] <= extend_product(product_q[2*i]) + extend_product(product_q[2*i+1]);
            if (valid_q[2])
                for (i=0; i<16; i=i+1) quad_q[i] <= pair_q[2*i] + pair_q[2*i+1];
            if (valid_q[3])
                for (i=0; i<8; i=i+1) sum_q[i] <= quad_q[2*i] + quad_q[2*i+1];
            // Stage 5: preserve the original sign-dependent rounding bias.
            if (valid_q[4])
                for (i=0; i<8; i=i+1) begin
                    if (COEF_FRAC == 0) round_q[i] <= sum_q[i];
                    else round_q[i] <= sum_q[i] + (sum_q[i][ACC_W-1] ? NEG_ROUND_BIAS : ROUND_BIAS);
                end
        end
    end
endmodule
