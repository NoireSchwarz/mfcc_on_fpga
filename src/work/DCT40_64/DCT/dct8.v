`timescale 1ns/1ps
// Registered version of the original factorized eight-point DCT.
// Each product is shifted/truncated at exactly the original arithmetic boundary.
module dct8_parallel #(
    parameter integer IN_W = 24,
    parameter integer OUT_W = IN_W + 4
)(
    input wire CLK, RST, ED, in_valid,
    input wire [2:0] in_tag,
    output wire out_valid,
    output wire [2:0] out_tag,
    input wire signed [IN_W-1:0] x0,x1,x2,x3,x4,x5,x6,x7,
    output wire signed [OUT_W-1:0] y0,y1,y2,y3,y4,y5,y6,y7
);
    localparam integer S1_W=IN_W+1, S2_W=IN_W+2, S3_W=IN_W+3;
    localparam integer P1_W=S1_W+16, P2_W=S2_W+16;
    localparam integer P3_W=S3_W+16, P4_W=OUT_W+16;
    localparam integer PIPE_STAGES=9;
    localparam signed [15:0] C5=16'sd18205, S5=16'sd27246;
    localparam signed [15:0] C6=16'sd12540, S6=16'sd30274;
    localparam signed [15:0] C7=16'sd6393, S7=16'sd32138;
    localparam signed [15:0] SQRT8=16'sd23170, SQRT8_INV=16'sd11585;

    wire signed [IN_W-1:0] x_in [0:7];
    reg signed [IN_W-1:0] input_q [0:7];
    reg signed [S1_W-1:0] a1 [0:7];
    reg signed [P1_W-1:0] p1 [0:7];
    reg signed [S2_W-1:0] even2 [0:3];
    reg signed [S2_W-1:0] a2 [0:7];
    reg signed [P2_W-1:0] p2 [0:3];
    reg signed [S3_W-1:0] side3 [0:5];
    reg signed [S3_W-1:0] a3 [0:7];
    reg signed [P3_W-1:0] p3 [0:1];
    reg signed [OUT_W-1:0] side4 [0:5];
    reg signed [P4_W-1:0] p4 [0:1];
    reg signed [OUT_W-1:0] side5 [0:5];
    reg signed [OUT_W-1:0] result_q [0:7];
    reg [PIPE_STAGES-1:0] valid_q;
    reg [2:0] tag_q [0:PIPE_STAGES-1];
    integer i;

    // The old signed_mult first shifted its full product, then assigned to
    // STAGE2_W/STAGE3_W. Preserve that truncation BEFORE rotation addition.
    function signed [S2_W-1:0] scale_p1;
        input signed [P1_W-1:0] value;
        begin scale_p1=value >>> 15; end
    endfunction
    function signed [S3_W-1:0] scale_p2;
        input signed [P2_W-1:0] value;
        begin scale_p2=value >>> 15; end
    endfunction
    function signed [OUT_W-1:0] extend3;
        input signed [S3_W-1:0] value;
        begin extend3=value; end
    endfunction
    assign x_in[0]=x0; assign x_in[1]=x1;
    assign x_in[2]=x2; assign x_in[3]=x3;
    assign x_in[4]=x4; assign x_in[5]=x5;
    assign x_in[6]=x6; assign x_in[7]=x7;
    assign y0=result_q[0]; assign y1=result_q[1];
    assign y2=result_q[2]; assign y3=result_q[3];
    assign y4=result_q[4]; assign y5=result_q[5];
    assign y6=result_q[6]; assign y7=result_q[7];
    assign out_valid=valid_q[PIPE_STAGES-1];
    assign out_tag=tag_q[PIPE_STAGES-1];

    always @(posedge CLK) begin
        if(RST) begin
            valid_q<=0;
            for(i=0;i<PIPE_STAGES;i=i+1) tag_q[i]<=0;
        end else if(ED) begin
            valid_q<={valid_q[PIPE_STAGES-2:0],in_valid};
            tag_q[0]<=in_tag;
            for(i=1;i<PIPE_STAGES;i=i+1) tag_q[i]<=tag_q[i-1];
            // Stage 0: input selection is isolated from the first butterfly.
            if(in_valid)
                for(i=0;i<8;i=i+1) input_q[i]<=x_in[i];
            // Stage 1: initial butterfly, one signed add/subtract per path.
            if(valid_q[0]) begin
                for(i=0;i<4;i=i+1) begin
                    a1[i]<=$signed({input_q[i][IN_W-1],input_q[i]})
                         + $signed({input_q[7-i][IN_W-1],input_q[7-i]});
                    a1[7-i]<=$signed({input_q[i][IN_W-1],input_q[i]})
                           - $signed({input_q[7-i][IN_W-1],input_q[7-i]});
                end
            end
            // Stage 2: first rotation products; even butterflies run in parallel.
            if(valid_q[1]) begin
                p1[0]<=a1[4]*C7; p1[1]<=a1[4]*S7;
                p1[2]<=a1[7]*C7; p1[3]<=a1[7]*S7;
                p1[4]<=a1[5]*C5; p1[5]<=a1[5]*S5;
                p1[6]<=a1[6]*C5; p1[7]<=a1[6]*S5;
                even2[0]<=$signed({a1[0][S1_W-1],a1[0]})+$signed({a1[3][S1_W-1],a1[3]});
                even2[1]<=$signed({a1[1][S1_W-1],a1[1]})+$signed({a1[2][S1_W-1],a1[2]});
                even2[2]<=$signed({a1[1][S1_W-1],a1[1]})-$signed({a1[2][S1_W-1],a1[2]});
                even2[3]<=$signed({a1[0][S1_W-1],a1[0]})-$signed({a1[3][S1_W-1],a1[3]});
            end
            // Stage 3: first rotations, using already registered products.
            if(valid_q[2]) begin
                for(i=0;i<4;i=i+1) a2[i]<=even2[i];
                a2[4]<=scale_p1(p1[0])+scale_p1(p1[3]);
                a2[7]<=scale_p1(p1[2])-scale_p1(p1[1]);
                a2[5]<=scale_p1(p1[4])+scale_p1(p1[7]);
                a2[6]<=scale_p1(p1[6])-scale_p1(p1[5]);
            end
            // Stage 4: second rotation products; remaining butterflies in parallel.
            if(valid_q[3]) begin
                p2[0]<=a2[2]*C6; p2[1]<=a2[2]*S6;
                p2[2]<=a2[3]*C6; p2[3]<=a2[3]*S6;
                side3[0]<=$signed({a2[0][S2_W-1],a2[0]})+$signed({a2[1][S2_W-1],a2[1]});
                side3[1]<=$signed({a2[0][S2_W-1],a2[0]})-$signed({a2[1][S2_W-1],a2[1]});
                side3[2]<=$signed({a2[4][S2_W-1],a2[4]})+$signed({a2[5][S2_W-1],a2[5]});
                side3[3]<=$signed({a2[4][S2_W-1],a2[4]})-$signed({a2[5][S2_W-1],a2[5]});
                side3[4]<=$signed({a2[6][S2_W-1],a2[6]})+$signed({a2[7][S2_W-1],a2[7]});
                side3[5]<=$signed({a2[6][S2_W-1],a2[6]})-$signed({a2[7][S2_W-1],a2[7]});
            end
            // Stage 5: second rotation sums; align all bypass branches.
            if(valid_q[4]) begin
                a3[0]<=side3[0]; a3[1]<=side3[1];
                a3[2]<=scale_p2(p2[0])+scale_p2(p2[3]);
                a3[3]<=scale_p2(p2[2])-scale_p2(p2[1]);
                a3[4]<=side3[2]; a3[5]<=side3[3];
                a3[6]<=side3[4]; a3[7]<=side3[5];
            end
            // Stage 6: even normalization products and odd pre-adds in parallel.
            if(valid_q[5]) begin
                p3[0]<=a3[0]*SQRT8; p3[1]<=a3[1]*SQRT8_INV;
                side4[0]<=extend3(a3[2]) >>> 1;
                side4[1]<=extend3(a3[3]) >>> 1;
                side4[2]<=extend3(a3[4]) >>> 1;
                side4[3]<=extend3(a3[5])+extend3(a3[6]);
                side4[4]<=extend3(a3[5])-extend3(a3[6]);
                side4[5]<=-extend3(a3[7]) >>> 1;
            end
            // Stage 7: odd normalization products use registered pre-adds.
            if(valid_q[6]) begin
                p4[0]<=side4[3]*SQRT8; p4[1]<=side4[4]*SQRT8_INV;
                side5[0]<=p3[0] >>> 16; side5[3]<=p3[1] >>> 15;
                side5[1]<=side4[2]; side5[2]<=side4[0];
                side5[4]<=side4[1]; side5[5]<=side4[5];
            end
            // Stage 8: original output ordering and final fixed-point slices.
            if(valid_q[7]) begin
                result_q[0]<=side5[0]; result_q[1]<=side5[1];
                result_q[2]<=side5[2]; result_q[3]<=p4[0] >>> 16;
                result_q[4]<=side5[3]; result_q[5]<=p4[1] >>> 15;
                result_q[6]<=side5[4]; result_q[7]<=side5[5];
            end
        end
    end
endmodule
