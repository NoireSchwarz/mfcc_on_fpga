`timescale 1ns/1ps
// One synchronous write port and one synchronous read port. No array reset.
module fft_bram_1w1r #(
    parameter integer WIDTH=32,
    parameter integer AW=10,
    parameter integer DEPTH=32'd1<<AW
)(
    input clk,input wr_en,input [AW-1:0] wr_addr,
    input [WIDTH-1:0] wr_data,input [AW-1:0] rd_addr,
    output reg [WIDTH-1:0] rd_data
);
    (* ram_style="block" *) reg [WIDTH-1:0] storage[0:DEPTH-1];
    always @(posedge clk) begin
        if(wr_en)storage[wr_addr]<=wr_data;
        rd_data<=storage[rd_addr];
    end
endmodule
