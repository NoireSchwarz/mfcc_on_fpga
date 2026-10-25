`timescale 1ns/1ps
// BRAM-backed real-input doubling backend (module name retained: fft2).
// The producer writes its complex M-point FFT directly into this cache.
// start is issued only after the last cache write. pair_real selects either
// direct readout or conjugate split + radix2 reconstruction (N=2*M).
// The merge arithmetic is shared with radix4 in fft_tree_bram_engine.
module fft2 #(
    parameter integer MAX_LOG2=11,
    parameter integer HALF_SPECTRUM=0
)(
    input clk,input resetn,input start,input pair_real,
    input [MAX_LOG2-2:0] base_last,
    input [MAX_LOG2-1:0] output_last,input [3:0] tw_shift,
    input cache_we,input [MAX_LOG2-2:0] cache_waddr,input [31:0] cache_wdata,
    output merge_start,output [10:0] merge_tw_address,
    output reg signed [15:0] even_re,even_im,odd_re,odd_im,
    input merge_valid,input [31:0] merge_lo,input [31:0] merge_hi,
    output [31:0] m_data,output m_valid,input m_ready,output m_last,
    output done
);
    localparam integer AW=MAX_LOG2-1;
    localparam IDLE=0,PAIR_READ=1,PAIR_SPLIT=2,PAIR_LAUNCH=3,
        PAIR_WAIT=4,OUTPUT_PREP=5,OUTPUT=6;
    reg [2:0] state;
    reg [AW-1:0] bin_index;
    reg [MAX_LOG2-1:0] output_index;
    wire [MAX_LOG2-1:0] next_output=output_index+1'b1;
    wire [AW-1:0] output_address=(state==OUTPUT && m_ready)?
        (next_output[AW-1:0]&base_last):(output_index[AW-1:0]&base_last);
    wire [AW-1:0] cache_raddr=(!pair_real && (state==OUTPUT_PREP || state==OUTPUT))?
        output_address:bin_index;
    wire [AW-1:0] sym_address=(-bin_index)&base_last;
    wire [31:0] value_k,value_sym,output_q_lo,output_q_hi;
    fft_bram_1w1r #(.AW(AW)) cache_a(
        .clk(clk),.wr_en(resetn&&cache_we),.wr_addr(cache_waddr),.wr_data(cache_wdata),
        .rd_addr(cache_raddr),.rd_data(value_k));
    fft_bram_1w1r #(.AW(AW)) cache_b(
        .clk(clk),.wr_en(resetn&&cache_we),.wr_addr(cache_waddr),.wr_data(cache_wdata),
        .rd_addr(sym_address),.rd_data(value_sym));
    wire signed [16:0] yr={value_k[15],value_k[15:0]};
    wire signed [16:0] yi={value_k[31],value_k[31:16]};
    wire signed [16:0] ysr={value_sym[15],value_sym[15:0]};
    wire signed [16:0] ysi={value_sym[31],value_sym[31:16]};
    wire signed [16:0] er_sum=yr+ysr,ei_diff=yi-ysi;
    wire signed [16:0] or_sum=yi+ysi,oi_diff=ysr-yr;
    wire output_we=resetn && state==PAIR_WAIT && merge_valid;
    fft_bram_1w1r #(.AW(AW)) output_lo(
        .clk(clk),.wr_en(output_we),.wr_addr(bin_index),.wr_data(merge_lo),
        .rd_addr(output_address),.rd_data(output_q_lo));
    generate if(HALF_SPECTRUM==0)begin: gen_full_spectrum
        fft_bram_1w1r #(.AW(AW)) output_hi(
            .clk(clk),.wr_en(output_we),.wr_addr(bin_index),.wr_data(merge_hi),
            .rd_addr(output_address),.rd_data(output_q_hi));
    end else begin: gen_half_spectrum
        assign output_q_hi=32'd0;
    end endgenerate
    wire high_half=(output_index>{1'b0,base_last});
    assign merge_start=resetn && state==PAIR_LAUNCH;
    assign merge_tw_address={{(11-AW){1'b0}},bin_index}<<tw_shift;
    assign m_valid=resetn && state==OUTPUT;
    assign m_last=m_valid && output_index==output_last;
    assign m_data=pair_real?(high_half?output_q_hi:output_q_lo):value_k;
    assign done=m_valid && m_ready && m_last;
    always @(posedge clk) if(!resetn)begin
        state<=IDLE;bin_index<=0;output_index<=0;
        even_re<=0;even_im<=0;odd_re<=0;odd_im<=0;
    end else case(state)
        IDLE:if(start)begin
            bin_index<=0;output_index<=0;
            state<=pair_real?PAIR_READ:OUTPUT_PREP;
        end
        PAIR_READ:state<=PAIR_SPLIT;
        PAIR_SPLIT:begin
            even_re<=(bin_index==0)?value_k[15:0]:(er_sum>>>1);
            even_im<=(bin_index==0)?16'sd0:(ei_diff>>>1);
            odd_re<=(bin_index==0)?value_k[31:16]:(or_sum>>>1);
            odd_im<=(bin_index==0)?16'sd0:(oi_diff>>>1);
            state<=PAIR_LAUNCH;
        end
        PAIR_LAUNCH:state<=PAIR_WAIT;
        PAIR_WAIT:if(merge_valid)begin
            if(bin_index==base_last)begin output_index<=0;state<=OUTPUT_PREP;end
            else begin bin_index<=bin_index+1'b1;state<=PAIR_READ;end
        end
        OUTPUT_PREP:state<=OUTPUT;
        OUTPUT:if(m_ready)begin
            if(output_index==output_last)begin output_index<=0;state<=IDLE;end
            else output_index<=output_index+1'b1;
        end
        default:state<=IDLE;
    endcase
endmodule
