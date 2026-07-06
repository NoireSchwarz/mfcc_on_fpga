`timescale 1ns / 1ps

module mfcc_trumpet_tb;
    // Change this assignment, or run vsim with "-G TB_N=<fft_points>".
    // Supported FFT points: 16, 32, 64, 128, 256, 512, 1024, 2048.
    parameter int TB_N = 512;

    localparam int N = TB_N;
    localparam int STRIDE = N / 2;
    localparam int OUT_WIDTH = 64;
    localparam int M_AXIS_DATA_W = 26;
    localparam int SAMPLE_COUNT = 117601;
    localparam int QUIET_CYCLES = 200000;
    localparam int MAX_SIM_CYCLES = 20000000;

    logic clk;
    logic reset;
    logic [15:0] s_axis_tdata;
    logic signed [M_AXIS_DATA_W-1:0] m_axis_tdata [OUT_WIDTH];
    logic s_axis_tready;
    logic s_axis_tvalid;
    logic m_axis_tready;
    logic m_axis_tvalid;
    logic m_axis_tlast;

    logic signed [15:0] audio_mem [0:SAMPLE_COUNT-1];
    string sample_file;
    string result_file;
    string summary_file;
    int result_fd;
    int summary_fd;
    int frame_count;
    int quiet_cycles;
    realtime start_time_ns;
    realtime end_time_ns;

    mfcc #(
        .N(N),
        .STRIDE(STRIDE),
        .OUT_WIDTH(OUT_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .s_axis_tdata(s_axis_tdata),
        .m_axis_tdata(m_axis_tdata),
        .s_axis_tready(s_axis_tready),
        .s_axis_tvalid(s_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic send_sample(input logic signed [15:0] sample);
        begin
            @(negedge clk);
            while (!s_axis_tready) begin
                @(negedge clk);
            end
            s_axis_tdata = sample;
            s_axis_tvalid = 1'b1;
            @(negedge clk);
            s_axis_tvalid = 1'b0;
            s_axis_tdata = '0;
        end
    endtask

    task automatic write_result_header;
        begin
            $fwrite(result_fd, "n,stride,frame,sim_time_ns,elapsed_ns");
            for (int i = 0; i < OUT_WIDTH; i++) begin
                $fwrite(result_fd, ",mfcc_%0d", i);
            end
            $fwrite(result_fd, "\n");
        end
    endtask

    always @(posedge clk) begin
        if (!reset && m_axis_tvalid && m_axis_tready) begin
            $fwrite(result_fd, "%0d,%0d,%0d,%0.3f,%0.3f",
                    N, STRIDE, frame_count, $realtime, $realtime - start_time_ns);
            for (int i = 0; i < OUT_WIDTH; i++) begin
                $fwrite(result_fd, ",%0d", $signed(m_axis_tdata[i]));
            end
            $fwrite(result_fd, "\n");
            frame_count = frame_count + 1;
        end
    end

    initial begin
        repeat (MAX_SIM_CYCLES) @(posedge clk);
        $fatal(1, "Timeout in mfcc_trumpet_tb N=%0d after %0d cycles", N, MAX_SIM_CYCLES);
    end

    initial begin
        if (!((N == 16) || (N == 32) || (N == 64) || (N == 128) ||
              (N == 256) || (N == 512) || (N == 1024) || (N == 2048))) begin
            $fatal(1, "This trumpet MFCC TB supports N=16,32,64,128,256,512,1024,2048; got N=%0d", N);
        end

        sample_file = "sim/trumpet_pcm16.mem";
        result_file = $sformatf("sim/mfcc_trumpet_%0d_result.csv", N);
        summary_file = $sformatf("sim/mfcc_trumpet_%0d_summary.csv", N);
        void'($value$plusargs("SAMPLE_FILE=%s", sample_file));
        void'($value$plusargs("RESULT_FILE=%s", result_file));
        void'($value$plusargs("SUMMARY_FILE=%s", summary_file));

        $readmemh(sample_file, audio_mem);

        result_fd = $fopen(result_file, "w");
        if (result_fd == 0) begin
            $fatal(1, "Could not open result CSV: %s", result_file);
        end
        write_result_header();

        summary_fd = $fopen(summary_file, "w");
        if (summary_fd == 0) begin
            $fatal(1, "Could not open summary CSV: %s", summary_file);
        end
        $fwrite(summary_fd, "n,stride,sample_count,frames,start_time_ns,end_time_ns,elapsed_ns,result_file\n");

        reset = 1'b1;
        s_axis_tdata = '0;
        s_axis_tvalid = 1'b0;
        m_axis_tready = 1'b1;
        frame_count = 0;

        repeat (10) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;
        start_time_ns = $realtime;
        repeat (5) @(posedge clk);

        for (int i = 0; i < SAMPLE_COUNT; i++) begin
            send_sample(audio_mem[i]);
        end

        quiet_cycles = 0;
        while (quiet_cycles < QUIET_CYCLES) begin
            @(posedge clk);
            if (m_axis_tvalid && m_axis_tready) begin
                quiet_cycles = 0;
            end else begin
                quiet_cycles++;
            end
        end

        end_time_ns = $realtime;
        $fwrite(summary_fd, "%0d,%0d,%0d,%0d,%0.3f,%0.3f,%0.3f,%s\n",
                N, STRIDE, SAMPLE_COUNT, frame_count,
                start_time_ns, end_time_ns, end_time_ns - start_time_ns, result_file);

        $display("mfcc_trumpet_tb N=%0d complete: %0d frames, elapsed %0.3f ns", N, frame_count, end_time_ns - start_time_ns);
        $display("  result CSV : %s", result_file);
        $display("  summary CSV: %s", summary_file);

        $fclose(result_fd);
        $fclose(summary_fd);
        $finish;
    end
endmodule
