`timescale 1ns/1ps
// Streaming BRAM FFT -> the original low-32-bit Re^2+Im^2 contract.
// The FFT emits only bins 0..N/2-1; no discarded upper-half drain or frame bus.
module power_spectrum #(
    parameter integer N=512
)(
    input clk,input reset,input [15:0] in,output [31:0] out,
    output s_ready,input s_valid,input s_last,
    input m_ready,output m_valid,output m_last
);
    wire [31:0] fft_data;
    wire signed [15:0] selected_re=fft_data[15:0];
    wire signed [15:0] selected_im=fft_data[31:16];
    wire signed [31:0] re_square=selected_re*selected_re;
    wire signed [31:0] im_square=selected_im*selected_im;
    wire [32:0] sum_square={1'b0,re_square}+{1'b0,im_square};
    assign out=sum_square[31:0];
    fft512 #(.N(N),.HALF_SPECTRUM(1)) my_fft(
        .clk(clk),.reset(reset),.s_data(in),.s_valid(s_valid),.s_ready(s_ready),
        .m_data(fft_data),.m_valid(m_valid),.m_ready(m_ready),.m_last(m_last));
    // s_last is reserved for compatibility; exactly N accepted words form a frame.
endmodule
