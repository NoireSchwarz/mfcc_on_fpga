`timescale 1ns/1ps
// Modes 0/1: full coefficient matrix, six stages. Mode 2: c_in[2:0] is BLOCK, thirteen recursive stages.
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
	// Recursive mode consumes only the family ID; generic modes retain all 64 coefficients.
	input signed [((USE_COEFF_PORT == 2) ? 3 : (64 * COEF_W)) - 1:0] c_in;
    // USE_COEFF_PORT=2 selects the structured project-family implementation.
    // c_in is now the 3-bit BLOCK ID in mode 2. Generic modes 0/1 retain their original interface.
    generate if(USE_COEFF_PORT==2) begin:gen_recursive
        wire signed [8*OUT_W-1:0] values;
        skewdct8_recursive_pipe #(.DATA_W(DATA_W),.OUT_W(OUT_W)) recursive_i(
            .CLK(CLK),.RST(RST),.ED(ED),.in_valid(in_valid),.in_tag(in_tag),.out_valid(out_valid),.out_tag(out_tag),
            .X({x0,x1,x2,x3,x4,x5,x6,x7}),.BLOCK(c_in[2:0]),.Y(values));
        assign y0=values[7*OUT_W+:OUT_W];
        assign y1=values[6*OUT_W+:OUT_W];
        assign y2=values[5*OUT_W+:OUT_W];
        assign y3=values[4*OUT_W+:OUT_W];
        assign y4=values[3*OUT_W+:OUT_W];
        assign y5=values[2*OUT_W+:OUT_W];
        assign y6=values[1*OUT_W+:OUT_W];
        assign y7=values[0*OUT_W+:OUT_W];
    end else begin:gen_dense
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
    end endgenerate
endmodule

// Recursive SkewDCT-II: BLOCK directly selects one of the eight fixed factor families.
// No matrix coefficient bus, matrix ROM, or signature decoder is required.
// Puschel, ICASSP 2003, eqs. (25)-(27): n=8 -> 4 -> 2, k=2.
// Arithmetic: 12 real multiplications and 29 transform add/sub operations.
// Fixed-point implementation adds registered rounding; there is no multiply-add
// combinational stage. II=1 enabled edge; 13 enabled register stages.
module skewdct8_recursive_pipe #(
    parameter integer DATA_W=16, OUT_W=24
)(
    input CLK, RST, ED, in_valid,
    input [2:0] in_tag,
    output out_valid,
    output [2:0] out_tag,
    input signed [8*DATA_W-1:0] X,
    input [2:0] BLOCK,
    output signed [8*OUT_W-1:0] Y
);
    localparam integer GUARD_FRAC=8;
    localparam integer IW=DATA_W+16; // eight fractional + eight integer guard bits
    localparam integer FW=27, FF=21, PW=IW+FW, STAGES=13;
    localparam signed [PW-1:0] P_HALF={{PW-1{1'b0}},1'b1} <<< (FF-1);
    localparam signed [IW-1:0] Y_HALF={{IW-1{1'b0}},1'b1} <<< (GUARD_FRAC-1);
    reg [STAGES-1:0] valid_q;
    reg [2:0] tag_q[0:STAGES-1], block_q[0:STAGES-1];
    reg signed [IW-1:0] x_q[0:7];
    reg signed [IW-1:0] leaf_sum[0:3],leaf_diff[0:3],leaf_sum_d[0:3];
    reg signed [FW-1:0] leaf_factor[0:3];
    reg signed [PW-1:0] leaf_product[0:3];
    reg signed [IW-1:0] leaf_result[0:7];
    reg signed [IW-1:0] mid_sum[0:3],mid_diff[0:3],mid_sum_d[0:3],mid_sum_r[0:3],mid_scaled[0:3];
    reg signed [FW-1:0] mid_factor[0:1];
    reg signed [PW-1:0] mid_product[0:3];
    reg signed [IW-1:0] mid_result[0:7];
    reg signed [IW-1:0] root_sum[0:3],root_diff[0:3],root_sum_d[0:3],root_sum_r[0:3],root_scaled[0:3];
    reg signed [FW-1:0] root_factor;
    reg signed [PW-1:0] root_product[0:3];
    reg signed [IW-1:0] result_q[0:7],rounded_q[0:7];
    integer i;

    function signed [FW-1:0] factor;
        input [2:0] block_id,which;
        begin
            case({which,block_id})
                6'd0: factor = 27'sd1048892;
                6'd1: factor = 27'sd1051425;
                6'd2: factor = 27'sd1056522;
                6'd3: factor = 27'sd1064244;
                6'd4: factor = 27'sd1074689;
                6'd5: factor = 27'sd1087987;
                6'd6: factor = 27'sd1104313;
                6'd7: factor = 27'sd1123884;
                6'd8: factor = 27'sd42727119;
                6'd9: factor = 27'sd14253819;
                6'd10: factor = 27'sd8566050;
                6'd11: factor = 27'sd6133390;
                6'd12: factor = 27'sd4785806;
                6'd13: factor = 27'sd3931480;
                6'd14: factor = 27'sd3342802;
                6'd15: factor = 27'sd2913561;
                6'd16: factor = 27'sd1447815;
                6'd17: factor = 27'sd1384791;
                6'd18: factor = 27'sd1330095;
                6'd19: factor = 27'sd1282529;
                6'd20: factor = 27'sd1241133;
                6'd21: factor = 27'sd1205139;
                6'd22: factor = 27'sd1173922;
                6'd23: factor = 27'sd1146975;
                6'd24: factor = 27'sd1520688;
                6'd25: factor = 27'sd1605358;
                6'd26: factor = 27'sd1704360;
                6'd27: factor = 27'sd1821051;
                6'd28: factor = 27'sd1959964;
                6'd29: factor = 27'sd2127368;
                6'd30: factor = 27'sd2332183;
                6'd31: factor = 27'sd2587535;
                6'd32: factor = 27'sd1049841;
                6'd33: factor = 27'sd1060049;
                6'd34: factor = 27'sd1080971;
                6'd35: factor = 27'sd1113677;
                6'd36: factor = 27'sd1159943;
                6'd37: factor = 27'sd1222503;
                6'd38: factor = 27'sd1305486;
                6'd39: factor = 27'sd1415176;
                6'd40: factor = 27'sd21369996;
                6'd41: factor = 27'sd7146273;
                6'd42: factor = 27'sd4315480;
                6'd43: factor = 27'sd3112519;
                6'd44: factor = 27'sd2452493;
                6'd45: factor = 27'sd2039623;
                6'd46: factor = 27'sd1760244;
                6'd47: factor = 27'sd1561406;
                6'd48: factor = 27'sd1053650;
                6'd49: factor = 27'sd1095759;
                6'd50: factor = 27'sd1188968;
                6'd51: factor = 27'sd1356484;
                6'd52: factor = 27'sd1652880;
                6'd53: factor = 27'sd2224402;
                6'd54: factor = 27'sd3612233;
                6'd55: factor = 27'sd10697884;
                default: factor=27'sd0;
            endcase
        end
    endfunction
    function signed [IW-1:0] lift;
        input signed [DATA_W-1:0] value;
        reg signed [IW-1:0] extended;
        begin extended=value; lift=extended <<< GUARD_FRAC; end
    endfunction
    function signed [IW-1:0] round_product;
        input signed [PW-1:0] value;
        reg signed [PW-1:0] biased;
        begin
            biased=value+(value[PW-1] ? P_HALF-1'b1 : P_HALF);
            round_product=biased >>> FF;
        end
    endfunction

    assign out_valid=valid_q[STAGES-1];
    assign out_tag=tag_q[STAGES-1];
    genvar g;
    generate for(g=0;g<8;g=g+1) begin:OUTPUTS
        assign Y[(7-g)*OUT_W+:OUT_W]=rounded_q[g] >>> GUARD_FRAC;
    end endgenerate

    always @(posedge CLK) begin
        if(RST) begin
            valid_q<=0;
            for(i=0;i<STAGES;i=i+1) begin tag_q[i]<=0;block_q[i]<=0;end
        end else if(ED) begin
            valid_q<={valid_q[STAGES-2:0],in_valid};
            tag_q[0]<=in_tag;
            block_q[0]<=BLOCK;
            for(i=1;i<STAGES;i=i+1) begin tag_q[i]<=tag_q[i-1];block_q[i]<=block_q[i-1];end
            // S0: input capture, fraction extension and direct family-ID capture.
            if(in_valid)
                for(i=0;i<8;i=i+1) x_q[i]<=lift(X[(7-i)*DATA_W+:DATA_W]);
            // S1: four two-point butterflies; coefficient selection is parallel.
            if(valid_q[0]) begin
                leaf_sum[0]<=x_q[0]+x_q[7];leaf_diff[0]<=x_q[0]-x_q[7];
                leaf_sum[1]<=x_q[3]+x_q[4];leaf_diff[1]<=x_q[3]-x_q[4];
                leaf_sum[2]<=x_q[1]+x_q[6];leaf_diff[2]<=x_q[1]-x_q[6];
                leaf_sum[3]<=x_q[2]+x_q[5];leaf_diff[3]<=x_q[2]-x_q[5];
                for(i=0;i<4;i=i+1) leaf_factor[i]<=factor(block_q[0],i);
            end
            // S2: leaf products only; sums follow an equal-length delay.
            if(valid_q[1])
                for(i=0;i<4;i=i+1) begin
                    leaf_product[i]<=leaf_diff[i]*leaf_factor[i];leaf_sum_d[i]<=leaf_sum[i];
                end
            // S3: registered product rounding, with eight fractional guard bits.
            if(valid_q[2])
                for(i=0;i<4;i=i+1) begin
                    leaf_result[2*i]<=leaf_sum_d[i];leaf_result[2*i+1]<=round_product(leaf_product[i]);
                end
            // S4: the two four-point transforms' sum/difference stage.
            if(valid_q[3]) begin
                for(i=0;i<4;i=i+1) begin
                    mid_sum[i]<=leaf_result[4*(i/2)+(i%2)]+leaf_result[4*(i/2)+2+(i%2)];
                    mid_diff[i]<=leaf_result[4*(i/2)+(i%2)]-leaf_result[4*(i/2)+2+(i%2)];
                end
                mid_factor[0]<=factor(block_q[3],3'd4);mid_factor[1]<=factor(block_q[3],3'd5);
            end
            // S5: four midpoint products, with no following accumulation.
            if(valid_q[4])
                for(i=0;i<4;i=i+1) begin
                    mid_product[i]<=mid_diff[i]*mid_factor[i/2];mid_sum_d[i]<=mid_sum[i];
                end
            // S6: midpoint product rounding.
            if(valid_q[5])
                for(i=0;i<4;i=i+1) begin mid_scaled[i]<=round_product(mid_product[i]);mid_sum_r[i]<=mid_sum_d[i];end
            // S7: C4 sparse post-add, exactly one adder per affected output.
            if(valid_q[6]) begin
                mid_result[0]<=mid_sum_r[0];mid_result[1]<=mid_sum_r[1]+mid_scaled[1];
                mid_result[2]<=mid_scaled[0];mid_result[3]<=mid_scaled[1];
                mid_result[4]<=mid_sum_r[2];mid_result[5]<=mid_sum_r[3]+mid_scaled[3];
                mid_result[6]<=mid_scaled[2];mid_result[7]<=mid_scaled[3];
            end
            // S8: top-level butterflies, plus separately registered root factor.
            if(valid_q[7]) begin
                for(i=0;i<4;i=i+1) begin root_sum[i]<=mid_result[i]+mid_result[i+4];root_diff[i]<=mid_result[i]-mid_result[i+4];end
                root_factor<=factor(block_q[7],3'd6);
            end
            // S9: four top-level products only.
            if(valid_q[8])
                for(i=0;i<4;i=i+1) begin root_product[i]<=root_diff[i]*root_factor;root_sum_d[i]<=root_sum[i];end
            // S10: root product rounding.
            if(valid_q[9])
                for(i=0;i<4;i=i+1) begin root_scaled[i]<=round_product(root_product[i]);root_sum_r[i]<=root_sum_d[i];end
            // S11: C8 sparse post-add; no serial post-add cascade.
            if(valid_q[10]) begin
                result_q[0]<=root_sum_r[0];result_q[1]<=root_sum_r[1]+root_scaled[3];
                result_q[2]<=root_sum_r[2]+root_scaled[2];result_q[3]<=root_sum_r[3]+root_scaled[1];
                for(i=0;i<4;i=i+1) result_q[i+4]<=root_scaled[i];
            end
            // S12: final sign-dependent round-to-nearest, ties away from zero.
            if(valid_q[11])
                for(i=0;i<8;i=i+1) rounded_q[i]<=result_q[i]+(result_q[i][IW-1] ? Y_HALF-1'b1 : Y_HALF);
        end
    end
    // All eight BLOCK values are valid. Tags remain independent transaction metadata.
    // synthesis translate_off
    always @(posedge CLK)
        if(!RST && ED && in_valid && ((^BLOCK) === 1'bx))
            $fatal(1,"recursive SkewDCT8 received an unknown BLOCK family ID");
    // synthesis translate_on
endmodule
