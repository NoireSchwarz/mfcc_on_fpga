`timescale 1ns / 1ps

module radix4_merge_stage #(
    parameter int NB = 16,
    parameter int TW = 16,
    parameter int N = 64,
    parameter int SPAN = N / 4
)(
    input  logic                         clk,
    input  logic                         rst,
    input  logic                         start,
    input  var logic signed [NB-1:0]     in0_re [0:SPAN-1],
    input  var logic signed [NB-1:0]     in0_im [0:SPAN-1],
    input  var logic signed [NB-1:0]     in1_re [0:SPAN-1],
    input  var logic signed [NB-1:0]     in1_im [0:SPAN-1],
    input  var logic signed [NB-1:0]     in2_re [0:SPAN-1],
    input  var logic signed [NB-1:0]     in2_im [0:SPAN-1],
    input  var logic signed [NB-1:0]     in3_re [0:SPAN-1],
    input  var logic signed [NB-1:0]     in3_im [0:SPAN-1],
    output logic                         out_valid,
    output logic                         busy,
    output logic signed [NB-1:0]         out_re [0:N-1],
    output logic signed [NB-1:0]         out_im [0:N-1]
);

    localparam int STRIDE = 2048 / N;
    localparam logic [1:0] MODE_RADIX4 = 2'd2;

    typedef enum logic [1:0] {
        IDLE,
        START_KERNEL,
        WAIT_KERNEL
    } state_t;

    state_t state;
    logic [$clog2(SPAN)-1:0] cnt;
    logic kernel_start;
    logic kernel_valid;
    logic kernel_busy;
    logic signed [TW-1:0] tw1_re;
    logic signed [TW-1:0] tw1_im;
    logic signed [TW-1:0] tw2_re;
    logic signed [TW-1:0] tw2_im;
    logic signed [TW-1:0] tw3_re;
    logic signed [TW-1:0] tw3_im;
    logic [10:0] tw1_addr;
    logic [10:0] tw2_addr;
    logic [10:0] tw3_addr;
    logic [31:0] tw_base_addr;
    logic [31:0] tw2_addr_raw;
    logic [31:0] tw3_addr_raw;
    logic signed [NB-1:0] y0_re;
    logic signed [NB-1:0] y0_im;
    logic signed [NB-1:0] y1_re;
    logic signed [NB-1:0] y1_im;
    logic signed [NB-1:0] y2_re;
    logic signed [NB-1:0] y2_im;
    logic signed [NB-1:0] y3_re;
    logic signed [NB-1:0] y3_im;

    assign tw_base_addr = cnt * STRIDE;
    assign tw2_addr_raw = tw_base_addr << 1;
    assign tw3_addr_raw = tw_base_addr + (tw_base_addr << 1);
    assign tw1_addr = tw_base_addr[10:0];
    assign tw2_addr = tw2_addr_raw[10:0];
    assign tw3_addr = tw3_addr_raw[10:0];

    WROM2048 #(.TW(TW)) twiddle1_i (.ADDR(tw1_addr), .WR(tw1_re), .WI(tw1_im));
    WROM2048 #(.TW(TW)) twiddle2_i (.ADDR(tw2_addr), .WR(tw2_re), .WI(tw2_im));
    WROM2048 #(.TW(TW)) twiddle3_i (.ADDR(tw3_addr), .WR(tw3_re), .WI(tw3_im));

    fft_merge_kernel #(.NB(NB), .TW(TW)) kernel_i (
        .clk(clk),
        .rst(rst),
        .start(kernel_start),
        .mode(MODE_RADIX4),
        .x0_re(in0_re[cnt]),
        .x0_im(in0_im[cnt]),
        .x1_re(in1_re[cnt]),
        .x1_im(in1_im[cnt]),
        .x2_re(in2_re[cnt]),
        .x2_im(in2_im[cnt]),
        .x3_re(in3_re[cnt]),
        .x3_im(in3_im[cnt]),
        .w1_re(tw1_re),
        .w1_im(tw1_im),
        .w2_re(tw2_re),
        .w2_im(tw2_im),
        .w3_re(tw3_re),
        .w3_im(tw3_im),
        .valid(kernel_valid),
        .busy(kernel_busy),
        .y0_re(y0_re),
        .y0_im(y0_im),
        .y1_re(y1_re),
        .y1_im(y1_im),
        .y2_re(y2_re),
        .y2_im(y2_im),
        .y3_re(y3_re),
        .y3_im(y3_im)
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
                        out_re[cnt]          <= y0_re;
                        out_im[cnt]          <= y0_im;
                        out_re[cnt + SPAN]   <= y1_re;
                        out_im[cnt + SPAN]   <= y1_im;
                        out_re[cnt + 2*SPAN] <= y2_re;
                        out_im[cnt + 2*SPAN] <= y2_im;
                        out_re[cnt + 3*SPAN] <= y3_re;
                        out_im[cnt + 3*SPAN] <= y3_im;

                        if (cnt == SPAN - 1) begin
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
