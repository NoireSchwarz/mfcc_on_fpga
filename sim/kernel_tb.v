`timescale 1ns/1ps
module kernel_tb;
    parameter NB=16,TW=16,CASES=1024;
    reg clk=0;always #5 clk=~clk;
    reg rst=1,start=0;
    reg [1:0] mode=0;
    reg signed [NB-1:0] xr[0:3],xi[0:3];
    reg signed [TW-1:0] wr[1:3],wi[1:3];
    wire valid,busy,ref_valid,ref_busy;
    wire [8*NB-1:0] y,ref_y;
    reg [8*NB-1:0] expected,previous;
    localparam signed [NB-1:0] XMIN={1'b1,{NB-1{1'b0}}},XMAX={1'b0,{NB-1{1'b1}}};
    localparam signed [TW-1:0] WMIN={1'b1,{TW-1{1'b0}}},WMAX={1'b0,{TW-1{1'b1}}};
    integer i,j,c,abort_at,latency,old_latency,seen,seen_ref,checked=0,resets=0;
    fft_merge_kernel #(.NB(NB),.TW(TW)) dut(
        .clk(clk),.rst(rst),.start(start),.mode(mode),
        .x0_re(xr[0]),.x0_im(xi[0]),.x1_re(xr[1]),.x1_im(xi[1]),
        .x2_re(xr[2]),.x2_im(xi[2]),.x3_re(xr[3]),.x3_im(xi[3]),
        .w1_re(wr[1]),.w1_im(wi[1]),.w2_re(wr[2]),.w2_im(wi[2]),.w3_re(wr[3]),.w3_im(wi[3]),
        .valid(valid),.busy(busy),.y0_re(y[0*NB+:NB]),.y0_im(y[1*NB+:NB]),
        .y1_re(y[2*NB+:NB]),.y1_im(y[3*NB+:NB]),.y2_re(y[4*NB+:NB]),.y2_im(y[5*NB+:NB]),.y3_re(y[6*NB+:NB]),.y3_im(y[7*NB+:NB]));
    fft_merge_kernel_reference #(.NB(NB),.TW(TW)) reference(
        .clk(clk),.rst(rst),.start(start),.mode(mode),
        .x0_re(xr[0]),.x0_im(xi[0]),.x1_re(xr[1]),.x1_im(xi[1]),
        .x2_re(xr[2]),.x2_im(xi[2]),.x3_re(xr[3]),.x3_im(xi[3]),
        .w1_re(wr[1]),.w1_im(wi[1]),.w2_re(wr[2]),.w2_im(wi[2]),.w3_re(wr[3]),.w3_im(wi[3]),
        .valid(ref_valid),.busy(ref_busy),.y0_re(ref_y[0*NB+:NB]),.y0_im(ref_y[1*NB+:NB]),
        .y1_re(ref_y[2*NB+:NB]),.y1_im(ref_y[3*NB+:NB]),.y2_re(ref_y[4*NB+:NB]),.y2_im(ref_y[5*NB+:NB]),.y3_re(ref_y[6*NB+:NB]),.y3_im(ref_y[7*NB+:NB]));

    task drive_data;
        input integer pattern;
        integer k;
        begin
            for(k=0;k<4;k=k+1) begin
                case(pattern)
                    0:begin xr[k]=0;xi[k]=0;end
                    1:begin xr[k]=XMAX;xi[k]=XMAX;end
                    2:begin xr[k]=XMIN;xi[k]=XMIN;end
                    3:begin xr[k]=(k==0)?XMAX:0;xi[k]=0;end
                    4:begin xr[k]=(k%2)?-1:1;xi[k]=(k%2)?1:-1;end
                    5:begin xr[k]=XMIN;xi[k]=XMAX;end
                    6:begin xr[k]=XMIN;xi[k]=0;end
                    7:begin xr[k]=XMAX;xi[k]=0;end
                    default:begin xr[k]={$random,$random};xi[k]={$random,$random};end
                endcase
            end
            for(k=1;k<4;k=k+1) begin
                case(pattern)
                    0:begin wr[k]=0;wi[k]=0;end
                    1,7:begin wr[k]=WMAX;wi[k]=WMAX;end
                    2,5:begin wr[k]=WMIN;wi[k]=WMIN;end
                    3:begin wr[k]=WMAX;wi[k]=0;end
                    4:begin wr[k]=(k%2)?WMIN:WMAX;wi[k]=(k%2)?WMAX:WMIN;end
                    6:begin wr[k]=WMIN;wi[k]=0;end
                    default:begin wr[k]={$random,$random};wi[k]={$random,$random};end
                endcase
            end
        end
    endtask
    task reset_both;
        begin
            @(negedge clk);rst=1;start=0;
            repeat(2) begin
                @(posedge clk);#1;
                if(valid!==0 || busy!==0 || y!==0 || ref_valid!==0 || ref_busy!==0 || ref_y!==0) $fatal(1,"bad kernel reset");
                @(negedge clk);
            end
            rst=0;resets=resets+1;
        end
    endtask
    initial begin
        drive_data(0);reset_both();
        // Reset each pipeline phase, including partial butterflies and saturation.
        for(abort_at=1;abort_at<=7;abort_at=abort_at+1) begin
            @(negedge clk);drive_data(8);mode=2;start=1;
            @(posedge clk);#1;
            @(negedge clk);start=0;
            repeat(abort_at) @(negedge clk);
            reset_both();
            repeat(9) begin @(posedge clk);#1;if(valid || busy) $fatal(1,"stale transaction after reset");end
        end
        for(c=0;c<CASES;c=c+1) begin
            @(negedge clk);drive_data(c%16);mode=c%4;start=1;previous=y;
            latency=(mode==0)?3:(mode==1)?4:7;
            old_latency=(mode==0 || mode==1)?1:4;
            seen=0;seen_ref=0;
            @(posedge clk);#1;
            if(busy!==1 || valid!==0 || ref_busy!==1) $fatal(1,"start not accepted");
            for(j=1;j<=9;j=j+1) begin
                @(negedge clk);start=0;
                // Inputs change even while busy. Old x2/w2 and x3/w3 sample
                // edges must still be respected; mode/start data are latched.
                drive_data(c%16);mode=$random;
                @(posedge clk);#1;
                if(ref_valid) begin
                    if(seen_ref || j!=old_latency) $fatal(1,"bad original latency");
                    expected=ref_y;seen_ref=1;
                end
                if(valid) begin
                    if(seen || j!=latency || !seen_ref || busy) $fatal(1,"bad registered kernel control");
                    if(y!==expected || (^y)===1'bx) $fatal(1,"kernel mismatch case=%0d NB=%0d TW=%0d got=%h expected=%h",c,NB,TW,y,expected);
                    seen=1;checked=checked+1;
                end
                if(j<latency && (busy!==1 || y!==previous)) $fatal(1,"premature output / busy drop");
                if(j>latency && busy) $fatal(1,"busy stuck");
            end
            if(!seen || !seen_ref) $fatal(1,"missing kernel result");
        end
        $display("PASS kernel NB=%0d TW=%0d cases=%0d reset_scenarios=%0d changing_busy_inputs=1",NB,TW,checked,resets);
        $finish;
    end
endmodule
