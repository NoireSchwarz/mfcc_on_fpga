// -----------------------------------------------------------------------------
// dct64_serial.sv
// -----------------------------------------------------------------------------
// Block-input, serial-output DCT64 scheduler.
//
// The datapath keeps the original 64-lane input block through the skew
// permutation and first skew-DCT bank, then streams the later stages:
//
//   SKEW_BUFRAM64
//     -> skewdct8_dctii_tdm_bank
//     -> NORM
//     -> dct8_tdm_bank
//     -> NORM
//     -> c64_8_postadd_serial
// -----------------------------------------------------------------------------

`ifndef DCT64_SERIAL_SV
`define DCT64_SERIAL_SV

`timescale 1 ns / 1 ps

module dct64_serial #(
    parameter int DATA_W     = 16,
    parameter int SKEW_OUT_W = 24,
    parameter int C_OUT_W    = SKEW_OUT_W + 2
)(
    input  logic clk,
    input  logic rst,
    input  logic [3:0] shift,

    input  var logic signed [DATA_W-1:0] s_data [0:63],
    input  logic s_valid,
    output logic s_ready,

    output logic signed [C_OUT_W-1:0] m_data,
    output logic [5:0] m_index,
    output logic m_valid,
    input  logic m_ready,

    output logic ovf_skew,
    output logic ovf_dct
);

    localparam integer SKEW_NORM_W = SKEW_OUT_W - 2;
    localparam integer DCT_OUT_W   = SKEW_NORM_W + 4;

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_WAIT_SKEW,
        ST_SKEW_NORM,
        ST_DCT_NORM,
        ST_OUTPUT
    } state_t;

    state_t state;

    logic signed [SKEW_NORM_W-1:0] norm_skew_dout;
    logic norm_skew_ed;
    logic norm_skew_start;
    logic norm_skew_ovf;
    logic norm_skew_rdy;
    logic skew_norm_valid;
    logic skew_norm_last;

    logic signed [SKEW_NORM_W-1:0] dct_s_data;
    logic dct_s_valid;
    logic dct_s_ready;

    logic [5:0] dct_norm_index;
    logic signed [SKEW_OUT_W-1:0] norm_dct_dout;
    logic norm_dct_ed;
    logic norm_dct_start;
    logic norm_dct_ovf;
    logic norm_dct_rdy;
    logic dct_norm_valid;
    logic dct_norm_last;

    logic signed [SKEW_OUT_W-1:0] dct_norm_buf [0:63];

    logic signed [DATA_W-1:0] input_hold [0:63];
    logic signed [DATA_W-1:0] skew_input [0:63];

    logic skew_start;
    logic signed [SKEW_OUT_W-1:0] skew_m_data;
    logic [5:0] skew_m_index;
    logic skew_m_valid;
    logic skew_m_ready;
    logic skew_rdy;

    logic dct_start;
    logic signed [DCT_OUT_W-1:0] dct_m_data;
    logic [5:0] dct_m_index;
    logic dct_m_valid;
    logic dct_m_ready;
    logic dct_rdy;

    logic c64_start;
    logic c64_ready;
    logic c64_rdy;

    logic d_skew_start;
    logic q_skew_start;
    logic d_dct_start;
    logic q_dct_start;
    logic d_c64_start;
    logic q_c64_start;

    SKEW_BUFRAM64 #(
        .DATA_W(DATA_W)
    ) U_SKEW_BUF (
        .DIN(input_hold),
        .DOUT(skew_input)
    );

    skewdct8_dctii_tdm_bank #(
        .DATA_W(DATA_W),
        .OUT_W(SKEW_OUT_W)
    ) U_SKEW_TDM (
        .CLK(clk),
        .RST(rst),
        .ED(1'b1),
        .START(skew_start),
        .DIN(skew_input),
        .m_data(skew_m_data),
        .m_index(skew_m_index),
        .m_valid(skew_m_valid),
        .m_ready(skew_m_ready),
        .RDY(skew_rdy)
    );

    NORM #(SKEW_OUT_W - 4) U_NORM_SKEW (
        .CLK(clk),
        .ED(norm_skew_ed),
        .START(norm_skew_start),
        .DIN(skew_m_data),
        .SHIFT(shift[1:0]),
        .OVF(norm_skew_ovf),
        .RDY(norm_skew_rdy),
        .DOUT(norm_skew_dout)
    );

    dct8_tdm_bank #(
        .IN_W(SKEW_NORM_W),
        .OUT_W(DCT_OUT_W)
    ) U_DCT_TDM (
        .CLK(clk),
        .RST(rst),
        .ED(1'b1),
        .START(dct_start),
        .s_data(dct_s_data),
        .s_valid(dct_s_valid),
        .s_ready(dct_s_ready),
        .m_data(dct_m_data),
        .m_index(dct_m_index),
        .m_valid(dct_m_valid),
        .m_ready(dct_m_ready),
        .RDY(dct_rdy)
    );

    NORM #(DCT_OUT_W - 4) U_NORM_DCT (
        .CLK(clk),
        .ED(norm_dct_ed),
        .START(norm_dct_start),
        .DIN(dct_m_data),
        .SHIFT(shift[3:2]),
        .OVF(norm_dct_ovf),
        .RDY(norm_dct_rdy),
        .DOUT(norm_dct_dout)
    );

    c64_8_postadd_serial #(
        .IN_W(SKEW_OUT_W),
        .OUT_W(C_OUT_W),
        .ORTHO_DCT8_INPUT(1)
    ) U_C64_8 (
        .CLK(clk),
        .RST(rst),
        .ED(1'b1),
        .START(c64_start),
        .DIN(dct_norm_buf),
        .m_data(m_data),
        .m_index(m_index),
        .m_valid(m_valid),
        .m_ready(c64_ready),
        .RDY(c64_rdy)
    );

    assign s_ready = (state == ST_IDLE);

    assign skew_start = q_skew_start;
    assign skew_m_ready = (state == ST_SKEW_NORM);

    assign norm_skew_ed = skew_m_valid && skew_m_ready;
    assign norm_skew_start = norm_skew_ed && (skew_m_index == 6'd0);

    assign dct_start = q_dct_start;
    assign dct_s_data = norm_skew_dout;
    assign dct_s_valid = skew_norm_valid;

    assign dct_m_ready = (state == ST_DCT_NORM);
    assign norm_dct_ed = dct_m_valid && dct_m_ready;
    assign norm_dct_start = norm_dct_ed && (dct_m_index == 6'd0);

    assign c64_start = q_c64_start;
    assign c64_ready = (state == ST_OUTPUT) && m_ready;

    always_comb begin
        d_skew_start = 1'b0;
        d_dct_start = 1'b0;
        d_c64_start = 1'b0;

        if ((state == ST_IDLE) && s_valid && s_ready) begin
            d_skew_start = 1'b1;
        end

        if ((state == ST_WAIT_SKEW) && skew_m_valid) begin
            d_dct_start = 1'b1;
        end

        if ((state == ST_DCT_NORM) && dct_norm_valid && dct_norm_last) begin
            d_c64_start = 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
            dct_norm_index <= 6'd0;
            skew_norm_valid <= 1'b0;
            skew_norm_last <= 1'b0;
            dct_norm_valid <= 1'b0;
            dct_norm_last <= 1'b0;
            q_skew_start <= 1'b0;
            q_dct_start <= 1'b0;
            q_c64_start <= 1'b0;
            ovf_skew <= 1'b0;
            ovf_dct <= 1'b0;
            for (int i = 0; i < 64; i = i + 1) begin
                input_hold[i] <= '0;
                dct_norm_buf[i] <= '0;
            end
        end else begin
            q_skew_start <= d_skew_start;
            q_dct_start <= d_dct_start;
            q_c64_start <= d_c64_start;

            skew_norm_valid <= norm_skew_ed;
            if (norm_skew_ed) begin
                skew_norm_last <= (skew_m_index == 6'd63);
            end

            dct_norm_valid <= norm_dct_ed;
            if (norm_dct_ed) begin
                dct_norm_index <= dct_m_index;
                dct_norm_last <= (dct_m_index == 6'd63);
            end

            case (state)
                ST_IDLE: begin
                    ovf_skew <= 1'b0;
                    ovf_dct <= 1'b0;
                    if (s_valid && s_ready) begin
                        for (int i = 0; i < 64; i = i + 1) begin
                            input_hold[i] <= s_data[i];
                        end
                        state <= ST_WAIT_SKEW;
                    end
                end

                ST_WAIT_SKEW: begin
                    if (skew_m_valid) begin
                        state <= ST_SKEW_NORM;
                    end
                end

                ST_SKEW_NORM: begin
                    if (skew_norm_valid) begin
                        ovf_skew <= ovf_skew | norm_skew_ovf;
                        if (skew_norm_last) begin
                            state <= ST_DCT_NORM;
                        end
                    end
                end

                ST_DCT_NORM: begin
                    if (dct_norm_valid) begin
                        dct_norm_buf[dct_norm_index] <= norm_dct_dout;
                        ovf_dct <= ovf_dct | norm_dct_ovf;
                        if (dct_norm_last) begin
                            state <= ST_OUTPUT;
                        end
                    end
                end

                ST_OUTPUT: begin
                    if (c64_rdy) begin
                        state <= ST_IDLE;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule

`endif
