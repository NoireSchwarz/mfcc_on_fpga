// SystemVerilog ROM table loaded with $readmemh
`timescale 1 ns / 1 ps

module WROM2048(
    WI,
    WR,
    ADDR
);

parameter TW = 16;
parameter COS_FILE = "src/work/FFT512/WROM2048_cos.mem";
parameter SIN_FILE = "src/work/FFT512/WROM2048_sin.mem";

input [10:0] ADDR;
output signed [TW-1:0] WI;
output signed [TW-1:0] WR;

wire [10:0] ADDR;
wire signed [TW-1:0] WI;
wire signed [TW-1:0] WR;

logic [15:0] cosw [0:2047];
logic [15:0] sinw [0:2047];

initial begin
    $readmemh(COS_FILE, cosw);
    $readmemh(SIN_FILE, sinw);
end

logic [15:0] wri;
logic [15:0] wii;
assign wri = cosw[ADDR];
assign wii = sinw[ADDR];

logic [TW:0] wrt;
logic [TW:0] wit;
assign wrt = wri[15:16-TW];
assign wit = wii[15:16-TW];
assign WR = wrt[TW-1:0];
assign WI = wit[TW-1:0];

endmodule
