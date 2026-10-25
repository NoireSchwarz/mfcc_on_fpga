`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module fft256 (
	CLK,
	RST,
	ED,
	START,
	SHIFT,
	DR,
	DI,
	RDY,
	OVF1,
	OVF2,
	ADDR,
	O_fft_real,
	O_fft_imag
);
	parameter nb = 16;
	input wire CLK;
	input wire RST;
	input wire ED;
	input wire START;
	input wire [3:0] SHIFT;
	input wire [nb - 1:0] DR;
	input wire [nb - 1:0] DI;
	output wire RDY;
	output wire OVF1;
	output wire OVF2;
	output wire [7:0] ADDR;
	output wire [nb - 1:0] O_fft_real;
	output wire [nb - 1:0] O_fft_imag;
	wire [nb + 3:0] DOR;
	wire [nb + 3:0] DOI;
	wire [nb - 1:0] dr1;
	wire [nb - 1:0] di1;
	wire [nb + 1:0] dr3;
	wire [nb + 1:0] di3;
	wire [nb + 1:0] dr4;
	wire [nb + 1:0] di4;
	wire [nb + 1:0] dr5;
	wire [nb + 1:0] di5;
	wire [nb + 3:0] dr2;
	wire [nb + 3:0] di2;
	wire [nb + 5:0] dr6;
	wire [nb + 5:0] di6;
	wire [nb + 3:0] dr7;
	wire [nb + 3:0] di7;
	wire [nb + 3:0] dr8;
	wire [nb + 3:0] di8;
	wire rdy1;
	wire rdy2;
	wire rdy3;
	wire rdy4;
	wire rdy5;
	wire rdy6;
	wire rdy7;
	wire rdy8;
	reg [7:0] addri;
	BUFRAM256C #(.nb(nb)) U_BUF1(
		.CLK(CLK),
		.RST(RST),
		.ED(ED),
		.START(START),
		.DR(DR),
		.DI(DI),
		.RDY(rdy1),
		.DOR(dr1),
		.DOI(di1)
	);
	FFT16 #(.nb(nb)) U_FFT1(
		.CLK(CLK),
		.RST(RST),
		.ED(ED),
		.START(rdy1),
		.DIR(dr1),
		.DII(di1),
		.RDY(rdy2),
		.DOR(dr2),
		.DOI(di2)
	);
	wire [1:0] shiftl;
	assign shiftl = SHIFT[1:0];
	CNORM #(.nb(nb)) U_NORM1(
		.CLK(CLK),
		.ED(ED),
		.START(rdy2),
		.DR(dr2),
		.DI(di2),
		.SHIFT(shiftl),
		.OVF(OVF1),
		.RDY(rdy3),
		.DOR(dr3),
		.DOI(di3)
	);
	ROTATOR64 #(.nb(nb + 2)) U_MPU(
		.CLK(CLK),
		.RST(RST),
		.ED(ED),
		.START(rdy3),
		.DR(dr3),
		.DI(di3),
		.RDY(rdy4),
		.DOR(dr4),
		.DOI(di4)
	);
	BUFRAM256C #(.nb(nb + 2)) U_BUF2(
		.CLK(CLK),
		.RST(RST),
		.ED(ED),
		.START(rdy4),
		.DR(dr4),
		.DI(di4),
		.RDY(rdy5),
		.DOR(dr5),
		.DOI(di5)
	);
	FFT16 #(.nb(nb + 2)) U_FFT2(
		.CLK(CLK),
		.RST(RST),
		.ED(ED),
		.START(rdy5),
		.DIR(dr5),
		.DII(di5),
		.RDY(rdy6),
		.DOR(dr6),
		.DOI(di6)
	);
	wire [1:0] shifth;
	assign shifth = SHIFT[3:2];
	CNORM #(.nb(nb + 2)) U_NORM2(
		.CLK(CLK),
		.ED(ED),
		.START(rdy6),
		.DR(dr6),
		.DI(di6),
		.SHIFT(shifth),
		.OVF(OVF2),
		.RDY(rdy7),
		.DOR(dr7),
		.DOI(di7)
	);
	BUFRAM256C #(.nb(nb + 4)) Ubuf3(
		.CLK(CLK),
		.RST(RST),
		.ED(ED),
		.START(rdy7),
		.DR(dr7),
		.DI(di7),
		.RDY(rdy8),
		.DOR(dr8),
		.DOI(di8)
	);
	always @(posedge CLK)
		if (RST)
			addri <= 8'b00000000;
		else if (rdy8 == 1)
			addri <= 8'b00000000;
		else if (ED)
			addri <= addri + 1;
	assign ADDR = addri;
	assign DOR = dr8;
	assign DOI = di8;
	assign RDY = rdy8;
	assign O_fft_real = DOR[nb + 3:4];
	assign O_fft_imag = DOI[nb + 3:4];
endmodule
