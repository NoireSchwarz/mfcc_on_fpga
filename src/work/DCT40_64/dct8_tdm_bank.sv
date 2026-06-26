// -----------------------------------------------------------------------------
// dct8_tdm_bank.sv
// -----------------------------------------------------------------------------
// Serial-I/O, time-multiplexed 8-block DCT-II bank.
//
// Input stream order is the old array lane order:
//
//   lane 8*i + j = sample j of DCT8 block i
//
// Output stream order is also the old DOUT lane order:
//
//   m_index 8*i + j = DCT8 block i output j
// -----------------------------------------------------------------------------

`ifndef DCT8_TDM_BANK_SV
`define DCT8_TDM_BANK_SV

`timescale 1 ns / 1 ps

module dct8_tdm_bank #(
    parameter integer IN_W  = 24,
    parameter integer OUT_W = IN_W + 4
)(
    input  logic CLK,
    input  logic RST,
    input  logic ED,
    input  logic START,

    input  logic signed [IN_W-1:0] s_data,
    input  logic s_valid,
    output logic s_ready,

    output logic signed [OUT_W-1:0] m_data,
    output logic [5:0] m_index,
    output logic m_valid,
    input  logic m_ready,

    output logic RDY
);

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_INPUT,
        ST_RUN,
        ST_OUTPUT
    } state_t;

    state_t state;

    logic [5:0] input_idx;
    logic [2:0] block_idx;
    logic [5:0] out_idx;

    logic signed [IN_W-1:0] din_hold [0:63];
    logic signed [OUT_W-1:0] dout_hold [0:63];
    logic signed [IN_W-1:0] dct_x [0:7];
    wire signed [OUT_W-1:0] dct_y [0:7];

    genvar gi;
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : GEN_DCT_X
            assign dct_x[gi] = din_hold[{block_idx, gi[2:0]}];
        end
    endgenerate

    dct8_parallel #(
        .IN_W(IN_W),
        .OUT_W(OUT_W)
    ) U_DCT8 (
        .x0(dct_x[0]),
        .x1(dct_x[1]),
        .x2(dct_x[2]),
        .x3(dct_x[3]),
        .x4(dct_x[4]),
        .x5(dct_x[5]),
        .x6(dct_x[6]),
        .x7(dct_x[7]),
        .y0(dct_y[0]),
        .y1(dct_y[1]),
        .y2(dct_y[2]),
        .y3(dct_y[3]),
        .y4(dct_y[4]),
        .y5(dct_y[5]),
        .y6(dct_y[6]),
        .y7(dct_y[7])
    );

    assign s_ready = (state == ST_INPUT);
    assign m_valid = (state == ST_OUTPUT);

    always_comb begin
        m_index = out_idx;
        m_data = dout_hold[out_idx];
    end

    always_ff @(posedge CLK) begin
        if (RST) begin
            state <= ST_IDLE;
            input_idx <= 6'd0;
            block_idx <= 3'd0;
            out_idx <= 6'd0;
            RDY <= 1'b0;
            for (int i = 0; i < 64; i = i + 1) begin
                din_hold[i] <= '0;
                dout_hold[i] <= '0;
            end
        end else if (ED) begin
            RDY <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (START) begin
                        input_idx <= 6'd0;
                        state <= ST_INPUT;
                    end
                end

                ST_INPUT: begin
                    if (s_valid && s_ready) begin
                        din_hold[input_idx] <= s_data;

                        if (input_idx == 6'd63) begin
                            input_idx <= 6'd0;
                            block_idx <= 3'd0;
                            state <= ST_RUN;
                        end else begin
                            input_idx <= input_idx + 6'd1;
                        end
                    end
                end

                ST_RUN: begin
                    for (int k = 0; k < 8; k = k + 1) begin
                        dout_hold[{block_idx, k[2:0]}] <= dct_y[k];
                    end

                    if (block_idx == 3'd7) begin
                        out_idx <= 6'd0;
                        state <= ST_OUTPUT;
                    end else begin
                        block_idx <= block_idx + 3'd1;
                    end
                end

                ST_OUTPUT: begin
                    if (m_valid && m_ready) begin
                        if (out_idx == 6'd63) begin
                            out_idx <= 6'd0;
                            RDY <= 1'b1;
                            state <= ST_IDLE;
                        end else begin
                            out_idx <= out_idx + 6'd1;
                        end
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
