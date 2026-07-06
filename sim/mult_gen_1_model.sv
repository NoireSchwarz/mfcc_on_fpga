`timescale 1ns / 1ps

module mult_gen_1 (
    input  logic        CLK,
    input  logic [31:0] A,
    input  logic [15:0] B,
    output logic [31:0] P
);
    logic [47:0] product;

    assign product = A * B;

    always_ff @(posedge CLK) begin
        P <= product >> 15;
    end
endmodule
