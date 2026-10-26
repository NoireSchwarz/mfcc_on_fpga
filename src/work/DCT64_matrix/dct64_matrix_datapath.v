`timescale 1ns/1ps
// Parallel frame capture, registered product, registered accumulation.
// Rounding, scaling, output truncation and sticky overflow match the baseline.
module dct64_matrix_datapath #(
    parameter DATA_W=16,
    parameter C_OUT_W=26,
    parameter COEF_W=20,
    parameter COEF_FRAC=14,
    parameter ACC_W=(DATA_W+COEF_W)+6
)(
    input wire clk, rst,
    input wire [64*DATA_W-1:0] s_data,
    input wire [3:0] shift,
    input wire frame_load,
    input wire [5:0] sample_raddr,
    input wire signed [COEF_W-1:0] coeff_rdata,
    input wire operand_re, product_en, accumulator_clear, accumulator_en, result_we,
    output wire signed [C_OUT_W-1:0] result_wdata,
    output reg ovf_dct
);
    localparam PROD_W=DATA_W+COEF_W;
    localparam SCALE_W=ACC_W+6;
    localparam signed [ACC_W-1:0] ONE={{ACC_W-1{1'b0}},1'b1};
    localparam signed [ACC_W-1:0] HALF_LSB=(COEF_FRAC==0 ? 0 : ONE << (COEF_FRAC-1));
    reg [64*DATA_W-1:0] frame_hold;
    reg [3:0] shift_hold;
    reg signed [DATA_W-1:0] sample_q;
    reg signed [COEF_W-1:0] coefficient_q;
    reg signed [PROD_W-1:0] product_q;
    reg signed [ACC_W-1:0] accumulator;
    wire signed [DATA_W-1:0] sample_value=frame_hold[sample_raddr*DATA_W+:DATA_W];
    wire [2:0] left_shift={1'b0,shift_hold[1:0]}+{1'b0,shift_hold[3:2]};
    wire signed [ACC_W-1:0] product_ext={{ACC_W-PROD_W{product_q[PROD_W-1]}},product_q};
    wire signed [ACC_W-1:0] biased=(COEF_FRAC==0 ? accumulator : (accumulator+HALF_LSB)-(accumulator[ACC_W-1] ? ONE : 0));
    wire signed [ACC_W-1:0] rounded=biased >>> COEF_FRAC;
    wire signed [SCALE_W-1:0] rounded_ext={{SCALE_W-ACC_W{rounded[ACC_W-1]}},rounded};
    wire signed [SCALE_W-1:0] scaled=(rounded_ext <<< left_shift) >>> 4;
    wire signed [SCALE_W-1:0] restored=result_wdata;
    assign result_wdata=scaled;
    always @(posedge clk) begin
        if(rst) begin frame_hold<=0; shift_hold<=0; end
        else if(frame_load) begin frame_hold<=s_data; shift_hold<=shift; end
    end
    always @(posedge clk)
        if(operand_re) begin sample_q<=sample_value; coefficient_q<=coeff_rdata; end
    always @(posedge clk)
        if(product_en) product_q<=sample_q*coefficient_q;
    always @(posedge clk)
        if(rst) accumulator<=0;
        else if(accumulator_clear) accumulator<=0;
        else if(accumulator_en) accumulator<=accumulator+product_ext;
    always @(posedge clk)
        if(rst) ovf_dct<=1'b0;
        else if(frame_load) ovf_dct<=1'b0;
        else if(result_we) ovf_dct<=ovf_dct || (restored!=scaled);
endmodule
