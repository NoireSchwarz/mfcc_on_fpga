`timescale 1ns/1ps
// Same harness compiles against baseline or refactored complete MFCC sources.
module mfcc_bram_tb;
    parameter N=512,FRAMES=4,OUT_WIDTH=1,MATRIX=0,STALLS=1;
    parameter SAMPLE_COUNT=FRAMES*(N/2);
    localparam DATA_W=26,EXPECTED_FRAMES=SAMPLE_COUNT/(N/2);
    reg clk=0;always #5 clk=~clk;
    reg reset=1,s_valid=0,m_ready=0;
    reg [15:0] s_data=0;
    wire s_ready,m_valid,m_last;
    wire [OUT_WIDTH*DATA_W-1:0] m_data;
    reg [15:0] samples[0:SAMPLE_COUNT-1];
    reg signed [DATA_W-1:0] coefficients[0:63];
    reg [OUT_WIDTH*DATA_W-1:0] held_data;
    reg held=0,held_last;
    reg [31:0] input_rng=32'h4c86ea32,output_rng=32'h31e927ba;
    integer i,k,fd,frame_count,output_index,cycles,stalls,waiting;
    mfcc #(.N(N),.STRIDE(N/2),.OUT_WIDTH(OUT_WIDTH),.DCT_USE_MATRIX(MATRIX)) dut(
        .clk(clk),.reset(reset),.s_axis_tdata(s_data),.s_axis_tvalid(s_valid),
        .s_axis_tready(s_ready),.m_axis_tdata(m_data),.m_axis_tvalid(m_valid),
        .m_axis_tready(m_ready),.m_axis_tlast(m_last));
    always @(negedge clk)if(!reset)begin
        output_rng={output_rng[30:0],output_rng[31]^output_rng[21]^output_rng[1]^output_rng[0]};
        if(!m_valid)waiting=0;else waiting=waiting+1;
        m_ready=!STALLS || (waiting>5 && output_rng[2:0]!=0 && cycles%193>=80);
    end
    always @(posedge clk)if(!reset)begin
        cycles=cycles+1;
        if(cycles>20000000)$fatal(1,"MFCC timeout N=%0d frames=%0d",N,frame_count);
        if(held)begin
            if(!m_valid || m_data!==held_data || m_last!==held_last)
                $fatal(1,"MFCC output unstable under backpressure");
            stalls=stalls+1;
        end
        held=m_valid&&!m_ready;held_data=m_data;held_last=m_last;
        if(m_valid&&m_ready)begin
            if((^m_data)===1'bx)$fatal(1,"unknown MFCC coefficient");
            if(m_last!==(output_index+OUT_WIDTH==64))$fatal(1,"MFCC TLAST mismatch");
            if(frame_count>=EXPECTED_FRAMES)$fatal(1,"extra MFCC frame");
            for(k=0;k<OUT_WIDTH;k=k+1)
                coefficients[output_index+k]=$signed(m_data[k*DATA_W+:DATA_W]);
            if(output_index+OUT_WIDTH==64)begin
                $fwrite(fd,"%0d",frame_count);
                for(k=0;k<64;k=k+1)$fwrite(fd,",%0d",coefficients[k]);
                $fwrite(fd,"\n");frame_count=frame_count+1;output_index=0;
            end else output_index=output_index+OUT_WIDTH;
        end
    end
    initial begin
        cycles=0;stalls=0;waiting=0;frame_count=0;output_index=0;
        $readmemh("input.mem",samples);fd=$fopen("mfcc.csv","w");
        repeat(10)@(negedge clk);reset=0;
        for(i=0;i<SAMPLE_COUNT;i=i+1)begin
            input_rng={input_rng[30:0],input_rng[31]^input_rng[21]^input_rng[1]^input_rng[0]};
            if(STALLS)repeat(input_rng[1:0])@(negedge clk);
            @(negedge clk);s_data=samples[i];s_valid=1;
            @(posedge clk);while(!s_ready)@(posedge clk);
            @(negedge clk);s_valid=0;
        end
        wait(frame_count==EXPECTED_FRAMES);
        repeat(100)@(negedge clk);
        if(STALLS && stalls==0)$fatal(1,"MFCC stalls were not exercised");
        $fclose(fd);
        $display("PASS MFCC N=%0d matrix=%0d lanes=%0d frames=%0d coefficients=%0d stalls=%0d cycles=%0d",N,MATRIX,OUT_WIDTH,frame_count,frame_count*64,stalls,cycles);
        $finish;
    end
endmodule
