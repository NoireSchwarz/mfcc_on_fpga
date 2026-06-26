// -----------------------------------------------------------------------------
// skewdct8_tdm.sv
// -----------------------------------------------------------------------------
// Parallel-input, serial-output, time-multiplexed eight-block skew DCT-II bank.
//
// One dynamic-coefficient 8x8 skew DCT engine is reused for the eight skew
// blocks.  Input array order is the old DIN lane order:
//
//   lane 8*b + j = input j of skew block b
//
// Output stream order is the old DOUT lane order consumed by the following DCT8
// layer:
//
//   m_index 8*k + b = skew block b output k
// -----------------------------------------------------------------------------

`ifndef SKEWDCT8_TDM_SV
`define SKEWDCT8_TDM_SV

`timescale 1 ns / 1 ps

module skewdct8_dctii_tdm_bank #(
    parameter integer DATA_W    = 16,
    parameter integer COEF_W    = 20,
    parameter integer COEF_FRAC = 14,
    parameter integer ACC_W     = 48,
    parameter integer OUT_W     = 24
)(
    input  logic CLK,
    input  logic RST,
    input  logic ED,
    input  logic START,

    input  var logic signed [DATA_W-1:0] DIN [0:63],

    output logic signed [OUT_W-1:0] m_data,
    output logic [5:0] m_index,
    output logic m_valid,
    input  logic m_ready,

    output logic RDY
);

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_RUN,
        ST_OUTPUT
    } state_t;

    state_t state;

    logic [2:0] block_idx;
    logic [5:0] out_idx;

    logic signed [OUT_W-1:0] dout_hold [0:63];
    logic signed [DATA_W-1:0] skew_x [0:7];
    logic signed [OUT_W-1:0] skew_y [0:7];

    genvar gi;
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : GEN_SKEW_X
            assign skew_x[gi] = DIN[{block_idx, gi[2:0]}];
        end
    endgenerate

    skewdct8_dctii_dyn #(
        .DATA_W(DATA_W),
        .COEF_W(COEF_W),
        .COEF_FRAC(COEF_FRAC),
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) U_SKEW_DYN (
        .BLOCK(block_idx),
        .X(skew_x),
        .Y(skew_y)
    );

    assign m_valid = (state == ST_OUTPUT);

    always_comb begin
        m_index = out_idx;
        m_data = dout_hold[out_idx];
    end

    always_ff @(posedge CLK) begin
        if (RST) begin
            state <= ST_IDLE;
            block_idx <= 3'd0;
            out_idx <= 6'd0;
            RDY <= 1'b0;
            for (int i = 0; i < 64; i = i + 1) begin
                dout_hold[i] <= '0;
            end
        end else if (ED) begin
            RDY <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (START) begin
                        block_idx <= 3'd0;
                        state <= ST_RUN;
                    end
                end

                ST_RUN: begin
                    for (int k = 0; k < 8; k = k + 1) begin
                        dout_hold[{k[2:0], block_idx}] <= skew_y[k];
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

module skewdct8_dctii_coeff_rom #(
    parameter integer COEF_W = 20
)(
    input  logic [2:0] BLOCK,
    output logic signed [COEF_W-1:0] C [0:7][0:7]
);

    localparam integer ROM_W = 20;
    logic signed [ROM_W-1:0] coeff_mem [0:511];

    initial begin
        $readmemh("work/skewdct8_coeff_rom.mem", coeff_mem);
    end

    function automatic int coeff_addr;
        input logic [2:0] block;
        input int row;
        input int col;
        begin
            coeff_addr = (int'(block) * 64) + (row * 8) + col;
        end
    endfunction

    always_comb begin
        for (int row = 0; row < 8; row = row + 1) begin
            for (int col = 0; col < 8; col = col + 1) begin
                C[row][col] = coeff_mem[coeff_addr(BLOCK, row, col)];
            end
        end
    end

endmodule
module skewdct8_dctii_dyn #(
    parameter integer DATA_W    = 16,
    parameter integer COEF_W    = 20,
    parameter integer COEF_FRAC = 14,
    parameter integer ACC_W     = 48,
    parameter integer OUT_W     = 24
)(
    input  logic [2:0] BLOCK,
    input  var logic signed [DATA_W-1:0] X [0:7],
    output logic signed [OUT_W-1:0] Y [0:7]
);

    logic signed [COEF_W-1:0] coeff [0:7][0:7];

    skewdct8_dctii_coeff_rom #(
        .COEF_W(COEF_W)
    ) U_COEFF_ROM (
        .BLOCK(BLOCK),
        .C(coeff)
    );

    skewdct8 #(
        .DATA_W(DATA_W),
        .COEF_W(COEF_W),
        .COEF_FRAC(COEF_FRAC),
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .USE_COEFF_PORT(1)
    ) U_SKEWDCT8 (
        .x0(X[0]),
        .x1(X[1]),
        .x2(X[2]),
        .x3(X[3]),
        .x4(X[4]),
        .x5(X[5]),
        .x6(X[6]),
        .x7(X[7]),
        .y0(Y[0]),
        .y1(Y[1]),
        .y2(Y[2]),
        .y3(Y[3]),
        .y4(Y[4]),
        .y5(Y[5]),
        .y6(Y[6]),
        .y7(Y[7]),
        .c_in(coeff)
    );

endmodule

`endif
