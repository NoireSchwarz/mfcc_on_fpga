`timescale 1ns/1ps
// Shared complex roots and optional radix4 expansion. All real doubling,
// spectral cache ownership and output streaming belong to fft2x.v (fft2).
// ROOT_FAMILY: 0=both runtime families, 1=FFT16 only, 2=FFT256 only.
module fft_tree_bram_engine #(
    parameter integer MAX_LOG2=11,
    parameter integer COMPLEX_INPUT=0,
    parameter integer ROOT_FAMILY=0,
    parameter integer HALF_SPECTRUM=0
)(
    input clk,input resetn,input [2:0] size_sel,
    input [15:0] s_data,input [15:0] s_imag,input s_valid,output s_ready,
    output [31:0] m_data,output m_valid,input m_ready,
    output m_last,output busy,output [2:0] size_active_o
);
    localparam integer AW=MAX_LOG2-1;
    localparam integer LDEPTH=(MAX_LOG2>7)?256:16;
    localparam LOAD=0,ROOT_PREFETCH=1,ROOT_START=2,ROOT_FEED=3,
        ROOT_WAIT=4,ROOT_CAPTURE=5,NEXT_LANE=6,
        R4_READ=7,R4_LAUNCH=8,R4_WAIT=9,
        R4_STORE1=10,R4_STORE2=11,R4_STORE3=12,
        POST_START=13,POST_WAIT=14;
    reg [3:0] state;
    reg [2:0] size_active;
    reg [MAX_LOG2-1:0] input_index;
    reg [AW-1:0] sample_index,bin_index;
    reg [1:0] lane_index;
    reg [15:0] even_input;
    wire [2:0] load_size=(input_index==0)?size_sel:size_active;
    wire family_valid=(ROOT_FAMILY==0) ||
        ((ROOT_FAMILY==1)&&!load_size[2]) || ((ROOT_FAMILY==2)&&load_size[2]);
    wire config_valid=(load_size+4<=MAX_LOG2)&&family_valid;
    wire [MAX_LOG2-1:0] load_last=(16<<load_size)-1;
    wire [MAX_LOG2-1:0] output_last=((16<<size_active)>>HALF_SPECTRUM)-1;
    wire family256=size_active[2],expand4=size_active[1],pair_real=size_active[0];
    wire [AW-1:0] root_last=family256?255:15;
    wire [AW-1:0] base_last=family256?(expand4?1023:255):(expand4?63:15);
    wire [AW-1:0] root_points=family256?256:16;
    wire r4_phase=(state>=R4_READ && state<=R4_STORE3);
    assign s_ready=resetn && state==LOAD && config_valid;
    assign busy=resetn && (state!=LOAD || input_index!=0);
    assign size_active_o=size_active;

    wire [AW-1:0] prefetch_sample=(state==ROOT_FEED)?sample_index+1'b1:0;
    wire [AW-1:0] input_address=expand4?
        ((prefetch_sample<<2)|lane_index):prefetch_sample;
    wire input_we=s_valid && s_ready && (!load_size[0] || input_index[0]);
    wire [AW-1:0] input_waddr=load_size[0]?
        input_index[MAX_LOG2-1:1]:input_index[AW-1:0];
    wire [31:0] input_wdata=load_size[0]?{s_data,even_input}:
        {(COMPLEX_INPUT!=0)?s_imag:16'd0,s_data};
    wire [31:0] input_q;
    fft_bram_1w1r #(.AW(AW)) input_ram(
        .clk(clk),.wr_en(input_we),.wr_addr(input_waddr),.wr_data(input_wdata),
        .rd_addr(input_address),.rd_data(input_q));

    reg root_start;
    reg signed [15:0] root_in_re,root_in_im;
    wire root16_ready,root256_ready;
    wire signed [19:0] root16_re,root16_im;
    wire signed [15:0] root256_re,root256_im;
    wire root_ready=family256?root256_ready:root16_ready;
    wire [31:0] root_value=family256?{root256_im,root256_re}:
        {root16_im[19:4],root16_re[19:4]};
    generate if(ROOT_FAMILY!=2)begin:gen_root16
        FFT16 #(.nb(16)) root16_i(
            .CLK(clk),.RST(!resetn),.ED(1'b1),.START(root_start&&!family256),
            .DIR(root_in_re),.DII(root_in_im),.RDY(root16_ready),
            .DOR(root16_re),.DOI(root16_im));
    end else begin:gen_no_root16
        assign root16_ready=1'b0;assign root16_re=20'd0;assign root16_im=20'd0;
    end
    if(MAX_LOG2>7 && ROOT_FAMILY!=1)begin:gen_root256
        fft256_1024 #(.NB(16),.TW(16),.N(256)) root256_i(
            .CLK(clk),.RST(!resetn),.ED(1'b1),.START(root_start&&family256),
            .DIR(root_in_re),.DII(root_in_im),.RDY(root256_ready),
            .DOR(root256_re),.DOI(root256_im));
    end else begin:gen_no_root256
        assign root256_ready=1'b0;assign root256_re=16'd0;assign root256_im=16'd0;
    end endgenerate

    wire lane_we=resetn && state==ROOT_CAPTURE && expand4;
    wire [AW-1:0] lane_raddr=bin_index&root_last;
    wire [31:0] lane_q0,lane_q1,lane_q2,lane_q3;
    fft_bram_1w1r #(.AW(AW),.DEPTH(LDEPTH)) lane0(
        .clk(clk),.wr_en(lane_we&&lane_index==0),.wr_addr(sample_index),.wr_data(root_value),
        .rd_addr(lane_raddr),.rd_data(lane_q0));
    fft_bram_1w1r #(.AW(AW),.DEPTH(LDEPTH)) lane1(
        .clk(clk),.wr_en(lane_we&&lane_index==1),.wr_addr(sample_index),.wr_data(root_value),
        .rd_addr(lane_raddr),.rd_data(lane_q1));
    fft_bram_1w1r #(.AW(AW),.DEPTH(LDEPTH)) lane2(
        .clk(clk),.wr_en(lane_we&&lane_index==2),.wr_addr(sample_index),.wr_data(root_value),
        .rd_addr(lane_raddr),.rd_data(lane_q2));
    fft_bram_1w1r #(.AW(AW),.DEPTH(LDEPTH)) lane3(
        .clk(clk),.wr_en(lane_we&&lane_index==3),.wr_addr(sample_index),.wr_data(root_value),
        .rd_addr(lane_raddr),.rd_data(lane_q3));

    wire post_merge_start,post_done;
    wire [10:0] post_tw_address;
    wire signed [15:0] even_re,even_im,odd_re,odd_im;
    wire [3:0] post_tw_shift=family256?(expand4?0:2):(expand4?4:6);
    wire [10:0] r4_tw_address={{(11-AW){1'b0}},bin_index}<<(family256?1:5);
    wire [10:0] tw1_address=r4_phase?r4_tw_address:post_tw_address;
    wire [10:0] tw2_address=tw1_address<<1;
    wire [10:0] tw3_address=tw1_address+tw2_address;
    wire signed [15:0] w1_re,w1_im,w2_re,w2_im,w3_re,w3_im;
    WROM2048 tw1_i(.ADDR(tw1_address),.WR(w1_re),.WI(w1_im));
    WROM2048 tw2_i(.ADDR(tw2_address),.WR(w2_re),.WI(w2_im));
    WROM2048 tw3_i(.ADDR(tw3_address),.WR(w3_re),.WI(w3_im));
    reg r4_kernel_start;
    wire kernel_valid,kernel_busy;
    wire signed [15:0] y0_re,y0_im,y1_re,y1_im,y2_re,y2_im,y3_re,y3_im;
    fft_merge_kernel #(.NB(16),.TW(16)) kernel_i(
        .clk(clk),.rst(!resetn),.start(r4_phase?r4_kernel_start:post_merge_start),
        .mode(r4_phase?2'd2:2'd1),
        .x0_re(r4_phase?lane_q0[15:0]:even_re),.x0_im(r4_phase?lane_q0[31:16]:even_im),
        .x1_re(r4_phase?lane_q1[15:0]:odd_re),.x1_im(r4_phase?lane_q1[31:16]:odd_im),
        .x2_re(lane_q2[15:0]),.x2_im(lane_q2[31:16]),
        .x3_re(lane_q3[15:0]),.x3_im(lane_q3[31:16]),
        .w1_re(w1_re),.w1_im(w1_im),.w2_re(w2_re),.w2_im(w2_im),
        .w3_re(w3_re),.w3_im(w3_im),.valid(kernel_valid),.busy(kernel_busy),
        .y0_re(y0_re),.y0_im(y0_im),.y1_re(y1_re),.y1_im(y1_im),
        .y2_re(y2_re),.y2_im(y2_im),.y3_re(y3_re),.y3_im(y3_im));

    reg cache_we;
    reg [AW-1:0] cache_waddr;
    reg [31:0] cache_wdata;
    always @* begin
        cache_we=1'b0;cache_waddr=sample_index;cache_wdata=root_value;
        if(state==ROOT_CAPTURE && !expand4)cache_we=1'b1;
        if(state==R4_WAIT && kernel_valid)begin
            cache_we=1'b1;cache_waddr=bin_index;cache_wdata={y0_im,y0_re};
        end
        if(state==R4_STORE1)begin
            cache_we=1'b1;cache_waddr=bin_index+root_points;cache_wdata={y1_im,y1_re};
        end
        if(state==R4_STORE2)begin
            cache_we=1'b1;cache_waddr=bin_index+(root_points<<1);cache_wdata={y2_im,y2_re};
        end
        if(state==R4_STORE3)begin
            cache_we=1'b1;cache_waddr=bin_index+root_points+(root_points<<1);cache_wdata={y3_im,y3_re};
        end
    end
    fft2 #(.MAX_LOG2(MAX_LOG2),.HALF_SPECTRUM(HALF_SPECTRUM)) fft2x_i(
        .clk(clk),.resetn(resetn),.start(state==POST_START),.pair_real(pair_real),
        .base_last(base_last),.output_last(output_last),.tw_shift(post_tw_shift),
        .cache_we(cache_we),.cache_waddr(cache_waddr),.cache_wdata(cache_wdata),
        .merge_start(post_merge_start),.merge_tw_address(post_tw_address),
        .even_re(even_re),.even_im(even_im),.odd_re(odd_re),.odd_im(odd_im),
        .merge_valid(kernel_valid),.merge_lo({y0_im,y0_re}),.merge_hi({y1_im,y1_re}),
        .m_data(m_data),.m_valid(m_valid),.m_ready(m_ready),.m_last(m_last),.done(post_done));

    always @(posedge clk) if(!resetn)begin
        state<=LOAD;size_active<=0;input_index<=0;sample_index<=0;bin_index<=0;
        lane_index<=0;even_input<=0;root_start<=0;root_in_re<=0;root_in_im<=0;r4_kernel_start<=0;
    end else begin
        root_start<=0;r4_kernel_start<=0;
        case(state)
            LOAD:if(s_valid && s_ready)begin
                if(input_index==0)size_active<=size_sel;
                if(load_size[0] && !input_index[0])even_input<=s_data;
                if(input_index==load_last)begin
                    input_index<=0;sample_index<=0;lane_index<=0;bin_index<=0;state<=ROOT_PREFETCH;
                end else input_index<=input_index+1'b1;
            end
            ROOT_PREFETCH:state<=ROOT_START;
            ROOT_START:begin root_start<=1;sample_index<=0;state<=ROOT_FEED;end
            ROOT_FEED:begin
                root_in_re<=input_q[15:0];root_in_im<=input_q[31:16];
                if(sample_index==root_last)begin sample_index<=0;state<=ROOT_WAIT;end
                else sample_index<=sample_index+1'b1;
            end
            ROOT_WAIT:if(root_ready)begin sample_index<=0;state<=ROOT_CAPTURE;end
            ROOT_CAPTURE:if(sample_index==root_last)begin
                sample_index<=0;bin_index<=0;state<=expand4?NEXT_LANE:POST_START;
            end else sample_index<=sample_index+1'b1;
            NEXT_LANE:if(lane_index==3)begin bin_index<=0;state<=R4_READ;end
                else begin lane_index<=lane_index+1'b1;state<=ROOT_PREFETCH;end
            R4_READ:state<=R4_LAUNCH;
            R4_LAUNCH:begin r4_kernel_start<=1;state<=R4_WAIT;end
            R4_WAIT:if(kernel_valid)state<=R4_STORE1;
            R4_STORE1:state<=R4_STORE2;
            R4_STORE2:state<=R4_STORE3;
            R4_STORE3:if(bin_index==root_last)begin bin_index<=0;state<=POST_START;end
                else begin bin_index<=bin_index+1'b1;state<=R4_READ;end
            POST_START:state<=POST_WAIT;
            POST_WAIT:if(post_done)state<=LOAD;
            default:state<=LOAD;
        endcase
    end
endmodule
