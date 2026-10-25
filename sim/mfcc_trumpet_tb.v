`timescale 1ns/1ps
// Pure Verilog-2001 testbench. CSV coefficients are raw signed hardware values.
module mfcc_trumpet_tb;
    parameter TB_N=512, TB_USE_MATRIX=0, TB_SAMPLE_COUNT=117601;
    parameter TB_OUT_WIDTH=64, TB_STALL=0;
    localparam STRIDE=TB_N/2, DATA_W=26;
    localparam EXPECTED_FRAMES=TB_SAMPLE_COUNT/STRIDE;
    reg clk,reset;
    reg [15:0] s_axis_tdata;
    reg s_axis_tvalid,m_axis_tready;
    wire s_axis_tready,m_axis_tvalid,m_axis_tlast;
    wire signed [TB_OUT_WIDTH*DATA_W-1:0] m_axis_tdata;
    reg signed [15:0] audio_mem [0:117600];
    reg signed [DATA_W-1:0] frame_data [0:63];
    reg [4095:0] sample_file,result_file;
    reg [TB_OUT_WIDTH*DATA_W-1:0] held_data;
    reg held_valid,held_last;
    integer result_fd,frame_count,output_index,cycle_count,tb_error;
    integer i,k,plusarg_status,stall_cycles;
    realtime start_time_ns;

    mfcc #(.N(TB_N),.STRIDE(STRIDE),.OUT_WIDTH(TB_OUT_WIDTH),
           .DCT_USE_MATRIX(TB_USE_MATRIX)) dut(
        .clk(clk),.reset(reset),.s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),.s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),.m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),.m_axis_tlast(m_axis_tlast));

    initial begin clk=0;forever #5 clk=~clk;end
    task fail;
        input [2047:0] reason;
        begin
            tb_error=1;
            $display("FAIL: %0s",reason);
            if(result_fd!=0) $fclose(result_fd);
            $finish;
        end
    endtask
    task send_sample;
        input [15:0] value;
        integer gap;
        begin
            @(negedge clk);
            while(!s_axis_tready) @(negedge clk);
            if(TB_STALL) begin
                gap=$random & 3;
                repeat(gap) @(negedge clk);
            end
            s_axis_tdata=value;s_axis_tvalid=1;
            @(negedge clk);
            s_axis_tvalid=0;s_axis_tdata=0;
        end
    endtask

    always @(negedge clk) if(!reset && TB_STALL)
        m_axis_tready=(cycle_count%193>=160);

    always @(posedge clk) if(!reset) begin
        cycle_count=cycle_count+1;
        if(held_valid) begin
            if(m_axis_tvalid!==1'b1 || m_axis_tdata!==held_data || m_axis_tlast!==held_last)
                fail("Output changed while stalled");
        end
        held_valid=(m_axis_tvalid && !m_axis_tready);
        held_data=m_axis_tdata;held_last=m_axis_tlast;
        if(held_valid) stall_cycles=stall_cycles+1;
        if(dut.U_CORE.dct_serial_valid &&
            ((dut.U_CORE.dct_ovf_skew===1'b1)||(dut.U_CORE.dct_ovf_dct===1'b1)))
            fail("DCT overflow");
        if(m_axis_tvalid && m_axis_tready) begin
            if((^m_axis_tdata)===1'bx) fail("Unknown output coefficient");
            if(m_axis_tlast !== (output_index+TB_OUT_WIDTH==64)) fail("TLAST coefficient alignment");
            if(frame_count>=EXPECTED_FRAMES) fail("Extra output frame");
            for(k=0;k<TB_OUT_WIDTH;k=k+1)
                frame_data[output_index+k]=$signed(m_axis_tdata[k*DATA_W +: DATA_W]);
            if(output_index+TB_OUT_WIDTH==64) begin
                $fwrite(result_fd,"%0d,%0d,%0d,%0.3f,%0.3f",TB_N,STRIDE,frame_count,$realtime,$realtime-start_time_ns);
                for(k=0;k<64;k=k+1) $fwrite(result_fd,",%0d",frame_data[k]);
                $fwrite(result_fd,"\n");
                frame_count=frame_count+1;output_index=0;
            end else output_index=output_index+TB_OUT_WIDTH;
        end
    end

    initial begin
        result_fd=0;tb_error=0;frame_count=0;output_index=0;cycle_count=0;stall_cycles=0;
        held_valid=0;held_data=0;held_last=0;
        reset=1;s_axis_tdata=0;s_axis_tvalid=0;m_axis_tready=1;
        if(TB_SAMPLE_COUNT<1 || TB_SAMPLE_COUNT>117601 || 64%TB_OUT_WIDTH!=0)
            fail("Invalid testbench parameter");
        sample_file="trumpet_pcm16.mem";result_file="mfcc_verilog_result.csv";
        plusarg_status=$value$plusargs("SAMPLE_FILE=%s",sample_file);
        plusarg_status=$value$plusargs("RESULT_FILE=%s",result_file);
        $readmemh(sample_file,audio_mem);
        result_fd=$fopen(result_file,"w");
        if(result_fd==0) fail("Cannot open result CSV");
        $fwrite(result_fd,"n,stride,frame,sim_time_ns,elapsed_ns");
        for(i=0;i<64;i=i+1) $fwrite(result_fd,",mfcc_%0d",i);
        $fwrite(result_fd,"\n");
        repeat(10) @(negedge clk);
        reset=0;start_time_ns=$realtime;
        for(i=0;i<TB_SAMPLE_COUNT;i=i+1) send_sample(audio_mem[i]);
        wait(frame_count==EXPECTED_FRAMES);
        repeat(50) @(negedge clk);
        if(output_index!=0) fail("Partial output frame");
        if(TB_STALL && stall_cycles==0) fail("Backpressure test did not stall");
        $display("PASS: Verilog-2001 N=%0d matrix=%0d OUT_WIDTH=%0d frames=%0d stalls=%0d",
                 TB_N,TB_USE_MATRIX,TB_OUT_WIDTH,frame_count,stall_cycles);
        $fclose(result_fd);result_fd=0;
        $finish;
    end
    initial begin
        repeat(20000000) @(posedge clk);
        fail("Simulation timeout");
    end
endmodule
