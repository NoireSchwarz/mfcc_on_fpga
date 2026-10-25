`timescale 1ns/1ps
module reference_stream_tb;
    parameter N=512,FRAMES=8;
    reg clk=0;always #5 clk=~clk;
    reg reset=1,s_valid=0;
    reg [15:0] s_data=0;
    wire s_ready,m_valid,m_last;
    wire [31:0] m_data;
    reg [15:0] samples[0:N*FRAMES-1];
    integer f,sent,got,cycles=0,fd,first,begin_cycle;
    fft512 #(.N(N)) dut(.clk(clk),.reset(reset),.s_data(s_data),.s_valid(s_valid),.s_ready(s_ready),
        .m_data(m_data),.m_valid(m_valid),.m_ready(1'b1),.m_last(m_last));
    always @(posedge clk) begin cycles=cycles+1;if(cycles>1000000)$fatal(1,"reference timeout");end
    initial begin
        fd=$fopen("reference.hex","w");$readmemh("input.mem",samples);
        repeat(6)@(negedge clk);reset=0;
        for(f=0;f<FRAMES;f=f+1)begin
            sent=0;got=0;first=-1;begin_cycle=cycles;
            while(got<N)begin
                @(negedge clk);s_valid=(sent<N);if(sent<N)s_data=samples[f*N+sent];
                @(posedge clk);
                if(s_valid&&s_ready)sent=sent+1;
                if(m_valid)begin
                    if(sent!=N || m_last!==(got==N-1) || (^m_data)===1'bx)$fatal(1,"bad reference stream");
                    if(first<0)first=cycles-begin_cycle;
                    $fwrite(fd,"%08x\n",m_data);got=got+1;
                end
            end
            $display("FRAME N=%0d frame=%0d first=%0d cycles=%0d",N,f,first,cycles-begin_cycle);
        end
        @(negedge clk);s_valid=0;
        repeat(4)begin @(posedge clk);if(m_valid)$fatal(1,"extra reference output");@(negedge clk);end
        $fclose(fd);$display("PASS reference N=%0d frames=%0d words=%0d",N,FRAMES,N*FRAMES);$finish;
    end
endmodule
