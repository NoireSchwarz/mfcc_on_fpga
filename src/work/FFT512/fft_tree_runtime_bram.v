`timescale 1ns/1ps
// Real-input streaming FFT. size_sel 0..7 selects 16<<size_sel points.
module fft_tree_runtime_bram(
    input clk,input resetn,input [2:0] size_sel,
    input [15:0] s_data,input s_valid,output s_ready,
    output [31:0] m_data,output m_valid,input m_ready,
    output m_last,output busy,output [2:0] size_active_o
);
    fft_tree_bram_engine engine_i(
        .clk(clk),.resetn(resetn),.size_sel(size_sel),
        .s_data(s_data),.s_imag(16'd0),.s_valid(s_valid),.s_ready(s_ready),
        .m_data(m_data),.m_valid(m_valid),.m_ready(m_ready),
        .m_last(m_last),.busy(busy),.size_active_o(size_active_o));
endmodule

// Small standalone pair: only one FFT16 root is elaborated.
module fft64_128_shared_runtime(
    input clk,input resetn,input mode_128,
    input [15:0] s_data,input s_valid,output s_ready,
    output [31:0] m_data,output m_valid,input m_ready,
    output m_last,output busy,output mode_active_o
);
    wire [2:0] active_size;
    assign mode_active_o=active_size[0];
    fft_tree_bram_engine #(.MAX_LOG2(7)) engine_i(
        .clk(clk),.resetn(resetn),.size_sel({2'b01,mode_128}),
        .s_data(s_data),.s_imag(16'd0),.s_valid(s_valid),.s_ready(s_ready),
        .m_data(m_data),.m_valid(m_valid),.m_ready(m_ready),
        .m_last(m_last),.busy(busy),.size_active_o(active_size));
endmodule
