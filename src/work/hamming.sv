`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/15/2019 12:19:58 AM
// Design Name:
// Module Name: hamming
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module hamming #(
    parameter int N = 512,
    parameter COEFF_FILE = "hamming_coeff_rom.mem"
)(
    input  logic        clk,
    input  logic        reset,
    input  logic [15:0] in,
    output logic [15:0] out,
    input  logic        on
);

    localparam int ROM_COLS = 2048;
    localparam int ROM_ROWS = 8;
    localparam int ROM_DEPTH = ROM_ROWS * ROM_COLS;
    localparam int ROW_IDX = $clog2(N) - 4;


    logic [15:0] coeff_rom [0:ROM_DEPTH-1];
    logic [15:0] shift_reg [0:N-1];
    logic [30:0] result;

    initial begin
        $readmemh(COEFF_FILE, coeff_rom);
        for (int i = 0; i < N; i++) begin
            shift_reg[i] = coeff_rom[(ROW_IDX * ROM_COLS) + i];
        end
    end

    assign result = $signed(shift_reg[0]) * $signed(in);
    assign out = result >> 14;

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < N; i++) begin
                shift_reg[i] <= coeff_rom[(ROW_IDX * ROM_COLS) + i];
            end
        end else if (on) begin
            shift_reg[0] <= shift_reg[N-1];
            shift_reg[1:N-1] <= shift_reg[0:N-2];
        end
    end
endmodule
