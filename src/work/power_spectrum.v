`timescale 1ns/1ps
// Two elastic stages: registered squares, then registered low-32-bit sum.
// Ready/valid and last advance with the same token under backpressure.
module power_spectrum #(
    parameter integer N=512
)(
    input clk,input reset,input [15:0] in,output [31:0] out,
    output s_ready,input s_valid,input s_last,
    input m_ready,output m_valid,output m_last
);
    wire [31:0] fft_data;
    wire fft_valid,fft_last,fft_ready;
    wire signed [15:0] selected_re=fft_data[15:0];
    wire signed [15:0] selected_im=fft_data[31:16];
    reg signed [31:0] re_square_q,im_square_q;
    reg [31:0] power_q;
    reg square_valid,power_valid,square_last,power_last;
    wire power_ready=!power_valid || m_ready;
    wire square_ready=!square_valid || power_ready;
    wire [32:0] sum_square={1'b0,re_square_q}+{1'b0,im_square_q};
    assign fft_ready=!reset && square_ready;
    assign out=power_q;
    assign m_valid=power_valid;
    assign m_last=power_valid && power_last;
    fft512 #(.N(N),.HALF_SPECTRUM(1)) my_fft(
        .clk(clk),.reset(reset),.s_data(in),.s_valid(s_valid),.s_ready(s_ready),
        .m_data(fft_data),.m_valid(fft_valid),.m_ready(fft_ready),.m_last(fft_last));
    always @(posedge clk or posedge reset)
        if(reset) begin
            square_valid<=0;power_valid<=0;
            square_last<=0;power_last<=0;
        end else begin
            if(power_ready) begin
                power_valid<=square_valid;
                if(square_valid) begin
                    power_q<=sum_square[31:0];
                    power_last<=square_last;
                end
            end
            if(square_ready) begin
                square_valid<=fft_valid;
                if(fft_valid) begin
                    re_square_q<=selected_re*selected_re;
                    im_square_q<=selected_im*selected_im;
                    square_last<=fft_last;
                end
            end
        end
    // Datapath registers hold during reset; their valid bits are flushed.
    // s_last is reserved for compatibility; exactly N accepted words form a frame.
endmodule
