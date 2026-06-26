`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/15/2019 12:19:58 AM
// Design Name:
// Module Name: power_spectrum
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module power_spectrum #(parameter int N=512)(
    input clk,
    input reset,
    input [15:0] in,
    output [31:0] out,

    output s_ready,
    input s_valid,
    input s_last,

    input m_ready,
    output m_valid,
    output m_last
    );

    localparam int LOG2_N = $clog2(N);
    localparam int HALF_N = N/2;

    typedef enum logic [1:0] {
        ST_COLLECT,
        ST_FFT,
        ST_OUTPUT
    } state_t;

    state_t state;

    logic [LOG2_N:0] sample_cnt;
    logic [LOG2_N:0] out_cnt;

    logic signed [15:0] fft_real_in [0:511];
    logic signed [15:0] fft_out_re [0:511];
    logic signed [15:0] fft_out_im [0:511];

    logic fft_in_valid;
    logic fft_in_ready;
    logic fft_out_valid;
    logic fft_out_ready;

    logic signed [31:0] re_square;
    logic signed [31:0] im_square;
    logic [32:0] sum_square;

    assign s_ready = (state == ST_COLLECT);
    assign m_valid = (state == ST_OUTPUT);
    assign m_last = m_valid && (out_cnt == HALF_N-1);

    assign re_square = $signed(fft_out_re[out_cnt]) * $signed(fft_out_re[out_cnt]);
    assign im_square = $signed(fft_out_im[out_cnt]) * $signed(fft_out_im[out_cnt]);
    assign sum_square = re_square + im_square;
    assign out = sum_square >> LOG2_N;

    assign fft_in_valid = (state == ST_FFT);
    assign fft_out_ready = (state == ST_FFT);

    fft512 #(
        .NB(16),
        .TW(16)
    ) my_fft (
        .clk(clk),
        .fft_reset(reset),
        .reset(reset),
        .in_valid(fft_in_valid),
        .in_ready(fft_in_ready),
        .fft_real_in(fft_real_in),
        .out_valid(fft_out_valid),
        .out_ready(fft_out_ready),
        .fft_out_re(fft_out_re),
        .fft_out_im(fft_out_im)
    );

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= ST_COLLECT;
            sample_cnt <= '0;
            out_cnt <= '0;
            for(int i=0; i<512; i++) begin
                fft_real_in[i] <= '0;
            end
        end
        else begin
            case(state)
                ST_COLLECT: begin
                    out_cnt <= '0;

                    if(s_valid && s_ready) begin
                        fft_real_in[sample_cnt] <= in;

                        if(sample_cnt == N-1) begin
                            sample_cnt <= '0;
                            state <= ST_FFT;
                        end
                        else begin
                            sample_cnt <= sample_cnt + 1'b1;
                        end
                    end
                end

                ST_FFT: begin
                    if(fft_out_valid) begin
                        state <= ST_OUTPUT;
                    end
                end

                ST_OUTPUT: begin
                    if(m_valid && m_ready) begin
                        if(out_cnt == HALF_N-1) begin
                            out_cnt <= '0;
                            state <= ST_COLLECT;
                        end
                        else begin
                            out_cnt <= out_cnt + 1'b1;
                        end
                    end
                end

                default: begin
                    state <= ST_COLLECT;
                    sample_cnt <= '0;
                    out_cnt <= '0;
                end
            endcase
        end
    end
endmodule
