`timescale 1ns/1ps
// Asynchronous LUT ROM: no block-RAM read/output stage.
module dct64_coeff_rom #(
    parameter DATA_W = 20,
    parameter COEFF_FILE = "dct64_coeff_q14.mem"
)(
    input wire CLK, ED,
    input wire [11:0] ADDR,
    output wire signed [DATA_W-1:0] DOUT
);
    (* rom_style = "distributed" *)
    reg signed [DATA_W-1:0] coeff_mem [0:4095];
    initial $readmemh(COEFF_FILE, coeff_mem);
    // CLK/ED pins remain for source compatibility; the product register
    // in dct64_matrix_datapath captures the selected coefficient/sample.
    assign DOUT = coeff_mem[ADDR];
endmodule
