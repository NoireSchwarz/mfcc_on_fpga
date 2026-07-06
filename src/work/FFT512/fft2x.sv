`timescale 1ns / 1ps

module fft2 #(
    parameter int NB = 16,
    parameter int TW = 16,
    parameter int N = 512,
    parameter int HALF = N / 2
)(
    input  logic                         clk,
    input  logic                         fft_reset,
    input  logic                         reset,
    input  logic                         start,
    input  var logic signed [NB-1:0]     fft_real_in [0:N-1],
    output logic signed [NB-1:0]         even_out_re [0:HALF-1],
    output logic signed [NB-1:0]         even_out_im [0:HALF-1],
    output logic signed [NB-1:0]         odd_out_re [0:HALF-1],
    output logic signed [NB-1:0]         odd_out_im [0:HALF-1],
    output logic                         out_valid,
    output logic                         m_ready
);

    localparam bit USE_2FFT16      = (N == 32) || (N == 128);
    localparam bit USE_2FFT256     = (N == 512) || (N == 2048);
    localparam bit USE_RADIX2      = USE_2FFT16 || USE_2FFT256;
    localparam bit DIRECT_OUTPUT   = !USE_RADIX2;
    localparam bit USE_FFT16       = (N == 16) || USE_2FFT16 || (N == 64);
    localparam bit USE_FFT256      = (N == 256) || USE_2FFT256 || (N == 1024);
    localparam int FFT16_64_POINTS = ((N == 64) || (N == 128)) ? 64 : 16;
    localparam int FFT256_1024_POINTS = ((N == 1024) || (N == 2048)) ? 1024 : 256;
    localparam int BASE_POINTS     = USE_FFT16 ? FFT16_64_POINTS : FFT256_1024_POINTS;
    localparam int COUNT_POINTS   = (BASE_POINTS > HALF) ? BASE_POINTS : HALF;
    localparam int CNTW = $clog2(COUNT_POINTS);
    localparam logic [CNTW-1:0] LAST_COUNT = BASE_POINTS - 1;

    typedef enum logic [2:0] {
        IDLE,
        FEED,
        WAIT_RDY,
        CAPTURE,
        BUILD,
        DIRECT
    } state_t;

    state_t                       state;
    logic [CNTW-1:0]              feed_cnt;
    logic signed [NB-1:0]         fft_res_re [0:N-1];
    logic signed [NB-1:0]         fft_res_im [0:N-1];
    logic signed [NB-1:0]         fft_in_dr;
    logic signed [NB-1:0]         fft_in_di;
    logic                         fft_start;
    logic                         fft_rdy;
    logic signed [NB-1:0]         base_or;
    logic signed [NB-1:0]         base_oi;



    initial begin
        if (!USE_RADIX2 && !DIRECT_OUTPUT) begin
            $fatal(1, "fft2 supports N=16,32,64,128,256,512,1024,2048; got N=%0d", N);
        end
    end

    generate
        if (USE_FFT16) begin : gen_fft16
            logic signed [NB+3:0] fft16_or;
            logic signed [NB+3:0] fft16_oi;

            fft_16_64 #(
                .NB(NB),
                .TW(TW),
                .N(FFT16_64_POINTS)
            ) fft16_i (
                .CLK(clk),
                .RST(fft_reset),
                .ED(1'b1),
                .START(fft_start),
                .DIR(fft_in_dr),
                .DII(fft_in_di),
                .RDY(fft_rdy),
                .DOR(fft16_or),
                .DOI(fft16_oi)
            );

            assign base_or = fft16_or[NB+3:4];
            assign base_oi = fft16_oi[NB+3:4];
        end else if (USE_FFT256) begin : gen_fft256
            fft256_1024 #(
                .NB(NB),
                .TW(TW),
                .N(FFT256_1024_POINTS)
            ) fft256_i (
                .CLK(clk),
                .RST(fft_reset),
                .ED(1'b1),
                .START(fft_start),
                .DIR(fft_in_dr),
                .DII(fft_in_di),
                .RDY(fft_rdy),
                .DOR(base_or),
                .DOI(base_oi)
            );
        end else begin : gen_no_base
            assign fft_rdy = 1'b0;
            assign base_or = '0;
            assign base_oi = '0;
        end
    endgenerate

    always_ff @(posedge clk or posedge fft_reset) begin
        if (fft_reset) begin
            state      <= IDLE;
            feed_cnt   <= '0;
            out_valid  <= 1'b0;
            m_ready    <= 1'b1;
            fft_start  <= 1'b0;
            fft_in_dr  <= '0;
            fft_in_di  <= '0;
        end else if (reset) begin
            state      <= IDLE;
            feed_cnt   <= '0;
            out_valid  <= 1'b0;
            m_ready    <= 1'b1;
            fft_start  <= 1'b0;
            fft_in_dr  <= '0;
            fft_in_di  <= '0;
        end else begin
            fft_start <= 1'b0;

            case (state)
                IDLE: begin
                    out_valid <= 1'b0;
                    m_ready   <= 1'b1;
                    if (start) begin
                        feed_cnt  <= '0;
                        m_ready   <= 1'b0;
                        out_valid <= 1'b0;
                        fft_start <= 1'b1;
                        state     <= FEED;
                    end
                end

                FEED: begin
                    if (DIRECT_OUTPUT) begin
                        fft_in_dr <= fft_real_in[feed_cnt];
                        fft_in_di <= '0;
                    end else begin
                        fft_in_dr <= fft_real_in[{feed_cnt, 1'b0}];
                        fft_in_di <= fft_real_in[{feed_cnt, 1'b1}];
                    end
                    feed_cnt  <= feed_cnt + 1'b1;

                    if (feed_cnt == LAST_COUNT) begin
                        feed_cnt <= '0;
                        state    <= WAIT_RDY;
                    end
                end

                WAIT_RDY: begin
                    if (fft_rdy) begin
                        feed_cnt <= '0;
                        state    <= CAPTURE;
                    end
                end

                CAPTURE: begin
                    fft_res_re[feed_cnt] <= base_or;
                    fft_res_im[feed_cnt] <= base_oi;
                    feed_cnt             <= feed_cnt + 1'b1;

                    if (feed_cnt == LAST_COUNT) begin
                        feed_cnt <= '0;
                        if (DIRECT_OUTPUT) begin
                            state <= DIRECT;
                        end else begin
                            state <= BUILD;
                        end
                    end
                end

                BUILD: begin
                    for (int i = 0; i < HALF; i++) begin
                        logic [CNTW-1:0] sym;
                        logic signed [NB:0] y_re;
                        logic signed [NB:0] y_im;
                        logic signed [NB:0] ys_re;
                        logic signed [NB:0] ys_im;
                        logic signed [NB:0] tmp_re_1;
                        logic signed [NB:0] tmp_im_1;
                        logic signed [NB:0] tmp_re_2;
                        logic signed [NB:0] tmp_im_2;

                        if (i < BASE_POINTS) begin
                            sym = (i == 0) ? '0 : (BASE_POINTS - i);
                            y_re  = {fft_res_re[i][NB-1], fft_res_re[i]};
                            y_im  = {fft_res_im[i][NB-1], fft_res_im[i]};
                            ys_re = {fft_res_re[sym][NB-1], fft_res_re[sym]};
                            ys_im = {fft_res_im[sym][NB-1], fft_res_im[sym]};

                            tmp_re_1 = y_re + ys_re;
                            tmp_im_1 = y_im - ys_im;
                            even_out_re[i] <= tmp_re_1 >>> 1;
                            even_out_im[i] <= tmp_im_1 >>> 1;

                            tmp_re_2 = y_im + ys_im;
                            tmp_im_2 = ys_re - y_re;
                            odd_out_re[i] <= tmp_re_2 >>> 1;
                            odd_out_im[i] <= tmp_im_2 >>> 1;
                        end else begin
                            even_out_re[i] <= '0;
                            even_out_im[i] <= '0;
                            odd_out_re[i]  <= '0;
                            odd_out_im[i]  <= '0;
                        end
                    end

                    even_out_re[0] <= fft_res_re[0];
                    even_out_im[0] <= '0;
                    odd_out_re[0]  <= fft_res_im[0];
                    odd_out_im[0]  <= '0;

                    out_valid <= 1'b1;
                    m_ready   <= 1'b1;
                    state     <= IDLE;
                end

                DIRECT: begin
                    for (int i = 0; i < HALF; i++) begin
                        if ((2 * i) < BASE_POINTS) begin
                            even_out_re[i] <= fft_res_re[2 * i];
                            even_out_im[i] <= fft_res_im[2 * i];
                        end else begin
                            even_out_re[i] <= '0;
                            even_out_im[i] <= '0;
                        end

                        if (((2 * i) + 1) < BASE_POINTS) begin
                            odd_out_re[i]  <= fft_res_re[(2 * i) + 1];
                            odd_out_im[i]  <= fft_res_im[(2 * i) + 1];
                        end else begin
                            odd_out_re[i] <= '0;
                            odd_out_im[i] <= '0;
                        end
                    end

                    out_valid <= 1'b1;
                    m_ready   <= 1'b1;
                    state     <= IDLE;
                end
            endcase
        end
    end

endmodule
