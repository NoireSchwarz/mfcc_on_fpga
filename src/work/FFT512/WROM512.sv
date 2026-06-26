// SystemVerilog ROM table loaded with $readmemh
`timescale 1 ns / 1 ps

module WROM512(
                    WI,
                    WR,
                    ADDR
                    );

parameter TW = 16;
parameter COS_FILE = "work/WROM512_cos.mem";
parameter SIN_FILE = "work/WROM512_sin.mem";

input [7:0] ADDR;
output signed [TW-1:0] WI;
output signed [TW-1:0] WR;

wire [7:0] ADDR;
wire signed [TW-1:0] WI;
wire signed [TW-1:0] WR;

logic [15:0] cosw [0:255];
logic [15:0] sinw [0:255];

initial begin
    $readmemh(COS_FILE, cosw);
    $readmemh(SIN_FILE, sinw);
end

logic [15:0] wri, wii;
assign wri = cosw[ADDR];
assign wii = sinw[ADDR];

logic [TW:0] wrt, wit;
assign wrt = wri[15:16-TW];
assign wit = wii[15:16-TW];
assign WR = wrt[TW-1:0];
assign WI = wit[TW-1:0];

endmodule
