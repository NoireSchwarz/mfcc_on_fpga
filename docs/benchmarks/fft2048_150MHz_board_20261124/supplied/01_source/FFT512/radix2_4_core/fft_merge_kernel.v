`timescale 1ns/1ps
// Registered shared complex products, butterflies and saturation.
// Public ports, arithmetic widths and twiddle shift match the frozen baseline.
module fft_merge_kernel (
	clk,
	rst,
	start,
	mode,
	x0_re,
	x0_im,
	x1_re,
	x1_im,
	x2_re,
	x2_im,
	x3_re,
	x3_im,
	w1_re,
	w1_im,
	w2_re,
	w2_im,
	w3_re,
	w3_im,
	valid,
	busy,
	y0_re,
	y0_im,
	y1_re,
	y1_im,
	y2_re,
	y2_im,
	y3_re,
	y3_im
);
	parameter signed [31:0] NB = 16;
	parameter signed [31:0] TW = 16;
	input wire clk;
	input wire rst;
	input wire start;
	input wire [1:0] mode;
	input wire signed [NB - 1:0] x0_re;
	input wire signed [NB - 1:0] x0_im;
	input wire signed [NB - 1:0] x1_re;
	input wire signed [NB - 1:0] x1_im;
	input wire signed [NB - 1:0] x2_re;
	input wire signed [NB - 1:0] x2_im;
	input wire signed [NB - 1:0] x3_re;
	input wire signed [NB - 1:0] x3_im;
	input wire signed [TW - 1:0] w1_re;
	input wire signed [TW - 1:0] w1_im;
	input wire signed [TW - 1:0] w2_re;
	input wire signed [TW - 1:0] w2_im;
	input wire signed [TW - 1:0] w3_re;
	input wire signed [TW - 1:0] w3_im;
	output reg valid;
	output reg busy;
	output reg signed [NB - 1:0] y0_re;
	output reg signed [NB - 1:0] y0_im;
	output reg signed [NB - 1:0] y1_re;
	output reg signed [NB - 1:0] y1_im;
	output reg signed [NB - 1:0] y2_re;
	output reg signed [NB - 1:0] y2_im;
	output reg signed [NB - 1:0] y3_re;
	output reg signed [NB - 1:0] y3_im;
    localparam [1:0] MODE_ROT_ONLY=2'd0, MODE_RADIX2=2'd1, MODE_RADIX4=2'd2;
    localparam [3:0] IDLE=0, PRODUCT1=1, ROTATE1=2, ROTATE2=3,
        ROTATE3=4, BUTTERFLY_R2=5, SAT_ROT=6,
        R4_PARTIAL=7, R4_COMBINE=8, SAT_OUTPUT=9;
    localparam integer MW=NB+TW;
    localparam integer EXTW=(64>MW)?64:MW;
    reg [3:0] state;
    reg [1:0] mode_q;
    reg signed [NB-1:0] b0_re,b0_im,mul_x_re,mul_x_im;
    reg signed [TW-1:0] mul_w_re,mul_w_im;
    reg signed [MW-1:0] product_rr,product_ii,product_ri,product_ir;
    reg signed [63:0] b1_re,b1_im,b2_re,b2_im,b3_re,b3_im;
    reg signed [63:0] partial0_re,partial0_im,partial1_re,partial1_im;
    reg signed [63:0] partial2_re,partial2_im,partial3_re,partial3_im;
    reg signed [63:0] sum0_re,sum0_im,sum1_re,sum1_im;
    reg signed [63:0] sum2_re,sum2_im,sum3_re,sum3_im;
    // Mode 3 follows the old kernel's radix-4 fallback as well.
    wire radix4_mode=(mode_q!=MODE_ROT_ONLY)&&(mode_q!=MODE_RADIX2);
    wire product_enable=(state==PRODUCT1) ||
        (radix4_mode && ((state==ROTATE1)||(state==ROTATE2)));
    wire signed [EXTW-1:0] rr_ext={{EXTW-MW{product_rr[MW-1]}},product_rr};
    wire signed [EXTW-1:0] ii_ext={{EXTW-MW{product_ii[MW-1]}},product_ii};
    wire signed [EXTW-1:0] ri_ext={{EXTW-MW{product_ri[MW-1]}},product_ri};
    wire signed [EXTW-1:0] ir_ext={{EXTW-MW{product_ir[MW-1]}},product_ir};
    // Keep SHIFT_AFTER_SUM=1 exactly: add/subtract before the arithmetic shift.
    wire signed [63:0] rotation_re=(rr_ext-ii_ext) >>> (TW-1);
    wire signed [63:0] rotation_im=(ri_ext+ir_ext) >>> (TW-1);
    wire signed [63:0] b0_re_ext={{64-NB{b0_re[NB-1]}},b0_re};
    wire signed [63:0] b0_im_ext={{64-NB{b0_im[NB-1]}},b0_im};

    function automatic signed [NB-1:0] sat_nb;
        input reg signed [63:0] value;
        reg signed [63:0] max_value,min_value;
        begin
            max_value=(64'sd1 <<< (NB-1))-64'sd1;
            min_value=-(64'sd1 <<< (NB-1));
            if(value>max_value) sat_nb={1'b0,{NB-1{1'b1}}};
            else if(value<min_value) sat_nb={1'b1,{NB-1{1'b0}}};
            else sat_nb=value[NB-1:0];
        end
    endfunction

    always @(posedge clk) begin
        if(rst) begin
            state<=IDLE;valid<=0;busy<=0;mode_q<=MODE_ROT_ONLY;
            b0_re<=0;b0_im<=0;mul_x_re<=0;mul_x_im<=0;mul_w_re<=0;mul_w_im<=0;
            b1_re<=0;b1_im<=0;b2_re<=0;b2_im<=0;b3_re<=0;b3_im<=0;
            y0_re<=0;y0_im<=0;y1_re<=0;y1_im<=0;
            y2_re<=0;y2_im<=0;y3_re<=0;y3_im<=0;
            // Temporary datapath registers need no reset: the reset state
            // discards the transaction and every used value is overwritten.
        end else begin
            valid<=0;
            // Four shared real multipliers, isolated from rotation addition.
            // For radix-4 they accept rotations 1/2/3 on consecutive clocks.
            if(product_enable) begin
                product_rr<=mul_x_re*mul_w_re;
                product_ii<=mul_x_im*mul_w_im;
                product_ri<=mul_x_re*mul_w_im;
                product_ir<=mul_x_im*mul_w_re;
            end
            case(state)
                IDLE:begin
                    busy<=0;
                    if(start) begin
                        busy<=1;mode_q<=mode;b0_re<=x0_re;b0_im<=x0_im;
                        mul_x_re<=(mode==MODE_ROT_ONLY)?x0_re:x1_re;
                        mul_x_im<=(mode==MODE_ROT_ONLY)?x0_im:x1_im;
                        mul_w_re<=w1_re;mul_w_im<=w1_im;
                        state<=PRODUCT1;
                    end
                end
                PRODUCT1:begin
                    // Preserve the original x2/w2 sampling edge (start+1).
                    if(radix4_mode) begin
                        mul_x_re<=x2_re;mul_x_im<=x2_im;
                        mul_w_re<=w2_re;mul_w_im<=w2_im;
                    end
                    state<=ROTATE1;
                end
                ROTATE1:begin
                    b1_re<=rotation_re;b1_im<=rotation_im;
                    if(mode_q==MODE_ROT_ONLY) state<=SAT_ROT;
                    else if(mode_q==MODE_RADIX2) state<=BUTTERFLY_R2;
                    else begin
                        // Preserve the original x3/w3 sampling edge (start+2).
                        mul_x_re<=x3_re;mul_x_im<=x3_im;
                        mul_w_re<=w3_re;mul_w_im<=w3_im;
                        state<=ROTATE2;
                    end
                end
                ROTATE2:begin
                    b2_re<=rotation_re;b2_im<=rotation_im;
                    state<=ROTATE3;
                end
                ROTATE3:begin
                    b3_re<=rotation_re;b3_im<=rotation_im;
                    state<=R4_PARTIAL;
                end
                SAT_ROT:begin
                    y0_re<=sat_nb(b1_re);y0_im<=sat_nb(b1_im);
                    valid<=1;busy<=0;state<=IDLE;
                end
                BUTTERFLY_R2:begin
                    sum0_re<=b0_re_ext+b1_re;sum0_im<=b0_im_ext+b1_im;
                    sum1_re<=b0_re_ext-b1_re;sum1_im<=b0_im_ext-b1_im;
                    state<=SAT_OUTPUT;
                end
                R4_PARTIAL:begin
                    partial0_re<=b0_re_ext+b2_re;partial0_im<=b0_im_ext+b2_im;
                    partial1_re<=b0_re_ext-b2_re;partial1_im<=b0_im_ext-b2_im;
                    partial2_re<=b1_re+b3_re;partial2_im<=b1_im+b3_im;
                    partial3_re<=b1_re-b3_re;partial3_im<=b1_im-b3_im;
                    state<=R4_COMBINE;
                end
                R4_COMBINE:begin
                    sum0_re<=partial0_re+partial2_re;sum0_im<=partial0_im+partial2_im;
                    sum2_re<=partial0_re-partial2_re;sum2_im<=partial0_im-partial2_im;
                    sum1_re<=partial1_re+partial3_im;sum1_im<=partial1_im-partial3_re;
                    sum3_re<=partial1_re-partial3_im;sum3_im<=partial1_im+partial3_re;
                    state<=SAT_OUTPUT;
                end
                SAT_OUTPUT:begin
                    // Saturation has its own register boundary after the sums.
                    y0_re<=sat_nb(sum0_re);y0_im<=sat_nb(sum0_im);
                    y1_re<=sat_nb(sum1_re);y1_im<=sat_nb(sum1_im);
                    if(radix4_mode) begin
                        y2_re<=sat_nb(sum2_re);y2_im<=sat_nb(sum2_im);
                        y3_re<=sat_nb(sum3_re);y3_im<=sat_nb(sum3_im);
                    end
                    valid<=1;busy<=0;state<=IDLE;
                end
                default:begin state<=IDLE;busy<=0;end
            endcase
        end
    end
endmodule
