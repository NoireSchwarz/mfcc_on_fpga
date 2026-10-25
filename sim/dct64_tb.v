`timescale 1ns/1ps
module dct64_tb;
    parameter STALLS=1, FRAMES=64;
    localparam DATA_W=16, OUT_W=26;
    reg clk=0;always #5 clk=~clk;
    reg rst=1,s_valid=0,m_ready=0,m_ready_ref=0,force_stall=1;
    reg [3:0] shift=0;
    reg signed [64*DATA_W-1:0] s_data=0;
    wire s_ready,s_ready_ref,m_valid,m_valid_ref;
    wire signed [OUT_W-1:0] m_data,m_data_ref;
    wire [5:0] m_index,m_index_ref;
    wire ovf_skew,ovf_dct,ovf_skew_ref,ovf_dct_ref;
    reg signed [OUT_W-1:0] actual[0:63],expected[0:63];
    reg saved_skew,saved_dct,saved_skew_ref,saved_dct_ref;
    reg checking=0,held=0,held_ref=0;
    reg [OUT_W-1:0] held_data,held_data_ref;
    reg [5:0] held_index,held_index_ref;
    reg [31:0] rng=32'h1cb5e47a;
    reg signed [DATA_W-1:0] sample;
    integer count=0,count_ref=0,cycles=0,stall_checks=0,frames_checked=0;
    integer f,i,frame_start,first_new,last_new,first_old,last_old;
    dct64_serial dut(.clk(clk),.rst(rst),.shift(shift),.s_data(s_data),.s_valid(s_valid),.s_ready(s_ready),
        .m_data(m_data),.m_index(m_index),.m_valid(m_valid),.m_ready(m_ready),.ovf_skew(ovf_skew),.ovf_dct(ovf_dct));
    dct64_serial_reference ref_dut(.clk(clk),.rst(rst),.shift(shift),.s_data(s_data),.s_valid(s_valid),.s_ready(s_ready_ref),
        .m_data(m_data_ref),.m_index(m_index_ref),.m_valid(m_valid_ref),.m_ready(m_ready_ref),.ovf_skew(ovf_skew_ref),.ovf_dct(ovf_dct_ref));
    always @(negedge clk) begin
        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
        m_ready=!force_stall && (!STALLS || (rng[3:0]!=0 && cycles%71>=24));
        m_ready_ref=!force_stall && (!STALLS || (rng[7:4]!=0 && cycles%67>=21));
    end
    always @(posedge clk) begin
        if(rst) begin held=0;held_ref=0;end
        else begin
            cycles=cycles+1;
            if(cycles>200000) $fatal(1,"DCT64 timeout");
            if(held && (!m_valid || m_data!==held_data || m_index!==held_index)) $fatal(1,"DCT64 output unstable under backpressure");
            if(held_ref && (!m_valid_ref || m_data_ref!==held_data_ref || m_index_ref!==held_index_ref)) $fatal(1,"reference DCT64 output unstable");
            held=m_valid&&!m_ready;held_data=m_data;held_index=m_index;
            held_ref=m_valid_ref&&!m_ready_ref;held_data_ref=m_data_ref;held_index_ref=m_index_ref;
            if(held) stall_checks=stall_checks+1;
            if(checking && s_valid && s_ready && s_ready_ref) frame_start=cycles;
            if(checking && m_valid && m_ready) begin
                if(count>=64 || m_index!==count[5:0] || (^m_data)===1'bx) $fatal(1,"DCT64 bad output index/data");
                actual[count]=m_data;
                if(count==0) first_new=cycles-frame_start;
                if(count==63) begin saved_skew=ovf_skew;saved_dct=ovf_dct;last_new=cycles-frame_start;end
                count=count+1;
            end
            if(checking && m_valid_ref && m_ready_ref) begin
                if(count_ref>=64 || m_index_ref!==count_ref[5:0] || (^m_data_ref)===1'bx) $fatal(1,"reference DCT64 bad output index/data");
                expected[count_ref]=m_data_ref;
                if(count_ref==0) first_old=cycles-frame_start;
                if(count_ref==63) begin saved_skew_ref=ovf_skew_ref;saved_dct_ref=ovf_dct_ref;last_old=cycles-frame_start;end
                count_ref=count_ref+1;
            end
        end
    end
    task launch;
        begin
            wait(s_ready && s_ready_ref);
            @(negedge clk);#1;s_valid=1;
            @(posedge clk);
            if(!s_ready || !s_ready_ref) $fatal(1,"frame acceptance mismatch");
            @(negedge clk);#1;s_valid=0;
            // Verify that each top captures the accepted frame.
            s_data=~s_data;
        end
    endtask
    task flush_reset;
        begin
            @(negedge clk);#1;rst=1;s_valid=0;
            repeat(3) @(negedge clk);#1;rst=0;
            repeat(30) @(negedge clk);
            if(m_valid || m_valid_ref || !s_ready || !s_ready_ref) $fatal(1,"stale DCT64 transaction after reset");
        end
    endtask
    initial begin
        repeat(4) @(negedge clk);#1;rst=0;
        launch();repeat(4) @(negedge clk);flush_reset();
        launch();wait(m_valid);repeat(5) @(negedge clk);flush_reset();
        force_stall=0;
        for(f=0;f<FRAMES;f=f+1) begin
            wait(s_ready && s_ready_ref);
            @(negedge clk);#1;
            count=0;count_ref=0;checking=1;frame_start=cycles;
            shift=f%16;
            for(i=0;i<64;i=i+1) begin
                case(f%12)
                    0:sample=0;
                    1:sample=1234;
                    2:sample=(i==19)?16000:0;
                    3:sample=(i%2)?-25000:25000;
                    4:sample=-32768;
                    5:sample=32767;
                    6:sample=(i%2)?-1:1;
                    7:sample=$signed($random)%400;
                    default:sample=$random;
                endcase
                s_data[(63-i)*DATA_W+:DATA_W]=sample;
            end
            launch();
            wait(count==64 && count_ref==64);
            @(negedge clk);#1;
            for(i=0;i<64;i=i+1)
                if(actual[i]!==expected[i]) $fatal(1,"DCT64 mismatch frame=%0d shift=%0d k=%0d actual=%0d expected=%0d",f,shift,i,actual[i],expected[i]);
            if(saved_skew!==saved_skew_ref || saved_dct!==saved_dct_ref) $fatal(1,"DCT64 overflow flags differ frame=%0d",f);
            if(f==0) $display("DCT64_LATENCY stalls=%0d old_first=%0d new_first=%0d old_last=%0d new_last=%0d",STALLS,first_old,first_new,last_old,last_new);
            frames_checked=frames_checked+1;checking=0;
        end
        repeat(30) @(negedge clk);
        if(STALLS && stall_checks==0) $fatal(1,"DCT64 stalls not exercised");
        $display("PASS DCT64 frames=%0d coefficients=%0d shifts=16 stall_checks=%0d reset_aborts=2",frames_checked,frames_checked*64,stall_checks);
        $finish;
    end
endmodule
