`timescale 1ns/1ps
module legacy_reference_tb;
    parameter N=64;
    parameter FRAMES=8;
    reg clk=0; always #5 clk=~clk;
    reg rst=1,in_valid=0,out_ready=0;
    wire in_ready,out_valid;
    reg [N*16-1:0] frame_data;
    wire [N*16-1:0] result_re,result_im;
    reg [15:0] samples[0:N*FRAMES-1];
    integer f,k,fd,cycles,started;
    fft512 #(.N(N)) dut(.clk(clk),.fft_reset(rst),.reset(1'b0),
        .in_valid(in_valid),.in_ready(in_ready),.fft_real_in(frame_data),
        .out_valid(out_valid),.out_ready(out_ready),
        .fft_out_re(result_re),.fft_out_im(result_im));
    initial begin
        $readmemh("input.mem",samples);fd=$fopen("legacy.hex","w");cycles=0;
        repeat(8)@(negedge clk);rst=0;
        for(f=0;f<FRAMES;f=f+1)begin
            for(k=0;k<N;k=k+1)frame_data[(N-1-k)*16+:16]=samples[f*N+k];
            @(negedge clk);in_valid=1;out_ready=0;
            @(posedge clk);while(!in_ready)@(posedge clk);
            started=cycles;
            @(negedge clk);in_valid=0;
            @(posedge clk);while(!out_valid)@(posedge clk);
            for(k=0;k<N;k=k+1)begin
                if((^result_re[(N-1-k)*16+:16])===1'bx ||
                   (^result_im[(N-1-k)*16+:16])===1'bx)$fatal(1,"Unknown legacy output");
                $fdisplay(fd,"%04x%04x",result_im[(N-1-k)*16+:16],result_re[(N-1-k)*16+:16]);
            end
            $display("LEGACY N=%0d frame=%0d cycles=%0d",N,f,cycles-started);
            repeat(3)@(negedge clk);
            out_ready=1;@(negedge clk);out_ready=0;
        end
        $fclose(fd);$finish;
    end
    always @(posedge clk)begin
        cycles=cycles+1;if(cycles>500000)$fatal(1,"legacy timeout");
    end
endmodule
