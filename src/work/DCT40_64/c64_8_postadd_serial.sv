// -----------------------------------------------------------------------------
// c64_8_postadd_serial.sv
// -----------------------------------------------------------------------------
// Serial output form of the sparse C_64,8 base-change network.
//
// DIN is captured on START in the same lane order as c64_8_postadd:
//
//   DIN lane (8*i + p) = DCT8 block i output p
//
// After START, m_valid streams DOUT[0]..DOUT[63].  The current output is held
// stable while m_valid && !m_ready.
// -----------------------------------------------------------------------------

`ifndef C64_8_POSTADD_SERIAL_SV
`define C64_8_POSTADD_SERIAL_SV

`timescale 1 ns / 1 ps

module c64_8_postadd_serial #(
    parameter integer IN_W  = 24,
    parameter integer OUT_W = IN_W + 1,
    parameter integer ORTHO_DCT8_INPUT = 0
)(
    input  logic CLK,
    input  logic RST,
    input  logic ED,
    input  logic START,
    input  var logic signed [IN_W-1:0] DIN [0:63],

    output logic signed [OUT_W-1:0] m_data,
    output logic [5:0] m_index,
    output logic m_valid,
    input  logic m_ready,
    output logic RDY
);

    localparam integer SQRT2_FRAC = 14;
    localparam signed [15:0] SQRT2_Q14 = 16'sd23170;
    localparam integer COMP_W = OUT_W + 16;

    logic running;
    logic [5:0] out_idx;
    logic signed [IN_W-1:0] din_hold [0:63];

    function automatic signed [OUT_W-1:0] calc_lane;
        input logic [5:0] idx;
        logic [2:0] q;
        logic [2:0] r;
        int a_idx;
        int b_idx;
        logic signed [COMP_W-1:0] a_scaled_full;
        begin
            q = idx[5:3];
            r = idx[2:0];

            if (r == 3'd0) begin
                calc_lane = din_hold[q];
            end else begin
                a_idx = 8*r + q;

                if (q < 3'd7) begin
                    b_idx = 8*(8-r) + q + 1;

                    if (ORTHO_DCT8_INPUT && (q == 3'd0)) begin
                        a_scaled_full = din_hold[a_idx] * SQRT2_Q14;
                        calc_lane = (a_scaled_full >>> SQRT2_FRAC) + din_hold[b_idx];
                    end else begin
                        calc_lane = din_hold[a_idx] + din_hold[b_idx];
                    end
                end else begin
                    calc_lane = din_hold[a_idx];
                end
            end
        end
    endfunction

    always_comb begin
        m_data = calc_lane(out_idx);
        m_index = out_idx;
    end

    always_ff @(posedge CLK) begin
        if (RST) begin
            running <= 1'b0;
            out_idx <= 6'd0;
            m_valid <= 1'b0;
            RDY <= 1'b0;
            for (int i = 0; i < 64; i = i + 1) begin
                din_hold[i] <= '0;
            end
        end else if (ED) begin
            RDY <= 1'b0;

            if (START) begin
                running <= 1'b1;
                out_idx <= 6'd0;
                m_valid <= 1'b1;
                for (int i = 0; i < 64; i = i + 1) begin
                    din_hold[i] <= DIN[i];
                end
            end else if (running && m_valid && m_ready) begin
                if (out_idx == 6'd63) begin
                    running <= 1'b0;
                    m_valid <= 1'b0;
                    RDY <= 1'b1;
                end else begin
                    out_idx <= out_idx + 6'd1;
                end
            end
        end
    end

endmodule

`endif
