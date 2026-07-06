`timescale 1ns / 1ps

module fft_merge_kernel #(
    parameter int NB = 16,
    parameter int TW = 16
)(
    input  logic                         clk,
    input  logic                         rst,
    input  logic                         start,
    input  logic [1:0]                   mode,

    input  logic signed [NB-1:0]         x0_re,
    input  logic signed [NB-1:0]         x0_im,
    input  logic signed [NB-1:0]         x1_re,
    input  logic signed [NB-1:0]         x1_im,
    input  logic signed [NB-1:0]         x2_re,
    input  logic signed [NB-1:0]         x2_im,
    input  logic signed [NB-1:0]         x3_re,
    input  logic signed [NB-1:0]         x3_im,

    input  logic signed [TW-1:0]         w1_re,
    input  logic signed [TW-1:0]         w1_im,
    input  logic signed [TW-1:0]         w2_re,
    input  logic signed [TW-1:0]         w2_im,
    input  logic signed [TW-1:0]         w3_re,
    input  logic signed [TW-1:0]         w3_im,

    output logic                         valid,
    output logic                         busy,
    output logic signed [NB-1:0]         y0_re,
    output logic signed [NB-1:0]         y0_im,
    output logic signed [NB-1:0]         y1_re,
    output logic signed [NB-1:0]         y1_im,
    output logic signed [NB-1:0]         y2_re,
    output logic signed [NB-1:0]         y2_im,
    output logic signed [NB-1:0]         y3_re,
    output logic signed [NB-1:0]         y3_im
);

    localparam logic [1:0] MODE_ROT_ONLY = 2'd0;
    localparam logic [1:0] MODE_RADIX2   = 2'd1;
    localparam logic [1:0] MODE_RADIX4   = 2'd2;

    typedef enum logic [2:0] {
        IDLE,
        CAPTURE_1,
        CAPTURE_2,
        CAPTURE_3,
        FINISH_R4
    } state_t;

    state_t state;
    logic [1:0] mode_q;

    logic signed [NB-1:0] b0_re;
    logic signed [NB-1:0] b0_im;
    logic signed [NB-1:0] mul_x_re;
    logic signed [NB-1:0] mul_x_im;
    logic signed [TW-1:0] mul_w_re;
    logic signed [TW-1:0] mul_w_im;

    logic signed [63:0] rot_re;
    logic signed [63:0] rot_im;
    logic signed [63:0] b1_re;
    logic signed [63:0] b1_im;
    logic signed [63:0] b2_re;
    logic signed [63:0] b2_im;
    logic signed [63:0] b3_re;
    logic signed [63:0] b3_im;

    logic signed [63:0] mul_re;
    logic signed [63:0] mul_im;

    complex_twiddle_mul #(
        .NB(NB),
        .TW(TW),
        .OUTW(64),
        .SHIFT(TW - 1),
        .SHIFT_AFTER_SUM(1'b1)
    ) mul_i (
        .x_re(mul_x_re),
        .x_im(mul_x_im),
        .w_re(mul_w_re),
        .w_im(mul_w_im),
        .y_re(mul_re),
        .y_im(mul_im)
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

    task automatic write_r4_outputs;
        logic signed [63:0] p0_re;
        logic signed [63:0] p0_im;
        logic signed [63:0] p1_re;
        logic signed [63:0] p1_im;
        logic signed [63:0] p2_re;
        logic signed [63:0] p2_im;
        logic signed [63:0] p3_re;
        logic signed [63:0] p3_im;
        begin
            p0_re = $signed({{(64-NB){b0_re[NB-1]}}, b0_re}) + b2_re;
            p0_im = $signed({{(64-NB){b0_im[NB-1]}}, b0_im}) + b2_im;
            p1_re = $signed({{(64-NB){b0_re[NB-1]}}, b0_re}) - b2_re;
            p1_im = $signed({{(64-NB){b0_im[NB-1]}}, b0_im}) - b2_im;
            p2_re = b1_re + b3_re;
            p2_im = b1_im + b3_im;
            p3_re = b1_re - b3_re;
            p3_im = b1_im - b3_im;

            y0_re <= sat_nb(p0_re + p2_re);
            y0_im <= sat_nb(p0_im + p2_im);
            y2_re <= sat_nb(p0_re - p2_re);
            y2_im <= sat_nb(p0_im - p2_im);
            y1_re <= sat_nb(p1_re + p3_im);
            y1_im <= sat_nb(p1_im - p3_re);
            y3_re <= sat_nb(p1_re - p3_im);
            y3_im <= sat_nb(p1_im + p3_re);
        end
    endtask

    always_ff @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            valid    <= 1'b0;
            busy     <= 1'b0;
            mode_q   <= MODE_ROT_ONLY;
            b0_re    <= '0;
            b0_im    <= '0;
            mul_x_re <= '0;
            mul_x_im <= '0;
            mul_w_re <= '0;
            mul_w_im <= '0;
            b1_re    <= '0;
            b1_im    <= '0;
            b2_re    <= '0;
            b2_im    <= '0;
            b3_re    <= '0;
            b3_im    <= '0;
            y0_re    <= '0;
            y0_im    <= '0;
            y1_re    <= '0;
            y1_im    <= '0;
            y2_re    <= '0;
            y2_im    <= '0;
            y3_re    <= '0;
            y3_im    <= '0;
        end else begin
            valid <= 1'b0;

            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        busy   <= 1'b1;
                        mode_q <= mode;
                        b0_re  <= x0_re;
                        b0_im  <= x0_im;

                        if (mode == MODE_ROT_ONLY) begin
                            mul_x_re <= x0_re;
                            mul_x_im <= x0_im;
                        end else begin
                            mul_x_re <= x1_re;
                            mul_x_im <= x1_im;
                        end
                        mul_w_re <= w1_re;
                        mul_w_im <= w1_im;
                        state    <= CAPTURE_1;
                    end
                end

                CAPTURE_1: begin
                    rot_re <= mul_re;
                    rot_im <= mul_im;
                    b1_re  <= mul_re;
                    b1_im  <= mul_im;

                    if (mode_q == MODE_ROT_ONLY) begin
                        y0_re <= sat_nb(mul_re);
                        y0_im <= sat_nb(mul_im);
                        valid <= 1'b1;
                        busy  <= 1'b0;
                        state <= IDLE;
                    end else if (mode_q == MODE_RADIX2) begin
                        y0_re <= sat_nb($signed({{(64-NB){b0_re[NB-1]}}, b0_re}) + mul_re);
                        y0_im <= sat_nb($signed({{(64-NB){b0_im[NB-1]}}, b0_im}) + mul_im);
                        y1_re <= sat_nb($signed({{(64-NB){b0_re[NB-1]}}, b0_re}) - mul_re);
                        y1_im <= sat_nb($signed({{(64-NB){b0_im[NB-1]}}, b0_im}) - mul_im);
                        valid <= 1'b1;
                        busy  <= 1'b0;
                        state <= IDLE;
                    end else begin
                        mul_x_re <= x2_re;
                        mul_x_im <= x2_im;
                        mul_w_re <= w2_re;
                        mul_w_im <= w2_im;
                        state    <= CAPTURE_2;
                    end
                end

                CAPTURE_2: begin
                    b2_re    <= mul_re;
                    b2_im    <= mul_im;
                    mul_x_re <= x3_re;
                    mul_x_im <= x3_im;
                    mul_w_re <= w3_re;
                    mul_w_im <= w3_im;
                    state    <= CAPTURE_3;
                end

                CAPTURE_3: begin
                    b3_re <= mul_re;
                    b3_im <= mul_im;
                    state <= FINISH_R4;
                end

                FINISH_R4: begin
                    write_r4_outputs();
                    valid <= 1'b1;
                    busy  <= 1'b0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
