`timescale 1ns / 1ps

module tb_fft2x256_impulse;
    localparam int NB = 16;

    logic clk = 1'b0;
    logic fft_reset = 1'b1;
    logic reset = 1'b0;
    logic start = 1'b0;
    logic signed [NB-1:0] fft_real_in [0:511];
    logic signed [NB-1:0] even_out_re [0:255];
    logic signed [NB-1:0] even_out_im [0:255];
    logic signed [NB-1:0] odd_out_re [0:255];
    logic signed [NB-1:0] odd_out_im [0:255];
    logic out_valid;
    logic m_ready;
    int errors = 0;

    fft2x256 #(.NB(NB)) dut (
        .clk(clk),
        .fft_reset(fft_reset),
        .reset(reset),
        .start(start),
        .fft_real_in(fft_real_in),
        .even_out_re(even_out_re),
        .even_out_im(even_out_im),
        .odd_out_re(odd_out_re),
        .odd_out_im(odd_out_im),
        .out_valid(out_valid),
        .m_ready(m_ready)
    );

    always #5 clk = ~clk;

    initial begin
        for (int i = 0; i < 512; i++) begin
            fft_real_in[i] = '0;
        end
        fft_real_in[0] = 16'sd32767;

        repeat (4) @(posedge clk);
        fft_reset = 1'b0;
        repeat (2) @(posedge clk);

        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        fork
            begin
                wait (out_valid);
            end
            begin
                repeat (2000) @(posedge clk);
                $error("timeout waiting for out_valid");
                $finish;
            end
        join_any
        disable fork;

        for (int i = 0; i < 256; i++) begin
            if ($isunknown({even_out_re[i], even_out_im[i], odd_out_re[i], odd_out_im[i]})) begin
                errors++;
                $error("X at bin %0d: even %0d + j%0d, odd %0d + j%0d",
                       i, even_out_re[i], even_out_im[i], odd_out_re[i], odd_out_im[i]);
            end
        end

        for (int i = 0; i < 256; i++) begin
            if (even_out_im[i] !== '0) begin
                errors++;
                $error("channel 1 unexpected imaginary at bin %0d: %0d", i, even_out_im[i]);
            end
            if (odd_out_re[i] !== '0 || odd_out_im[i] !== '0) begin
                errors++;
                $error("channel 2 expected zero at bin %0d: %0d + j%0d",
                       i, odd_out_re[i], odd_out_im[i]);
            end
        end
        if (even_out_re[0] <= 0) begin
            errors++;
            $error("channel 1 impulse spectrum expected positive real line, got %0d", even_out_re[0]);
        end

        if (errors != 0) begin
            $fatal(1, "FAIL fft2x256 impulse smoke test with %0d errors", errors);
        end

        $display("PASS fft2x256 impulse smoke test");
        $finish;
    end
endmodule
