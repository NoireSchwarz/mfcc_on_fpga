// -----------------------------------------------------------------------------
// dct64.sv
// -----------------------------------------------------------------------------
// 40-point input wrapper around the DCT64 scheduler.
//
// The public interface accepts a 40-lane block handshake.  The wrapper extends
// the tail to 64 samples by holding the last input sample, then dct64_serial
// streams the 64 DCT outputs back to this wrapper.
// -----------------------------------------------------------------------------

`ifndef DCT64_SV
`define DCT64_SV

`timescale 1 ns / 1 ps

module dct64 #(
    parameter int DATA_W     = 16,
    parameter int SKEW_OUT_W = 24,
    parameter int C_OUT_W    = SKEW_OUT_W + 2
)(
    input  logic clk,
    input  logic rst,
    input  logic [3:0] shift,

    input  var logic signed [DATA_W-1:0] s_data [0:39],
    input  logic s_valid,
    output logic s_ready,

    output logic signed [C_OUT_W-1:0] m_data [0:63],
    output logic m_valid,
    input  logic m_ready,

    output logic ovf_skew,
    output logic ovf_dct
);

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_RECV_WAIT,
        ST_RECV,
        ST_OUT
    } state_t;

    state_t state;

    logic serial_s_valid;
    logic serial_s_ready;
    logic signed [DATA_W-1:0] serial_s_data [0:63];

    logic signed [C_OUT_W-1:0] serial_m_data;
    logic [5:0] serial_m_index;
    logic serial_m_valid;
    logic serial_m_ready;
    logic serial_ovf_skew;
    logic serial_ovf_dct;

    assign s_ready = (state == ST_IDLE) && serial_s_ready;
    assign serial_s_valid = (state == ST_IDLE) && s_valid;
    assign serial_m_ready = (state == ST_RECV);

    always_comb begin
    for (int i = 0; i < 64; i = i + 1) begin
        serial_s_data[i] = (i < 40) ? s_data[i] : s_data[39];
    end
end

    dct64_serial #(
        .DATA_W(DATA_W),
        .SKEW_OUT_W(SKEW_OUT_W),
        .C_OUT_W(C_OUT_W)
    ) U_SERIAL (
        .clk(clk),
        .rst(rst),
        .shift(shift),
        .s_data(serial_s_data),
        .s_valid(serial_s_valid),
        .s_ready(serial_s_ready),
        .m_data(serial_m_data),
        .m_index(serial_m_index),
        .m_valid(serial_m_valid),
        .m_ready(serial_m_ready),
        .ovf_skew(serial_ovf_skew),
        .ovf_dct(serial_ovf_dct)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
            m_valid <= 1'b0;
            ovf_skew <= 1'b0;
            ovf_dct <= 1'b0;
            for (int i = 0; i < 64; i = i + 1) begin
                m_data[i] <= '0;
            end
        end else begin
            case (state)
                ST_IDLE: begin
                    m_valid <= 1'b0;
                    if (s_valid && s_ready) begin
                        state <= ST_RECV_WAIT;
                    end
                end

                ST_RECV_WAIT: begin
                    if (serial_m_valid) begin
                        state <= ST_RECV;
                    end
                end

                ST_RECV: begin
                    if (serial_m_valid) begin
                        m_data[serial_m_index] <= serial_m_data;

                        if (serial_m_index == 6'd63) begin
                            ovf_skew <= serial_ovf_skew;
                            ovf_dct <= serial_ovf_dct;
                            m_valid <= 1'b1;
                            state <= ST_OUT;
                        end
                    end
                end

                ST_OUT: begin
                    if (m_ready) begin
                        m_valid <= 1'b0;
                        state <= ST_IDLE;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                    m_valid <= 1'b0;
                end
            endcase
        end
    end

endmodule

`endif
