`timescale 1ns/1ps
// Legacy module/file name retained for source-list compatibility.
// Each word is a separate flip-flop bank; reads use a combinational mux.
module dct64_ram64 #(
    parameter DATA_W = 16
)(
    input wire CLK, WE,
    input wire [5:0] ADDRW,
    input wire [DATA_W-1:0] DI,
    input wire RE,
    input wire [5:0] ADDRR,
    output wire signed [DATA_W-1:0] DO
);
    wire [DATA_W-1:0] read_word [0:63];
    genvar word;
    generate
        for(word=0;word<64;word=word+1) begin : GEN_WORD
            reg [DATA_W-1:0] word_q;
            always @(posedge CLK)
                if(WE && (ADDRW == word)) word_q <= DI;
            assign read_word[word] = word_q;
        end
    endgenerate
    // RE is retained as a legacy interface pin. ADDRR selects continuously.
    // The controller holds ADDRR while a valid output is backpressured.
    assign DO = read_word[ADDRR];
endmodule
