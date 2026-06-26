`timescale 1ns / 1ps

module tb_fft512_impulse;
    localparam int NB = 16;
    localparam logic signed [NB-1:0] NYQUIST_HIGH = {1'b0, {(NB-1){1'b1}}};
    localparam logic signed [NB-1:0] NYQUIST_LOW  = {1'b1, {(NB-1){1'b0}}};
    localparam int LEAK_TOL = 2;

    logic clk = 1'b0;
    logic fft_reset = 1'b1;
    logic reset = 1'b0;
    logic in_valid = 1'b0;
    logic in_ready;
    logic out_valid;
    logic out_ready = 1'b0;
    logic signed [NB-1:0] fft_real_in [0:511];
    logic signed [NB-1:0] fft_out_re [0:511];
    logic signed [NB-1:0] fft_out_im [0:511];
    int errors = 0;
    int out_file;
    int abs_re;
    int abs_im;

    fft512 #(.NB(NB)) dut (
        .clk(clk),
        .fft_reset(fft_reset),
        .reset(reset),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .fft_real_in(fft_real_in),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .fft_out_re(fft_out_re),
        .fft_out_im(fft_out_im)
    );

    always #5 clk = ~clk;

    initial begin
        for (int i = 0; i < 512; i++) begin
            fft_real_in[i] = (i[0] == 1'b0) ? NYQUIST_HIGH : NYQUIST_LOW;
        end

        repeat (4) @(posedge clk);
        fft_reset = 1'b0;
        repeat (2) @(posedge clk);

        in_valid = 1'b1;
        do begin
            @(posedge clk);
        end while (!in_ready);
        @(posedge clk);
        in_valid = 1'b0;

        fork
            begin
                wait (out_valid);
            end
            begin
                repeat (3000) @(posedge clk);
                $fatal(1, "timeout waiting for out_valid");
            end
        join_any
        disable fork;

        out_file = $fopen("out.csv", "w");
        if (out_file == 0) begin
            $fatal(1, "failed to open out.csv");
        end
        $fdisplay(out_file, "bin,real,imag");
        for (int i = 0; i < 512; i++) begin
            $fdisplay(out_file, "%0d,%0d,%0d", i, fft_out_re[i], fft_out_im[i]);
        end
        $fclose(out_file);

        repeat (3) begin
            @(posedge clk);
            if (!out_valid) begin
                errors++;
                $error("out_valid dropped while out_ready was low");
            end
            if (in_ready) begin
                errors++;
                $error("in_ready asserted before output frame was accepted");
            end
        end

        for (int i = 0; i < 512; i++) begin
            if ($isunknown({fft_out_re[i], fft_out_im[i]})) begin
                errors++;
                $error("X at bin %0d: %0d + j%0d", i, fft_out_re[i], fft_out_im[i]);
            end
            abs_re = (fft_out_re[i] < 0) ? -fft_out_re[i] : fft_out_re[i];
            abs_im = (fft_out_im[i] < 0) ? -fft_out_im[i] : fft_out_im[i];
            if (abs_im > LEAK_TOL) begin
                errors++;
                $error("unexpected imaginary at bin %0d: %0d", i, fft_out_im[i]);
            end
            if (i != 256 && abs_re > LEAK_TOL) begin
                errors++;
                $error("nyquist leakage at bin %0d: %0d + j%0d",
                       i, fft_out_re[i], fft_out_im[i]);
            end
        end
        if (fft_out_re[256] <= 0) begin
            errors++;
            $error("nyquist spectrum expected positive peak at bin 256, got %0d", fft_out_re[256]);
        end

        out_ready = 1'b1;
        @(posedge clk);
        out_ready = 1'b0;
        @(posedge clk);
        if (!in_ready) begin
            errors++;
            $error("in_ready did not return after output handshake");
        end

        if (errors != 0) begin
            $fatal(1, "FAIL fft512 nyquist smoke test with %0d errors", errors);
        end

        $display("PASS fft512 nyquist smoke test");
        $finish;
    end
endmodule
