// SystemVerilog ROM table loaded with $readmemh
`timescale 1 ns / 1 ps

module WROM256(
                    WI,
                    WR,
                    ADDR
                    );

parameter nw = 10;
parameter COS_FILE = "work/WROM256_cos.mem";
`ifdef FFT256paramifft
parameter SIN_FILE = "work/WROM256_sin_ifft.mem";
`else
parameter SIN_FILE = "work/WROM256_sin_fft.mem";
`endif

input [7:0] ADDR;
output [nw-1:0] WI;
output [nw-1:0] WR;

wire [7:0] ADDR;
wire [nw-1:0] WI;
wire [nw-1:0] WR;

logic [15:0] cosw [0:255];
logic [15:0] sinw [0:255];

initial begin
    $readmemh(COS_FILE, cosw);
    $readmemh(SIN_FILE, sinw);
end

logic [15:0] wri, wii;
assign wri = cosw[ADDR];
assign wii = sinw[ADDR];

logic [nw:0] wrt, wit;
assign wrt = wri[15:16-nw];
assign wit = wii[15:16-nw];
assign WR = wrt[nw-1:0];
assign WI = wit[nw-1:0];

endmodule
