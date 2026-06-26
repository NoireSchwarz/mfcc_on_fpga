`timescale 1 ns / 1 ps

module tb_dct64_serial_smoke;
    localparam int DATA_W = 16;
    localparam int SKEW_OUT_W = 24;
    localparam int C_OUT_W = SKEW_OUT_W + 2;

    logic clk;
    logic rst;
    logic [3:0] shift;
    logic signed [DATA_W-1:0] s_data [0:63];
    logic s_valid;
    logic s_ready;
    logic signed [C_OUT_W-1:0] m_data;
    logic [5:0] m_index;
    logic m_valid;
    logic m_ready;
    logic ovf_skew;
    logic ovf_dct;

    int out_count;
    int timeout_cycles;

    dct64_serial #(
        .DATA_W(DATA_W),
        .SKEW_OUT_W(SKEW_OUT_W),
        .C_OUT_W(C_OUT_W)
    ) dut (
        .clk(clk),
        .rst(rst),
        .shift(shift),
        .s_data(s_data),
        .s_valid(s_valid),
        .s_ready(s_ready),
        .m_data(m_data),
        .m_index(m_index),
        .m_valid(m_valid),
        .m_ready(m_ready),
        .ovf_skew(ovf_skew),
        .ovf_dct(ovf_dct)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b1;
        shift = 4'b0000;
        s_valid = 1'b0;
        m_ready = 1'b1;
        out_count = 0;
        timeout_cycles = 0;

        for (int i = 0; i < 64; i = i + 1) begin
            s_data[i] = i - 32;
        end

        repeat (5) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        wait (s_ready);
        @(posedge clk);
        s_valid = 1'b1;
        @(posedge clk);
        s_valid = 1'b0;

        while (out_count < 64 && timeout_cycles < 2000) begin
            @(posedge clk);
            timeout_cycles = timeout_cycles + 1;
            if (m_valid && m_ready) begin
                $display("DCT64_OUT index=%0d data=%0d", m_index, m_data);
                out_count = out_count + 1;
            end
        end

        if (out_count == 64) begin
            $display("DCT64_SMOKE_PASS outputs=%0d ovf_skew=%0b ovf_dct=%0b",
                     out_count, ovf_skew, ovf_dct);
        end else begin
            $fatal(1, "DCT64_SMOKE_TIMEOUT outputs=%0d", out_count);
        end

        $finish;
    end
endmodule
