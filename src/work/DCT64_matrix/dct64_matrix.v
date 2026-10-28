`timescale 1ns/1ps
// Register/LUT-backed matrix DCT; public interface and numeric parameters retained.
module dct64_matrix #(
    parameter DATA_W=16,
    parameter SKEW_OUT_W=24,
    parameter C_OUT_W=SKEW_OUT_W+2,
    parameter COEF_W=20,
    parameter COEF_FRAC=14,
    parameter ACC_W=(DATA_W+COEF_W)+6,
    parameter COEFF_FILE="dct64_coeff_q14.mem"
)(
    input wire clk, rst,
    input wire [3:0] shift,
    input wire [64*DATA_W-1:0] s_data,
    input wire s_valid,
    output wire s_ready,
    output wire signed [C_OUT_W-1:0] m_data,
    output wire [5:0] m_index,
    output wire m_valid,
    input wire m_ready,
    output wire ovf_skew, ovf_dct
);
    wire frame_load, operand_re, product_en, accumulator_clear, accumulator_en;
    wire result_we, result_re;
    wire [5:0] sample_raddr, result_waddr, result_raddr;
    wire [11:0] coeff_raddr;
    wire signed [COEF_W-1:0] coeff_rdata;
    wire signed [C_OUT_W-1:0] result_wdata;
    assign ovf_skew=1'b0;
    dct64_matrix_ctrl U_CONTROL(
        .clk(clk),.rst(rst),.s_valid(s_valid),.s_ready(s_ready),
        .m_valid(m_valid),.m_ready(m_ready),.m_index(m_index),
        .frame_load(frame_load),.sample_raddr(sample_raddr),.coeff_raddr(coeff_raddr),
        .operand_re(operand_re),.product_en(product_en),.accumulator_clear(accumulator_clear),.accumulator_en(accumulator_en),
        .result_we(result_we),.result_re(result_re),.result_waddr(result_waddr),.result_raddr(result_raddr));
    dct64_matrix_datapath #(.DATA_W(DATA_W),.C_OUT_W(C_OUT_W),.COEF_W(COEF_W),
        .COEF_FRAC(COEF_FRAC),.ACC_W(ACC_W)) U_DATAPATH(
        .clk(clk),.rst(rst),.s_data(s_data),.shift(shift),.frame_load(frame_load),
        .sample_raddr(sample_raddr),.coeff_rdata(coeff_rdata),.operand_re(operand_re),.product_en(product_en),
        .accumulator_clear(accumulator_clear),.accumulator_en(accumulator_en),
        .result_we(result_we),.result_wdata(result_wdata),.ovf_dct(ovf_dct));
    dct64_coeff_rom #(.DATA_W(COEF_W),.COEFF_FILE(COEFF_FILE)) U_COEFF_LUT(
        .CLK(clk),.ED(product_en),.ADDR(coeff_raddr),.DOUT(coeff_rdata));
    dct64_ram64 #(.DATA_W(C_OUT_W)) U_OUTPUT_REGS(
        .CLK(clk),.WE(result_we),.ADDRW(result_waddr),.DI(result_wdata),
        .RE(result_re),.ADDRR(result_raddr),.DO(m_data));
endmodule
