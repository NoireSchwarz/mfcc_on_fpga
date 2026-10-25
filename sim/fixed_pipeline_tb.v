`timescale 1ns/1ps
module fixed_pipeline_tb;
    parameter N=512,FRAMES=8,POWER=0,STALLS=1;
    localparam OUT_N=POWER?N/2:N;
    reg clk=0;always #5 clk=~clk;
    reg reset=1,s_valid=0,m_ready=0;
    reg [15:0] s_data=0;
    wire s_ready,m_valid,m_last;
    wire [31:0] m_data;
    reg [15:0] samples[0:N*FRAMES-1];
    reg [31:0] expected[0:OUT_N*FRAMES-1];
    reg [31:0] rng=32'h14a4beef,held_data;
    reg held,held_last;
    integer f,sent,got,cycles,checks,stalls;
    generate if(POWER)begin:gen_power
        power_spectrum #(.N(N)) dut(.clk(clk),.reset(reset),.in(s_data),.out(m_data),
            .s_valid(s_valid),.s_ready(s_ready),.s_last(1'b0),
            .m_ready(m_ready),.m_valid(m_valid),.m_last(m_last));
    end else begin:gen_fft
        fft512 #(.N(N)) dut(.clk(clk),.reset(reset),.s_data(s_data),
            .s_valid(s_valid),.s_ready(s_ready),.m_data(m_data),
            .m_ready(m_ready),.m_valid(m_valid),.m_last(m_last));
    end endgenerate
    initial begin
        cycles=0;checks=0;stalls=0;held=0;
        $readmemh("input.mem",samples);$readmemh("expected.mem",expected);
        repeat(6)@(negedge clk);reset=0;
        for(f=0;f<FRAMES;f=f+1)begin
            sent=0;got=0;held=0;
            while(got<OUT_N)begin
                @(negedge clk);
                rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
                s_valid=(sent<N)&&(!STALLS || rng[1:0]!=0);
                if(sent<N)s_data=samples[f*N+sent];
                m_ready=!STALLS || (rng[4:2]!=0 && cycles%101>17);
                @(posedge clk);
                if(held)begin
                    if(!m_valid || m_data!==held_data || m_last!==held_last)
                        $fatal(1,"unstable fixed output N=%0d POWER=%0d",N,POWER);
                    stalls=stalls+1;
                end
                held=m_valid&&!m_ready;held_data=m_data;held_last=m_last;
                if(s_valid&&s_ready)sent=sent+1;
                if(m_valid)begin
                    if(sent!=N)$fatal(1,"premature fixed output");
                    if(m_last!==(got==OUT_N-1))$fatal(1,"fixed TLAST mismatch");
                    if(m_ready)begin
                        if(m_data!==expected[f*OUT_N+got])
                            $fatal(1,"fixed mismatch N=%0d power=%0d frame=%0d k=%0d got=%h expected=%h",N,POWER,f,got,m_data,expected[f*OUT_N+got]);
                        got=got+1;checks=checks+1;
                    end
                end
            end
        end
        @(negedge clk);s_valid=0;m_ready=1;
        repeat(4)begin
            @(posedge clk);if(m_valid)$fatal(1,"extra fixed output");@(negedge clk);
        end
        $display("PASS N=%0d power=%0d words=%0d stalls=%0d cycles=%0d",N,POWER,checks,stalls,cycles);
        $finish;
    end
    always @(posedge clk)begin
        cycles=cycles+1;if(cycles>1000000)$fatal(1,"fixed pipeline timeout");
        if(reset && (m_valid || s_ready))$fatal(1,"fixed handshake during reset");
    end
endmodule
