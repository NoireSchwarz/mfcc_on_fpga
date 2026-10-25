`timescale 1ns/1ps
module cores_tb;
    parameter DATA_W=16, COEF_W=20, ACC_W=48, COEF_FRAC=14;
    parameter USE_COEFF_PORT=1, DCT_IN_W=22, VECTORS=1600;
    localparam SOUT=24, DOUT=DCT_IN_W+4;
    reg clk=0; always #5 clk=~clk;
    reg rst=1, ed=1, in_valid=0;
    reg [2:0] tag=0;
    reg signed [DATA_W-1:0] sx[0:7];
    reg signed [DCT_IN_W-1:0] dx[0:7];
    reg [64*COEF_W-1:0] coeff=0;
    wire [8*SOUT-1:0] sy,sy_ref;
    wire [8*DOUT-1:0] dy,dy_ref;
    wire sv,dv; wire [2:0] st,dt;
    reg [8*SOUT-1:0] sq[0:4095];
    reg [8*DOUT-1:0] dq[0:4095];
    reg [2:0] tags_s[0:4095],tags_d[0:4095];
    integer due_s[0:4095],due_d[0:4095];
    integer sr=0,sw=0,dr=0,dw=0,ticks=0,checks_s=0,checks_d=0;
    integer pauses=0,flushes=0,i,j,n;
    reg prev_sv=0,prev_dv=0;
    reg [8*SOUT-1:0] prev_sy;
    reg [8*DOUT-1:0] prev_dy;
    reg [2:0] prev_st,prev_dt;
    reg [31:0] rng=32'h3e91b7a5;
    reg want_s,want_d;
    skewdct8 #(.DATA_W(DATA_W),.COEF_W(COEF_W),.ACC_W(ACC_W),
        .COEF_FRAC(COEF_FRAC),.OUT_W(SOUT),.USE_COEFF_PORT(USE_COEFF_PORT)) skew(
        .CLK(clk),.RST(rst),.ED(ed),.in_valid(in_valid),.in_tag(tag),.out_valid(sv),.out_tag(st),
        .x0(sx[0]),.x1(sx[1]),.x2(sx[2]),.x3(sx[3]),.x4(sx[4]),.x5(sx[5]),.x6(sx[6]),.x7(sx[7]),
        .y0(sy[0*SOUT+:SOUT]),.y1(sy[1*SOUT+:SOUT]),.y2(sy[2*SOUT+:SOUT]),.y3(sy[3*SOUT+:SOUT]),
        .y4(sy[4*SOUT+:SOUT]),.y5(sy[5*SOUT+:SOUT]),.y6(sy[6*SOUT+:SOUT]),.y7(sy[7*SOUT+:SOUT]),.c_in(coeff));
    skewdct8_reference #(.DATA_W(DATA_W),.COEF_W(COEF_W),.ACC_W(ACC_W),
        .COEF_FRAC(COEF_FRAC),.OUT_W(SOUT),.USE_COEFF_PORT(USE_COEFF_PORT)) skew_ref(
        .x0(sx[0]),.x1(sx[1]),.x2(sx[2]),.x3(sx[3]),.x4(sx[4]),.x5(sx[5]),.x6(sx[6]),.x7(sx[7]),
        .y0(sy_ref[0*SOUT+:SOUT]),.y1(sy_ref[1*SOUT+:SOUT]),.y2(sy_ref[2*SOUT+:SOUT]),.y3(sy_ref[3*SOUT+:SOUT]),
        .y4(sy_ref[4*SOUT+:SOUT]),.y5(sy_ref[5*SOUT+:SOUT]),.y6(sy_ref[6*SOUT+:SOUT]),.y7(sy_ref[7*SOUT+:SOUT]),.c_in(coeff));
    dct8_parallel #(.IN_W(DCT_IN_W),.OUT_W(DOUT)) dct(
        .CLK(clk),.RST(rst),.ED(ed),.in_valid(in_valid),.in_tag(tag),.out_valid(dv),.out_tag(dt),
        .x0(dx[0]),.x1(dx[1]),.x2(dx[2]),.x3(dx[3]),.x4(dx[4]),.x5(dx[5]),.x6(dx[6]),.x7(dx[7]),
        .y0(dy[0*DOUT+:DOUT]),.y1(dy[1*DOUT+:DOUT]),.y2(dy[2*DOUT+:DOUT]),.y3(dy[3*DOUT+:DOUT]),
        .y4(dy[4*DOUT+:DOUT]),.y5(dy[5*DOUT+:DOUT]),.y6(dy[6*DOUT+:DOUT]),.y7(dy[7*DOUT+:DOUT]));
    dct8_parallel_reference #(.IN_W(DCT_IN_W),.OUT_W(DOUT)) dct_ref(
        .x0(dx[0]),.x1(dx[1]),.x2(dx[2]),.x3(dx[3]),.x4(dx[4]),.x5(dx[5]),.x6(dx[6]),.x7(dx[7]),
        .y0(dy_ref[0*DOUT+:DOUT]),.y1(dy_ref[1*DOUT+:DOUT]),.y2(dy_ref[2*DOUT+:DOUT]),.y3(dy_ref[3*DOUT+:DOUT]),
        .y4(dy_ref[4*DOUT+:DOUT]),.y5(dy_ref[5*DOUT+:DOUT]),.y6(dy_ref[6*DOUT+:DOUT]),.y7(dy_ref[7*DOUT+:DOUT]));

    // Queue results from the untouched combinational cores at acceptance time.
    // Due dates count enabled edges, rather than assuming wall-clock latency.
    always @(posedge clk) begin
        if(rst) begin
            sr=0;sw=0;dr=0;dw=0;ticks=0;flushes=flushes+1;
            #1;
            if(sv!==0 || dv!==0) $fatal(1,"pipeline valid not flushed by reset");
        end else if(ed) begin
            ticks=ticks+1;
            if(in_valid) begin
                sq[sw]=sy_ref;tags_s[sw]=tag;due_s[sw]=ticks+5;sw=sw+1;
                dq[dw]=dy_ref;tags_d[dw]=tag;due_d[dw]=ticks+8;dw=dw+1;
            end
            want_s=(sr<sw && due_s[sr]==ticks);
            want_d=(dr<dw && due_d[dr]==ticks);
            #1;
            if(sv!==want_s || dv!==want_d) $fatal(1,"incorrect valid latency tick=%0d",ticks);
            if(want_s) begin
                if(sy!==sq[sr] || st!==tags_s[sr]) $fatal(1,"SkewDCT8 mismatch tick=%0d got=%h expected=%h",ticks,sy,sq[sr]);
                sr=sr+1;checks_s=checks_s+1;
            end
            if(want_d) begin
                if(dy!==dq[dr] || dt!==tags_d[dr]) $fatal(1,"DCT8 mismatch tick=%0d got=%h expected=%h",ticks,dy,dq[dr]);
                dr=dr+1;checks_d=checks_d+1;
            end
        end else begin
            #1;
            if(sv!==prev_sv || dv!==prev_dv) $fatal(1,"valid advanced with ED=0");
            if(prev_sv && (sy!==prev_sy || st!==prev_st)) $fatal(1,"SkewDCT8 advanced with ED=0");
            if(prev_dv && (dy!==prev_dy || dt!==prev_dt)) $fatal(1,"DCT8 advanced with ED=0");
            pauses=pauses+1;
        end
        prev_sv=sv;prev_dv=dv;prev_sy=sy;prev_dy=dy;prev_st=st;prev_dt=dt;
    end
    initial begin
        for(i=0;i<8;i=i+1) begin sx[i]=0;dx[i]=0;end
        repeat(4) @(negedge clk);
        rst=0;
        for(n=0;n<VECTORS;n=n+1) begin
            @(negedge clk);
            rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
            ed=(n<64 || rng[1:0]!=0);
            in_valid=(n<64 || rng[4:2]!=0);
            tag=rng[7:5];
            // Reset during live traffic, including a reset while ED is low.
            rst=(n==310 || n==311 || n==850 || n==851);
            if(n==850 || n==851) ed=0;
            for(i=0;i<8;i=i+1) begin
                case(n%20)
                    0: begin sx[i]=0;dx[i]=0;end
                    1: begin sx[i]={1'b1,{DATA_W-1{1'b0}}};dx[i]={1'b1,{DCT_IN_W-1{1'b0}}};end
                    2: begin sx[i]={1'b0,{DATA_W-1{1'b1}}};dx[i]={1'b0,{DCT_IN_W-1{1'b1}}};end
                    3: begin sx[i]=(i%2)?-1:1;dx[i]=(i%2)?-1:1;end
                    default: begin sx[i]=$random;dx[i]=$random;end
                endcase
            end
            for(j=0;j<64;j=j+1) begin
                case(n%16)
                    0: coeff[j*COEF_W+:COEF_W]=0;
                    1: coeff[j*COEF_W+:COEF_W]={1'b1,{COEF_W-1{1'b0}}};
                    2: coeff[j*COEF_W+:COEF_W]={1'b0,{COEF_W-1{1'b1}}};
                    default: coeff[j*COEF_W+:COEF_W]=$random;
                endcase
            end
        end
        @(negedge clk);rst=0;ed=1;in_valid=0;
        repeat(20) @(negedge clk);
        if(sr!=sw || dr!=dw) $fatal(1,"pipeline did not drain");
        if(checks_s<500 || checks_d<500 || pauses==0) $fatal(1,"insufficient coverage");
        $display("PASS cores skew_vectors=%0d dct_vectors=%0d pauses=%0d reset_edges=%0d",checks_s,checks_d,pauses,flushes);
        $finish;
    end
endmodule
