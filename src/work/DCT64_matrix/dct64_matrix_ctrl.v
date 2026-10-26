`timescale 1ns/1ps
// One registered product and one accumulator; register-backed storage.
module dct64_matrix_ctrl (
    input wire clk, rst, s_valid,
    output wire s_ready, m_valid,
    input wire m_ready,
    output reg [5:0] m_index,
    output wire frame_load,
    output wire [5:0] sample_raddr,
    output wire [11:0] coeff_raddr,
    output wire operand_re, product_en, accumulator_clear, accumulator_en,
    output wire result_we, result_re,
    output reg [5:0] result_waddr,
    output wire [5:0] result_raddr
);
    localparam ST_IDLE=0, ST_PRIME=1, ST_MUL=2, ST_MAC=3, ST_STORE=4, ST_OUTPUT=5;
    reg [2:0] state;
    reg [5:0] term_index;
    assign s_ready = (state == ST_IDLE);
    assign m_valid = (state == ST_OUTPUT);
    assign frame_load = s_valid && s_ready;
    // LUT selection, multiplication and accumulation have separate registers.
    // PRIME captures operands 0; MUL captures product 0 and operands 1.
    assign sample_raddr = (state == ST_PRIME) ? 6'd0 :
                          (state == ST_MUL) ? 6'd1 : term_index+6'd2;
    assign coeff_raddr = {result_waddr,sample_raddr};
    assign operand_re = (state == ST_PRIME) || (state == ST_MUL) ||
                        ((state == ST_MAC) && (term_index < 62));
    assign product_en = (state == ST_MUL) || ((state == ST_MAC) && (term_index < 63));
    assign accumulator_clear = (state == ST_PRIME);
    assign accumulator_en = (state == ST_MAC);
    assign result_we = (state == ST_STORE);
    assign result_re = (state == ST_OUTPUT);
    assign result_raddr = m_index;
    always @(posedge clk) begin
        if(rst) begin
            state <= ST_IDLE;
            result_waddr <= 0;
            term_index <= 0;
            m_index <= 0;
        end else case(state)
            ST_IDLE: if(frame_load) begin
                result_waddr <= 0;
                term_index <= 0;
                m_index <= 0;
                state <= ST_PRIME;
            end
            ST_PRIME: begin term_index <= 0; state <= ST_MUL; end
            ST_MUL: state <= ST_MAC;
            ST_MAC: begin
                if(term_index == 63) state <= ST_STORE;
                else term_index <= term_index+6'd1;
            end
            ST_STORE: begin
                if(result_waddr == 63) begin m_index <= 0; state <= ST_OUTPUT; end
                else begin result_waddr <= result_waddr+6'd1; state <= ST_PRIME; end
            end
            ST_OUTPUT: if(m_ready) begin
                if(m_index == 63) state <= ST_IDLE;
                else m_index <= m_index+6'd1;
            end
            default: state <= ST_IDLE;
        endcase
    end
endmodule
