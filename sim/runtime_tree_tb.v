`timescale 1ns/1ps
module runtime_tree_tb;
    parameter MAX_LOG2=11;
    parameter WORDS=32640;
    parameter FRAMES=64;
    parameter STALLS=1;
    parameter PAIR_ONLY=0;
    reg clk=0;always #5 clk=~clk;
    reg resetn=0;
    reg [2:0] size_sel=0;
    reg [15:0] s_data=0;
    reg s_valid=0,m_ready=0;
    wire s_ready,m_valid,m_last,busy;
    wire [31:0] m_data;
    wire [2:0] active_size;
    reg [15:0] samples[0:WORDS-1];
    reg [31:0] expected[0:WORDS-1];
    reg [2:0] sizes[0:FRAMES-1];
    reg [31:0] rng=32'h7cf345ab;
    reg held;
    reg [31:0] held_data;
    reg held_last;
    reg [2:0] expected_active;
    integer frame_index,offset,n,sent,got,cycles,first_cycle,first_output;
    integer checked=0,stall_checks=0,latch_checks=0;
    generate if(PAIR_ONLY)begin:gen_pair
        wire mode_active;
        assign active_size={2'b01,mode_active};
        fft64_128_shared_runtime dut(.clk(clk),.resetn(resetn),.mode_128(size_sel[0]),
            .s_data(s_data),.s_valid(s_valid),.s_ready(s_ready),.m_data(m_data),
            .m_valid(m_valid),.m_ready(m_ready),.m_last(m_last),.busy(busy),
            .mode_active_o(mode_active));
    end else begin:gen_tree
        fft_tree_runtime_bram dut(.clk(clk),.resetn(resetn),.size_sel(size_sel),
            .s_data(s_data),.s_valid(s_valid),.s_ready(s_ready),.m_data(m_data),
            .m_valid(m_valid),.m_ready(m_ready),.m_last(m_last),.busy(busy),
            .size_active_o(active_size));
    end endgenerate
    task step_rng;
        begin rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};end
    endtask
    task reset_dut;
        begin
            @(negedge clk);resetn=0;s_valid=0;m_ready=0;held=0;
            repeat(5)begin
                @(posedge clk);
                if(m_valid || s_ready)$fatal(1,"handshake during reset");
                @(negedge clk);
            end
            resetn=1;
        end
    endtask
    initial begin
        cycles=0;held=0;
        $readmemh("runtime_input.mem",samples);
        $readmemh("runtime_expected.mem",expected);
        $readmemh("runtime_sizes.mem",sizes);
        reset_dut;
        // Discard partial input on reset; stale RAM contents must not escape.
        size_sel=3'd2;s_valid=1;s_data=16'h9e37;
        repeat(9)@(negedge clk);
        reset_dut;
        // Discard a running transform on reset as well.
        size_sel=3'd2;s_valid=1;
        repeat(64)@(negedge clk);
        s_valid=0;repeat(24)@(negedge clk);
        reset_dut;
        // Discard a pending, stalled output frame on reset.
        size_sel=3'd2;s_valid=1;
        repeat(64)@(negedge clk);
        s_valid=0;
        @(posedge clk);while(!m_valid)@(posedge clk);
        repeat(4)@(negedge clk);
        reset_dut;
        offset=0;
        for(frame_index=0;frame_index<FRAMES;frame_index=frame_index+1)begin
            n=16<<sizes[frame_index];sent=0;got=0;held=0;first_output=-1;
            expected_active=sizes[frame_index];first_cycle=cycles;
            while(got<n)begin
                @(negedge clk);step_rng;
                // Flip every selection bit after the first accepted sample.
                size_sel=(sent==0)?sizes[frame_index]:rng[10:8];
                s_valid=(sent<n)&&(!STALLS || rng[1:0]!=0);
                if(sent<n)s_data=samples[offset+sent];
                m_ready=!STALLS || (rng[4:2]!=0 && (cycles%89)>12);
                @(posedge clk);
                if(held)begin
                    if(!m_valid || m_data!==held_data || m_last!==held_last)
                        $fatal(1,"output changed under backpressure frame=%0d",frame_index);
                    stall_checks=stall_checks+1;
                end
                held=m_valid&&!m_ready;held_data=m_data;held_last=m_last;
                if(sent>0)begin
                    if(active_size!==expected_active)$fatal(1,"frame selection changed");
                    if(!busy)$fatal(1,"busy dropped within frame");
                    latch_checks=latch_checks+1;
                end
                if(s_valid&&s_ready)sent=sent+1;
                if(m_valid)begin
                    if(first_output<0)first_output=cycles-first_cycle;
                    if(sent!=n)$fatal(1,"premature output");
                    if(m_last!==(got==n-1))$fatal(1,"TLAST index=%0d N=%0d",got,n);
                    if(m_ready)begin
                        if(m_data!==expected[offset+got])
                            $fatal(1,"mismatch frame=%0d N=%0d k=%0d actual=%h expected=%h",frame_index,n,got,m_data,expected[offset+got]);
                        checked=checked+1;got=got+1;
                    end
                end
            end
            $display("RUNTIME frame=%0d N=%0d first=%0d cycles=%0d",frame_index,n,first_output,cycles-first_cycle);
            offset=offset+n;
        end
        @(negedge clk);s_valid=0;m_ready=1;
        repeat(4)begin
            @(posedge clk);if(m_valid || busy || m_last)$fatal(1,"extra output or busy after frame");
            @(negedge clk);
        end
        if(checked!=WORDS)$fatal(1,"count mismatch");
        $display("PASS words=%0d stall_checks=%0d latch_checks=%0d",checked,stall_checks,latch_checks);
        $finish;
    end
    always @(posedge clk)begin
        cycles=cycles+1;if(cycles>2000000)$fatal(1,"runtime timeout");
    end
endmodule
