`timescale 1ns/1ps
module banks_tb;
    parameter KIND=0, STALLS=1, FRAMES=32;
    localparam IN_W=(KIND==0)?16:22, OUT_W=(KIND==0)?24:26;
    reg clk=0;always #5 clk=~clk;
    reg rst=1,ed=1,start=0,s_valid=0,freeze=0;
    reg signed [64*IN_W-1:0] din=0;
    reg signed [IN_W-1:0] s_data=0;
    wire sr,sr_ref,mv,mv_ref,done,done_ref;
    wire signed [OUT_W-1:0] md,md_ref;
    wire [5:0] mi,mi_ref;
    reg mr=0,mr_ref=0;
    reg signed [OUT_W-1:0] actual[0:63],expected[0:63];
    reg signed [IN_W-1:0] samples[0:63];
    integer received=0,received_ref=0,frames_checked=0,cycles=0,pauses=0,stalls=0;
    integer f,i,source_bubbles,frame_start,first_cycle,last_cycle;
    reg checking=0,held=0,held_ref=0;
    reg [OUT_W-1:0] held_data,held_data_ref;
    reg [5:0] held_index,held_index_ref;
    reg [31:0] rng=32'h72cb1569;
    generate if(KIND==0) begin:skew_case
        assign sr=1'b1;assign sr_ref=1'b1;
        skewdct8_dctii_tdm_bank dut(.CLK(clk),.RST(rst),.ED(ed),.START(start),.DIN(din),
            .m_data(md),.m_index(mi),.m_valid(mv),.m_ready(mr),.RDY(done));
        skewdct8_dctii_tdm_bank_reference ref_dut(.CLK(clk),.RST(rst),.ED(ed),.START(start),.DIN(din),
            .m_data(md_ref),.m_index(mi_ref),.m_valid(mv_ref),.m_ready(mr_ref),.RDY(done_ref));
    end else begin:dct_case
        dct8_tdm_bank #(.IN_W(IN_W),.OUT_W(OUT_W)) dut(.CLK(clk),.RST(rst),.ED(ed),.START(start),
            .s_data(s_data),.s_valid(s_valid),.s_ready(sr),
            .m_data(md),.m_index(mi),.m_valid(mv),.m_ready(mr),.RDY(done));
        dct8_tdm_bank_reference #(.IN_W(IN_W),.OUT_W(OUT_W)) ref_dut(.CLK(clk),.RST(rst),.ED(ed),.START(start),
            .s_data(s_data),.s_valid(s_valid),.s_ready(sr_ref),
            .m_data(md_ref),.m_index(mi_ref),.m_valid(mv_ref),.m_ready(mr_ref),.RDY(done_ref));
    end endgenerate
    always @(negedge clk) begin
        rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
        ed=!freeze && (!STALLS || rng[1:0]!=0);
        mr=ed && (!STALLS || (rng[4:2]!=0 && cycles%53>=19));
        mr_ref=ed && (!STALLS || (rng[7:5]!=0 && cycles%47>=13));
    end
    always @(posedge clk) begin
        if(rst) begin held=0;held_ref=0;end
        else begin
            cycles=cycles+1;
            if(cycles>100000) $fatal(1,"bank timeout");
            if(!ed) pauses=pauses+1;
            if(held && (!mv || md!==held_data || mi!==held_index)) $fatal(1,"bank output changed under stall");
            if(held_ref && (!mv_ref || md_ref!==held_data_ref || mi_ref!==held_index_ref)) $fatal(1,"reference output changed under stall");
            held=mv&&!mr;held_data=md;held_index=mi;
            held_ref=mv_ref&&!mr_ref;held_data_ref=md_ref;held_index_ref=mi_ref;
            if(held) stalls=stalls+1;
            if(checking && mv && mr && ed) begin
                if(received>=64 || mi!==received[5:0] || (^md)===1'bx) $fatal(1,"bad bank output index/data");
                actual[received]=md;
                if(received==0) first_cycle=cycles-frame_start;
                received=received+1;
                last_cycle=cycles-frame_start;
            end
            if(checking && mv_ref && mr_ref && ed) begin
                if(received_ref>=64 || mi_ref!==received_ref[5:0]) $fatal(1,"bad reference bank index");
                expected[received_ref]=md_ref;received_ref=received_ref+1;
            end
        end
    end
    task launch;
        begin
            @(negedge clk);#1;start=1;
            @(posedge clk);while(!ed) @(posedge clk);
            @(negedge clk);#1;start=0;
        end
    endtask
    initial begin
        repeat(4) @(negedge clk);#1;rst=0;
        // Abort an active request. Reset must flush even when ED is low.
        launch();
        if(KIND==1) begin
            @(negedge clk);#1;s_valid=1;s_data=123;
            repeat(4) @(posedge clk);
        end else repeat(4) @(posedge clk);
        @(negedge clk);#1;rst=1;freeze=1;start=0;s_valid=0;
        repeat(3) @(negedge clk);#1;rst=0;freeze=0;
        repeat(30) @(negedge clk);
        if(mv || mv_ref) $fatal(1,"stale bank output after reset");
        for(f=0;f<FRAMES;f=f+1) begin
            @(negedge clk);#1;
            received=0;received_ref=0;frame_start=cycles;checking=1;
            for(i=0;i<64;i=i+1) begin
                case(f%8)
                    0:samples[i]=0;
                    1:samples[i]={1'b1,{IN_W-1{1'b0}}};
                    2:samples[i]={1'b0,{IN_W-1{1'b1}}};
                    3:samples[i]=(i%2)?-1:1;
                    4:samples[i]=(i==17)?12345:0;
                    default:samples[i]=$random;
                endcase
                din[(63-i)*IN_W+:IN_W]=samples[i];
            end
            launch();
            if(KIND==1) for(i=0;i<64;i=i+1) begin
                if(STALLS) begin source_bubbles=(i+f)%3;repeat(source_bubbles) @(negedge clk);end
                @(negedge clk);#1;s_data=samples[i];s_valid=1;
                @(posedge clk);while(!(ed && sr && sr_ref)) @(posedge clk);
                @(negedge clk);#1;s_valid=0;
            end
            wait(received==64 && received_ref==64);
            @(negedge clk);#1;
            for(i=0;i<64;i=i+1)
                if(actual[i]!==expected[i]) $fatal(1,"bank mismatch kind=%0d frame=%0d index=%0d actual=%0d expected=%0d",KIND,f,i,actual[i],expected[i]);
            frames_checked=frames_checked+1;
            checking=0;
            if(f==0) $display("BANK_LATENCY kind=%0d stalls=%0d first=%0d last=%0d",KIND,STALLS,first_cycle,last_cycle);
        end
        repeat(20) @(negedge clk);
        if(STALLS && (stalls==0 || pauses==0)) $fatal(1,"bank stalls not exercised");
        $display("PASS bank kind=%0d frames=%0d coefficients=%0d pauses=%0d stall_checks=%0d",KIND,frames_checked,frames_checked*64,pauses,stalls);
        $finish;
    end
endmodule
