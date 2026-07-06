`timescale 1ns / 1ps

module radix2_merge_stage #(
    parameter int NB = 16,
    parameter int TW = 16,
    parameter int N = 512,
    parameter int HALF = N / 2
)(
    input  logic                         clk,
    input  logic                         rst,
    input  logic                         start,
    input  var logic signed [NB-1:0]     even_re [0:HALF-1],
    input  var logic signed [NB-1:0]     even_im [0:HALF-1],
    input  var logic signed [NB-1:0]     odd_re  [0:HALF-1],
    input  var logic signed [NB-1:0]     odd_im  [0:HALF-1],
    output logic                         out_valid,
    output logic                         busy,
    output logic signed [NB-1:0]         out_re [0:N-1],
    output logic signed [NB-1:0]         out_im [0:N-1]
);

    localparam int STRIDE = 2048 / N;
    localparam logic [1:0] MODE_RADIX2 = 2'd1;

    typedef enum logic [1:0] {
        IDLE,
        START_KERNEL,
        WAIT_KERNEL
    } state_t;

    state_t state;
    logic [$clog2(HALF)-1:0] cnt;
    logic kernel_start;
    logic kernel_valid;
    logic kernel_busy;
    logic signed [TW-1:0] tw_re;
    logic signed [TW-1:0] tw_im;
    logic [10:0] tw_addr;
    logic signed [NB-1:0] y0_re;
    logic signed [NB-1:0] y0_im;
    logic signed [NB-1:0] y1_re;
    logic signed [NB-1:0] y1_im;
    logic signed [NB-1:0] unused_y2_re;
    logic signed [NB-1:0] unused_y2_im;
    logic signed [NB-1:0] unused_y3_re;
    logic signed [NB-1:0] unused_y3_im;
    logic [31:0] tw_addr_raw;

    assign tw_addr_raw = cnt * STRIDE;
    assign tw_addr = tw_addr_raw[10:0];

    WROM2048 #(.TW(TW)) twiddle_i (
        .ADDR(tw_addr),
        .WR(tw_re),
        .WI(tw_im)
    );

    fft_merge_kernel #(.NB(NB), .TW(TW)) kernel_i (
        .clk(clk),
        .rst(rst),
        .start(kernel_start),
        .mode(MODE_RADIX2),
        .x0_re(even_re[cnt]),
        .x0_im(even_im[cnt]),
        .x1_re(odd_re[cnt]),
        .x1_im(odd_im[cnt]),
        .x2_re('0),
        .x2_im('0),
        .x3_re('0),
        .x3_im('0),
        .w1_re(tw_re),
        .w1_im(tw_im),
        .w2_re('0),
        .w2_im('0),
        .w3_re('0),
        .w3_im('0),
        .valid(kernel_valid),
        .busy(kernel_busy),
        .y0_re(y0_re),
        .y0_im(y0_im),
        .y1_re(y1_re),
        .y1_im(y1_im),
        .y2_re(unused_y2_re),
        .y2_im(unused_y2_im),
        .y3_re(unused_y3_re),
        .y3_im(unused_y3_im)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            state        <= IDLE;
            cnt          <= '0;
            out_valid    <= 1'b0;
            busy         <= 1'b0;
            kernel_start <= 1'b0;
        end else begin
            kernel_start <= 1'b0;
            out_valid    <= 1'b0;

            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        cnt   <= '0;
                        busy  <= 1'b1;
                        state <= START_KERNEL;
                    end
                end

                START_KERNEL: begin
                    kernel_start <= 1'b1;
                    state        <= WAIT_KERNEL;
                end

                WAIT_KERNEL: begin
                    if (kernel_valid) begin
                        out_re[cnt]        <= y0_re;
                        out_im[cnt]        <= y0_im;
                        out_re[cnt + HALF] <= y1_re;
                        out_im[cnt + HALF] <= y1_im;

                        if (cnt == HALF - 1) begin
                            out_valid <= 1'b1;
                            busy      <= 1'b0;
                            state     <= IDLE;
                        end else begin
                            cnt   <= cnt + 1'b1;
                            state <= START_KERNEL;
                        end
                    end
                end
            endcase
        end
    end

endmodule
