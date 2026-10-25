`timescale 1ns/1ps
// Fixed-size streaming facade. N is elaborated with the complete MFCC chain.
// Whole-frame parallel buses are replaced by one 16-bit input / 32-bit output.
module fft512 #(
    parameter integer N=512,
    parameter integer HALF_SPECTRUM=0
)(
    input clk,input reset,input [15:0] s_data,input s_valid,output s_ready,
    output [31:0] m_data,output m_valid,input m_ready,output m_last
);
    localparam [2:0] SIZE=(N==16)?0:(N==32)?1:(N==64)?2:(N==128)?3:
        (N==256)?4:(N==512)?5:(N==1024)?6:7;
    localparam integer MAX_LOG2=(N<=32)?5:(N<=128)?7:(N<=512)?9:11;
    localparam integer ROOT_FAMILY=(N<=128)?1:2;
    wire busy;
    wire [2:0] active_size;
    initial if(N!=16 && N!=32 && N!=64 && N!=128 && N!=256 && N!=512 && N!=1024 && N!=2048)begin
        $display("ERROR: unsupported FFT length N=%0d",N);$finish;
    end
    fft_tree_bram_engine #(.MAX_LOG2(MAX_LOG2),.ROOT_FAMILY(ROOT_FAMILY),
        .HALF_SPECTRUM(HALF_SPECTRUM)) engine_i(
        .clk(clk),.resetn(!reset),.size_sel(SIZE),.s_data(s_data),.s_imag(16'd0),
        .s_valid(s_valid),.s_ready(s_ready),.m_data(m_data),.m_valid(m_valid),
        .m_ready(m_ready),.m_last(m_last),.busy(busy),.size_active_o(active_size));
endmodule
