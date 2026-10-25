`timescale 1ns/1ps
// Public Verilog-2001 interface: lane 0 is always in the least-significant bits.
// Internal sv2v arrays retain their original ascending-index ordering.
module mfcc #(
    parameter N=512, STRIDE=256, PRE_EMPH_COEFF=16'd31785,
    parameter LOG_FLOOR_LOG2=-16, DCT_USE_MATRIX=0, OUT_WIDTH=1,
    parameter DCT_DATA_W=16, DCT_SKEW_OUT_W=24,
    parameter DCT_OUT_W=DCT_SKEW_OUT_W+2,
    parameter POWER_SPEC_OUT_W=32, FILTER_BANK_OUT_W=16,
    parameter RESHAPE_POINTS=64, M_AXIS_DATA_W=DCT_OUT_W
)(
    input clk, reset,
    input [15:0] s_axis_tdata,
    output signed [OUT_WIDTH*M_AXIS_DATA_W-1:0] m_axis_tdata,
    output s_axis_tready, input s_axis_tvalid,
    input m_axis_tready, output m_axis_tvalid, output m_axis_tlast
);
    wire signed [OUT_WIDTH*M_AXIS_DATA_W-1:0] array_order_data;
    genvar lane;
    generate for(lane=0;lane<OUT_WIDTH;lane=lane+1) begin: output_lanes
        assign m_axis_tdata[lane*M_AXIS_DATA_W +: M_AXIS_DATA_W] =
            array_order_data[(OUT_WIDTH-1-lane)*M_AXIS_DATA_W +: M_AXIS_DATA_W];
    end endgenerate
    mfcc_core #(.N(N),.STRIDE(STRIDE),.PRE_EMPH_COEFF(PRE_EMPH_COEFF),
        .LOG_FLOOR_LOG2(LOG_FLOOR_LOG2),.DCT_USE_MATRIX(DCT_USE_MATRIX),
        .OUT_WIDTH(OUT_WIDTH),.DCT_DATA_W(DCT_DATA_W),
        .DCT_SKEW_OUT_W(DCT_SKEW_OUT_W),.DCT_OUT_W(DCT_OUT_W),
        .POWER_SPEC_OUT_W(POWER_SPEC_OUT_W),.FILTER_BANK_OUT_W(FILTER_BANK_OUT_W),
        .RESHAPE_POINTS(RESHAPE_POINTS),.M_AXIS_DATA_W(M_AXIS_DATA_W)) U_CORE (
        .clk(clk),.reset(reset),.s_axis_tdata(s_axis_tdata),
        .m_axis_tdata(array_order_data),.s_axis_tready(s_axis_tready),
        .s_axis_tvalid(s_axis_tvalid),.m_axis_tready(m_axis_tready),
        .m_axis_tvalid(m_axis_tvalid),.m_axis_tlast(m_axis_tlast));
endmodule
