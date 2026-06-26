`timescale 1ns / 1ps

module tb_fft512_onehot;
    localparam int NB = 16;
    localparam logic signed [NB-1:0] IMPULSE_VALUE = 16'sd32767;
    localparam int IMAG_TOL = 2;
    localparam int FLAT_TOL = 2;

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
    int total_abs;

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

    function automatic int abs_int(input int value);
        begin
            abs_int = (value < 0) ? -value : value;
        end
    endfunction

    task automatic clear_input;
        begin
            for (int i = 0; i < 512; i++) begin
                fft_real_in[i] = '0;
            end
        end
    endtask

    task automatic drive_onehot(input int hot_index);
        begin
            clear_input();
            fft_real_in[hot_index] = IMPULSE_VALUE;

            in_valid = 1'b1;
            do begin
                @(posedge clk);
            end while (!in_ready);
            @(posedge clk);
            in_valid = 1'b0;
        end
    endtask

    task automatic wait_for_output(input string label);
        begin
            fork
                begin
                    wait (out_valid);
                end
                begin
                    repeat (3500) @(posedge clk);
                    $fatal(1, "timeout waiting for %s out_valid", label);
                end
            join_any
            disable fork;
        end
    endtask

    task automatic write_csv(input string filename);
        int out_file;
        begin
            out_file = $fopen(filename, "w");
            if (out_file == 0) begin
                $fatal(1, "failed to open %s", filename);
            end

            $fdisplay(out_file, "bin,real,imag");
            for (int i = 0; i < 512; i++) begin
                $fdisplay(out_file, "%0d,%0d,%0d", i, fft_out_re[i], fft_out_im[i]);
            end
            $fclose(out_file);
        end
    endtask

    task automatic check_no_x(input string label);
        begin
            for (int i = 0; i < 512; i++) begin
                if ($isunknown({fft_out_re[i], fft_out_im[i]})) begin
                    errors++;
                    $error("%s X at bin %0d: %0d + j%0d",
                           label, i, fft_out_re[i], fft_out_im[i]);
                end
            end
        end
    endtask

    task automatic check_onehot0;
        int ref_re;
        int re_diff;
        int im_abs;
        begin
            check_no_x("onehot0");
            ref_re = fft_out_re[0];
            if (ref_re <= 0) begin
                errors++;
                $error("onehot0 expected positive reference bin, got %0d", ref_re);
            end

            for (int i = 0; i < 512; i++) begin
                re_diff = abs_int(fft_out_re[i] - ref_re);
                im_abs = abs_int(fft_out_im[i]);
                if (re_diff > FLAT_TOL || im_abs > IMAG_TOL) begin
                    errors++;
                    $error("onehot0 expected flat real spectrum at bin %0d: %0d + j%0d, ref %0d",
                           i, fft_out_re[i], fft_out_im[i], ref_re);
                end
            end
        end
    endtask

    task automatic check_onehot1;
        begin
            check_no_x("onehot1");
            total_abs = 0;
            for (int i = 0; i < 512; i++) begin
                total_abs += abs_int(fft_out_re[i]);
                total_abs += abs_int(fft_out_im[i]);
            end

            if (total_abs == 0) begin
                errors++;
                $error("onehot1 produced an all-zero spectrum");
            end
        end
    endtask

    task automatic accept_output(input string label);
        begin
            repeat (3) begin
                @(posedge clk);
                if (!out_valid) begin
                    errors++;
                    $error("%s out_valid dropped while out_ready was low", label);
                end
                if (in_ready) begin
                    errors++;
                    $error("%s in_ready asserted before output frame was accepted", label);
                end
            end

            out_ready = 1'b1;
            @(posedge clk);
            out_ready = 1'b0;
            @(posedge clk);
            if (!in_ready) begin
                errors++;
                $error("%s in_ready did not return after output handshake", label);
            end
        end
    endtask

    initial begin
        clear_input();

        repeat (4) @(posedge clk);
        fft_reset = 1'b0;
        repeat (2) @(posedge clk);

        drive_onehot(0);
        wait_for_output("onehot0");
        write_csv("out_onehot0.csv");
        check_onehot0();
        accept_output("onehot0");

        drive_onehot(1);
        wait_for_output("onehot1");
        write_csv("out_onehot1.csv");
        check_onehot1();
        accept_output("onehot1");

        if (errors != 0) begin
            $fatal(1, "FAIL fft512 onehot smoke test with %0d errors", errors);
        end

        $display("PASS fft512 onehot smoke test");
        $finish;
    end
endmodule
