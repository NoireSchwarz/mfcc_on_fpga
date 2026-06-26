`timescale 1ns / 1ps
module fft2x256 #(
    parameter NB = 16
)(
    input  logic                         clk,
    input  logic                         fft_reset,
    input  logic                         reset,
    input  logic                         start,
    input  var logic signed [NB-1:0]    fft_real_in [0:511],
    output logic signed [NB-1:0]        even_out_re [0:255],
    output logic signed [NB-1:0]        even_out_im [0:255],
    output logic signed [NB-1:0]        odd_out_re [0:255],
    output logic signed [NB-1:0]        odd_out_im [0:255],
    output logic                         out_valid,
    output logic                         m_ready
);

    typedef enum logic [2:0] {IDLE, FEED, WAIT_RDY, CAPTURE, BUILD} state_t;

    state_t                        state;
    logic [7:0]                    feed_cnt;
    logic signed [NB-1:0]          fft_res_re [0:255];
    logic signed [NB-1:0]          fft_res_im [0:255];
    logic signed [NB-1:0]          fft_in_dr;
    logic signed [NB-1:0]          fft_in_di;
    logic                           fft_start;
    logic                           fft_rdy;
    logic                           fft_ovf1;
    logic                           fft_ovf2;
    logic [7:0]                    fft_addr;
    logic signed [NB-1:0]          fft256_or;
    logic signed [NB-1:0]          fft256_oi;

    fft256 #(.nb(NB)) fft256_i (
        .CLK(clk),
        .RST(fft_reset),
        .ED(1'b1),
        .START(fft_start),
        .SHIFT(4'd0),
        .DR(fft_in_dr),
        .DI(fft_in_di),
        .RDY(fft_rdy),
        .OVF1(fft_ovf1),
        .OVF2(fft_ovf2),
        .ADDR(fft_addr),
        .O_fft_real(fft256_or),
        .O_fft_imag(fft256_oi)
    );

    always_ff @(posedge clk or posedge fft_reset) begin
        if (fft_reset) begin
            state      <= IDLE;
            feed_cnt   <= 8'd0;
            out_valid  <= 1'b0;
            m_ready    <= 1'b1;
            fft_start  <= 1'b0;
            fft_in_dr  <= '0;
            fft_in_di  <= '0;
        end else if (reset) begin
            state      <= IDLE;
            feed_cnt   <= 8'd0;
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
                        feed_cnt  <= 8'd0;
                        fft_start <= 1'b1;
                        state     <= FEED;
                        m_ready   <= 1'b0;
                        out_valid <= 1'b0;
                    end
                end
                FEED: begin
                    fft_in_dr <= fft_real_in[{feed_cnt, 1'b0}];
                    fft_in_di <= fft_real_in[{feed_cnt, 1'b1}];
                    feed_cnt <= feed_cnt + 8'd1;
                    if (feed_cnt == 8'd255) begin
                        feed_cnt <= 8'd0;
                        state    <= WAIT_RDY;
                    end
                end
                WAIT_RDY: begin
                    if (fft_rdy) begin
                        feed_cnt <= 8'd0;
                        state    <= CAPTURE;
                    end
                end
                CAPTURE: begin
                    fft_res_re[feed_cnt] <= fft256_or;
                    fft_res_im[feed_cnt] <= fft256_oi;
                    feed_cnt <= feed_cnt + 8'd1;
                    if (feed_cnt == 8'd255) begin
                        feed_cnt <= 8'd0;
                        state    <= BUILD;
                    end
                end
                BUILD: begin
                    for (int i = 0; i < 256; i++) begin
                        logic [7:0] sym;
                        logic signed [NB:0] y_re, y_im, ys_re, ys_im;
                        logic signed [NB:0] tmp_re_1, tmp_im_1, tmp_re_2, tmp_im_2;

                        sym = (i == 0) ? 8'd0 : (8'd0 - i[7:0]);
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
                    end

                    even_out_re[0] <= fft_res_re[0];
                    even_out_im[0] <= '0;
                    odd_out_re[0]  <= fft_res_im[0];
                    odd_out_im[0]  <= '0;

                    out_valid <= 1'b1;
                    m_ready   <= 1'b1;
                    state     <= IDLE;
                end
            endcase
        end
    end

endmodule
