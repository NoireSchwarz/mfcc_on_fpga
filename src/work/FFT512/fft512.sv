`timescale 1ns / 1ps

module fft512 #(
    parameter int NB = 16,
    parameter int TW = 16,
    parameter int N = 512,
    parameter int HALF = N / 2
)(
    input  logic                         clk,
    input  logic                         fft_reset,
    input  logic                         reset,

    input  logic                         in_valid,
    output logic                         in_ready,
    input  var logic signed [NB-1:0]    fft_real_in [0:N-1],

    output logic                         out_valid,
    input  logic                         out_ready,
    output logic signed [NB-1:0]        fft_out_re [0:N-1],
    output logic signed [NB-1:0]        fft_out_im [0:N-1]
);

    localparam bit USE_RADIX2 = (N == 32) || (N == 128) || (N == 512) || (N == 2048);

    typedef enum logic [2:0] {
        IDLE,
        RUN_FFT,
        RUN_MERGE,
        RUN_BYPASS,
        HOLD
    } state_t;

    state_t                         state;
    logic signed [NB-1:0]           fft2_frame [0:N-1];
    logic signed [NB-1:0]           fft2_even_re [0:HALF-1];
    logic signed [NB-1:0]           fft2_even_im [0:HALF-1];
    logic signed [NB-1:0]           fft2_odd_re [0:HALF-1];
    logic signed [NB-1:0]           fft2_odd_im [0:HALF-1];
    logic signed [NB-1:0]           merge_out_re [0:N-1];
    logic signed [NB-1:0]           merge_out_im [0:N-1];
    logic [1:0]                     d_start;
    logic [1:0]                     q_start;
    logic                           fft2_start;
    logic                           fft2_valid;
    logic                           fft2_ready;
    logic                           merge_start;
    logic                           merge_valid;
    logic                           merge_busy;

    assign in_ready = (state == IDLE) && fft2_ready && (USE_RADIX2 ? !merge_busy : 1'b1);
    assign d_start[0] = (state == IDLE) && in_valid && in_ready;
    assign d_start[1] = (state == RUN_FFT) && fft2_valid && USE_RADIX2;
    assign fft2_start = q_start[0];
    assign merge_start = q_start[1];

    fft2 #(
        .NB(NB),
        .N(N)
    ) fft2_i (
        .clk(clk),
        .fft_reset(fft_reset),
        .reset(reset),
        .start(fft2_start),
        .fft_real_in(fft2_frame),
        .even_out_re(fft2_even_re),
        .even_out_im(fft2_even_im),
        .odd_out_re(fft2_odd_re),
        .odd_out_im(fft2_odd_im),
        .out_valid(fft2_valid),
        .m_ready(fft2_ready)
    );

    generate
        if (USE_RADIX2) begin : gen_radix2_merge
            radix2_merge_stage #(
                .NB(NB),
                .TW(TW),
                .N(N)
            ) merge_i (
                .clk(clk),
                .rst(fft_reset || reset),
                .start(merge_start),
                .even_re(fft2_even_re),
                .even_im(fft2_even_im),
                .odd_re(fft2_odd_re),
                .odd_im(fft2_odd_im),
                .out_valid(merge_valid),
                .busy(merge_busy),
                .out_re(merge_out_re),
                .out_im(merge_out_im)
            );
        end else begin : gen_no_radix2_merge
            assign merge_valid = 1'b0;
            assign merge_busy  = 1'b0;
        end
    endgenerate

    always_ff @(posedge clk or posedge fft_reset) begin
        if (fft_reset) begin
            state       <= IDLE;
            q_start     <= '0;
            out_valid   <= 1'b0;
        end else if (reset) begin
            state       <= IDLE;
            q_start     <= '0;
            out_valid   <= 1'b0;
        end else begin
            q_start <= d_start;

            case (state)
                IDLE: begin
                    out_valid <= 1'b0;
                    if (in_valid && in_ready) begin
                        for (int i = 0; i < N; i++) begin
                            fft2_frame[i] <= fft_real_in[i];
                        end
                        state <= RUN_FFT;
                    end
                end

                RUN_FFT: begin
                    if (fft2_valid) begin
                        if (USE_RADIX2) begin
                            state <= RUN_MERGE;
                        end else begin
                            state <= RUN_BYPASS;
                        end
                    end
                end

                RUN_MERGE: begin
                    if (merge_valid) begin
                        for (int i = 0; i < N; i++) begin
                            fft_out_re[i] <= merge_out_re[i];
                            fft_out_im[i] <= merge_out_im[i];
                        end
                        out_valid <= 1'b1;
                        state     <= HOLD;
                    end
                end

                RUN_BYPASS: begin
                    for (int i = 0; i < HALF; i++) begin
                        fft_out_re[2 * i]       <= fft2_even_re[i];
                        fft_out_im[2 * i]       <= fft2_even_im[i];
                        fft_out_re[(2 * i) + 1] <= fft2_odd_re[i];
                        fft_out_im[(2 * i) + 1] <= fft2_odd_im[i];
                    end
                    out_valid <= 1'b1;
                    state     <= HOLD;
                end

                HOLD: begin
                    out_valid <= 1'b1;
                    if (out_ready) begin
                        out_valid <= 1'b0;
                        state     <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
