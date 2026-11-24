// Board-test wrapper only. The FFT implementation is the unmodified fft512
// hierarchy from Git commit 9be89af18ca9cf42e6f47990d7d1b781afb47615.
module bench_transform #(
    parameter integer KIND=0,
    parameter integer N=2048
)(
    (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 clk CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME clk, ASSOCIATED_BUSIF S_AXIS:M_AXIS, ASSOCIATED_RESET resetn, FREQ_HZ 150000000" *)
    input clk,
    (* X_INTERFACE_INFO="xilinx.com:signal:reset:1.0 resetn RST", X_INTERFACE_PARAMETER="XIL_INTERFACENAME resetn, POLARITY ACTIVE_LOW" *)
    input resetn,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 S_AXIS TDATA" *) input [15:0] s_axis_tdata,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 S_AXIS TVALID" *) input s_axis_tvalid,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 S_AXIS TREADY" *) output s_axis_tready,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 M_AXIS TDATA" *) output [31:0] m_axis_tdata,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 M_AXIS TVALID" *) output m_axis_tvalid,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 M_AXIS TREADY" *) input m_axis_tready,
    (* X_INTERFACE_INFO="xilinx.com:interface:axis:1.0 M_AXIS TLAST" *) output m_axis_tlast,
    output [31:0] error_flags
);
    assign error_flags=32'd0;
    fft512 #(.N(N),.HALF_SPECTRUM(0)) dut(
        .clk(clk),.reset(!resetn),
        .s_data(s_axis_tdata),.s_valid(s_axis_tvalid),.s_ready(s_axis_tready),
        .m_data(m_axis_tdata),.m_valid(m_axis_tvalid),
        .m_ready(m_axis_tready),.m_last(m_axis_tlast));
endmodule
