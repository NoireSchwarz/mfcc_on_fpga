`timescale 1ns/1ps
// Adapter for fft_16_64's original complex START/RDY protocol.
// RDY precedes the first registered DOR/DOI by one enabled clock.
module fft64_bram_legacy(
    input CLK,input RST,input ED,input START,
    input signed [15:0] DIR,input signed [15:0] DII,
    output reg RDY,output reg signed [19:0] DOR,output reg signed [19:0] DOI
);
    localparam IDLE=0,FEED=1,WAIT_RESULT=2,DRAIN=3;
    reg [1:0] state;
    reg [5:0] count;
    wire [31:0] result;
    wire valid,ready,last,busy;
    wire [2:0] active_size;
    fft_tree_bram_engine #(.MAX_LOG2(7),.COMPLEX_INPUT(1)) engine_i(
        .clk(CLK),.resetn(!RST),.size_sel(3'd2),
        .s_data(DIR),.s_imag(DII),.s_valid(state==FEED && ED),.s_ready(ready),
        .m_data(result),.m_valid(valid),.m_ready(state==DRAIN && ED),
        .m_last(last),.busy(busy),.size_active_o(active_size));
    always @(posedge CLK) if(RST)begin
        state<=IDLE;count<=0;RDY<=0;DOR<=0;DOI<=0;
    end else if(ED)begin
        RDY<=0;
        case(state)
            IDLE:if(START)begin count<=0;state<=FEED;end
            FEED:if(ready)begin
                if(count==63)begin count<=0;state<=WAIT_RESULT;end
                else count<=count+1'b1;
            end
            WAIT_RESULT:if(valid)begin RDY<=1;state<=DRAIN;end
            DRAIN:if(valid)begin
                DOR<={result[15:0],4'b0000};DOI<={result[31:16],4'b0000};
                if(last)state<=IDLE;
            end
            default:state<=IDLE;
        endcase
    end
endmodule
