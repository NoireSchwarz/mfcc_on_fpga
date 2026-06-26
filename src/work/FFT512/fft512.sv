`timescale 1ns / 1ps

module fft512 #(
    parameter NB = 16,
    parameter TW = 16
)(
    input  logic                         clk,
    input  logic                         fft_reset,
    input  logic                         reset,

    input  logic                         in_valid,
    output logic                         in_ready,
    input  var logic signed [NB-1:0]    fft_real_in [0:511],

    output logic                         out_valid,
    input  logic                         out_ready,
    output logic signed [NB-1:0]        fft_out_re [0:511],
    output logic signed [NB-1:0]        fft_out_im [0:511]
);

    typedef enum logic [2:0] {
        IDLE,
        START_FFT,
        RUN_FFT,
        BUILD_LOAD,
        BUILD_MUL,
        BUILD_ROT,
        BUILD_WRITE,
        HOLD
    } state_t;

    localparam int MW = NB + TW + 1;

    state_t                         state;
    logic [7:0]                     build_cnt;
    logic [7:0]                     build_idx_q;
    logic signed [NB-1:0]           fft2_frame [0:511];
    logic signed [NB-1:0]           fft2_even_re [0:255];
    logic signed [NB-1:0]           fft2_even_im [0:255];
    logic signed [NB-1:0]           fft2_odd_re [0:255];
    logic signed [NB-1:0]           fft2_odd_im [0:255];
    logic                            fft2_start;
    logic                            fft2_valid;
    logic                            fft2_ready;
    logic signed [TW-1:0]           tw_re;
    logic signed [TW-1:0]           tw_im;
    logic signed [63:0]             even_re_q;
    logic signed [63:0]             even_im_q;
    logic signed [NB-1:0]           odd_re_q;
    logic signed [NB-1:0]           odd_im_q;
    logic signed [TW-1:0]           tw_re_q;
    logic signed [TW-1:0]           tw_im_q;
    logic signed [MW-1:0]           mul_rr_q;
    logic signed [MW-1:0]           mul_ii_q;
    logic signed [MW-1:0]           mul_ri_q;
    logic signed [MW-1:0]           mul_ir_q;
    logic signed [63:0]             rot_re_q;
    logic signed [63:0]             rot_im_q;

    assign in_ready = (state == IDLE) && fft2_ready;

    fft2x256 #(.NB(NB)) fft2x256_i (
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

    WROM512 #(.TW(TW)) twiddle_i (
        .ADDR(build_cnt),
        .WR(tw_re),
        .WI(tw_im)
    );

    function automatic logic signed [NB-1:0] sat_nb(input logic signed [63:0] value);
        logic signed [63:0] max_value;
        logic signed [63:0] min_value;
        begin
            max_value = (64'sd1 <<< (NB - 1)) - 64'sd1;
            min_value = -(64'sd1 <<< (NB - 1));

            if (value > max_value) begin
                sat_nb = {1'b0, {(NB-1){1'b1}}};
            end else if (value < min_value) begin
                sat_nb = {1'b1, {(NB-1){1'b0}}};
            end else begin
                sat_nb = value[NB-1:0];
            end
        end
    endfunction

    always_ff @(posedge clk or posedge fft_reset) begin
        if (fft_reset) begin
            state      <= IDLE;
            build_cnt  <= 8'd0;
            build_idx_q <= 8'd0;
            fft2_start <= 1'b0;
            out_valid  <= 1'b0;
            even_re_q  <= '0;
            even_im_q  <= '0;
            odd_re_q   <= '0;
            odd_im_q   <= '0;
            tw_re_q    <= '0;
            tw_im_q    <= '0;
            mul_rr_q   <= '0;
            mul_ii_q   <= '0;
            mul_ri_q   <= '0;
            mul_ir_q   <= '0;
            rot_re_q   <= '0;
            rot_im_q   <= '0;
        end else if (reset) begin
            state      <= IDLE;
            build_cnt  <= 8'd0;
            build_idx_q <= 8'd0;
            fft2_start <= 1'b0;
            out_valid  <= 1'b0;
            even_re_q  <= '0;
            even_im_q  <= '0;
            odd_re_q   <= '0;
            odd_im_q   <= '0;
            tw_re_q    <= '0;
            tw_im_q    <= '0;
            mul_rr_q   <= '0;
            mul_ii_q   <= '0;
            mul_ri_q   <= '0;
            mul_ir_q   <= '0;
            rot_re_q   <= '0;
            rot_im_q   <= '0;
        end else begin
            fft2_start <= 1'b0;

            case (state)
                IDLE: begin
                    out_valid <= 1'b0;
                    if (in_valid && in_ready) begin
                        for (int i = 0; i < 512; i++) begin
                            fft2_frame[i] <= fft_real_in[i];
                        end
                        state      <= START_FFT;
                    end
                end

                START_FFT: begin
                    fft2_start <= 1'b1;
                    state      <= RUN_FFT;
                end

                RUN_FFT: begin
                    if (fft2_valid) begin
                        build_cnt <= 8'd0;
                        state     <= BUILD_LOAD;
                    end
                end

                BUILD_LOAD: begin
                    build_idx_q <= build_cnt;
                    even_re_q  <= $signed(fft2_even_re[build_cnt]);
                    even_im_q  <= $signed(fft2_even_im[build_cnt]);
                    odd_re_q   <= $signed(fft2_odd_re[build_cnt]);
                    odd_im_q   <= $signed(fft2_odd_im[build_cnt]);
                    tw_re_q    <= $signed(tw_re);
                    tw_im_q    <= $signed(tw_im);
                    state      <= BUILD_MUL;
                end

                BUILD_MUL: begin
                    mul_rr_q <= odd_re_q * tw_re_q;
                    mul_ii_q <= odd_im_q * tw_im_q;
                    mul_ri_q <= odd_re_q * tw_im_q;
                    mul_ir_q <= odd_im_q * tw_re_q;
                    state    <= BUILD_ROT;
                end

                BUILD_ROT: begin
                    rot_re_q <= (mul_rr_q - mul_ii_q) >>> (TW - 1);
                    rot_im_q <= (mul_ri_q + mul_ir_q) >>> (TW - 1);
                    state    <= BUILD_WRITE;
                end

                BUILD_WRITE: begin
                    fft_out_re[build_idx_q]       <= sat_nb(even_re_q + rot_re_q);
                    fft_out_im[build_idx_q]       <= sat_nb(even_im_q + rot_im_q);
                    fft_out_re[build_idx_q + 256] <= sat_nb(even_re_q - rot_re_q);
                    fft_out_im[build_idx_q + 256] <= sat_nb(even_im_q - rot_im_q);

                    if (build_cnt == 8'd255) begin
                        out_valid <= 1'b1;
                        state     <= HOLD;
                    end else begin
                        build_cnt <= build_cnt + 8'd1;
                        state     <= BUILD_LOAD;
                    end
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
