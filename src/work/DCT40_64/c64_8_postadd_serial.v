`timescale 1ns/1ps
// Three registered stages: operand selection, compensation product, post-add/output.
// ED freezes the complete pipeline. Output backpressure stalls all stages together.
module c64_8_postadd_serial (
    CLK, RST, ED, START, DIN,
    m_data, m_index, m_valid, m_ready, RDY
);
    parameter integer IN_W = 24;
    parameter integer OUT_W = IN_W + 1;
    parameter integer ORTHO_DCT8_INPUT = 0;
    input wire CLK;
    input wire RST;
    input wire ED;
    input wire START;
    input wire signed [(64 * IN_W) - 1:0] DIN;
    output reg signed [OUT_W - 1:0] m_data;
    output reg [5:0] m_index;
    output reg m_valid;
    input wire m_ready;
    output reg RDY;

    localparam integer SQRT2_FRAC = 14;
    localparam signed [15:0] SQRT2_Q14 = 16'sd23170;
    localparam integer COMP_W = OUT_W + 16;
    reg running;
    reg [5:0] issue_idx;
    reg issue_done;
    reg signed [IN_W - 1:0] din_hold [0:63];
    reg valid_s0, valid_s1;
    reg [5:0] index_s0, index_s1;
    reg add_s0, add_s1, scale_s0, scale_s1;
    reg signed [IN_W - 1:0] a_s0, b_s0, a_s1, b_s1;
    reg signed [COMP_W - 1:0] product_s1;

    wire advance = ED && (!m_valid || m_ready);
    wire issue_valid = running && !issue_done;
    wire [2:0] q = issue_idx[5:3];
    wire [2:0] r = issue_idx[2:0];
    wire [2:0] mirror_r = 3'd0 - r;
    wire [2:0] next_q = q + 3'd1;
    wire [5:0] a_addr = (r == 3'd0) ? {3'd0, q} : {r, q};
    // For the active add branch r!=0 and q<7, this equals 8*(8-r)+q+1.
    wire [5:0] b_addr = {mirror_r, next_q};
    wire add_lane = (r != 3'd0) && (q != 3'd7);
    wire scale_lane = (ORTHO_DCT8_INPUT != 0) && add_lane && (q == 3'd0);
    integer i;

    always @(posedge CLK) begin
        if (RST) begin
            running <= 1'b0;
            issue_idx <= 6'd0;
            issue_done <= 1'b0;
            valid_s0 <= 1'b0;
            valid_s1 <= 1'b0;
            index_s0 <= 6'd0;
            index_s1 <= 6'd0;
            add_s0 <= 1'b0;
            add_s1 <= 1'b0;
            scale_s0 <= 1'b0;
            scale_s1 <= 1'b0;
            m_data <= {OUT_W{1'b0}};
            m_index <= 6'd0;
            m_valid <= 1'b0;
            RDY <= 1'b0;
            for (i = 0; i < 64; i = i + 1)
                din_hold[i] <= {IN_W{1'b0}};
        end else if (ED) begin
            RDY <= 1'b0;
            if (START) begin
                // Match the original enabled START priority: replace any active frame.
                running <= 1'b1;
                issue_idx <= 6'd0;
                issue_done <= 1'b0;
                valid_s0 <= 1'b0;
                valid_s1 <= 1'b0;
                m_valid <= 1'b0;
                for (i = 0; i < 64; i = i + 1)
                    din_hold[i] <= DIN[(63 - i) * IN_W+:IN_W];
            end else if (advance) begin
                // S0: isolate indexed selection from the compensation multiplier.
                valid_s0 <= issue_valid;
                if (issue_valid) begin
                    a_s0 <= din_hold[a_addr];
                    b_s0 <= din_hold[b_addr];
                    index_s0 <= issue_idx;
                    add_s0 <= add_lane;
                    scale_s0 <= scale_lane;
                    if (issue_idx == 6'd63)
                        issue_done <= 1'b1;
                    else
                        issue_idx <= issue_idx + 6'd1;
                end

                // S1: register the full signed product and matching operand/control delays.
                valid_s1 <= valid_s0;
                if (valid_s0) begin
                    if (scale_s0)
                        product_s1 <= a_s0 * SQRT2_Q14;
                    a_s1 <= a_s0;
                    b_s1 <= b_s0;
                    index_s1 <= index_s0;
                    add_s1 <= add_s0;
                    scale_s1 <= scale_s0;
                end

                // S2: retain the original truncating shift and signed output assignment.
                // No rounding bias or saturation is introduced.
                m_valid <= valid_s1;
                if (valid_s1) begin
                    if (scale_s1)
                        m_data <= (product_s1 >>> SQRT2_FRAC) + b_s1;
                    else if (add_s1)
                        m_data <= a_s1 + b_s1;
                    else
                        m_data <= a_s1;
                    m_index <= index_s1;
                end

                // Completion follows acceptance of the final output, not its issue.
                if (m_valid && m_ready && (m_index == 6'd63)) begin
                    running <= 1'b0;
                    RDY <= 1'b1;
                end
            end
        end
    end
endmodule
