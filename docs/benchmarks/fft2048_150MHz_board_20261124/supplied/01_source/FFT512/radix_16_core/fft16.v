`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module FFT16 (
	DOR,
	DII,
	RST,
	ED,
	CLK,
	DOI,
	START,
	DIR,
	RDY
);
	parameter nb = 16;
	input wire ED;
	input wire RST;
	input wire CLK;
	input wire [nb - 1:0] DII;
	input wire START;
	input wire [nb - 1:0] DIR;
	output wire [nb + 3:0] DOI;
	output wire [nb + 3:0] DOR;
	output reg RDY;
	reg [3:0] ct;
	reg [5:0] ctd;
	always @(posedge CLK)
		if (RST) begin
			ct <= 0;
			ctd <= 63;
			RDY <= 0;
		end
		else if (START) begin
			ct <= 0;
			ctd <= 0;
			RDY <= 0;
		end
		else if (ED) begin
			RDY <= 0;
			ct <= ct + 1;
			if (ctd != 6'b111111)
				ctd <= ctd + 1;
			if (ctd == 28)
				RDY <= 1;
		end
	reg signed [nb - 1:0] dr;
	reg signed [nb - 1:0] d1r;
	reg signed [nb - 1:0] d2r;
	reg signed [nb - 1:0] d3r;
	reg signed [nb - 1:0] d4r;
	reg signed [nb - 1:0] d5r;
	reg signed [nb - 1:0] d6r;
	reg signed [nb - 1:0] d7r;
	reg signed [nb - 1:0] d8r;
	reg signed [nb - 1:0] di;
	reg signed [nb - 1:0] d1i;
	reg signed [nb - 1:0] d2i;
	reg signed [nb - 1:0] d3i;
	reg signed [nb - 1:0] d4i;
	reg signed [nb - 1:0] d5i;
	reg signed [nb - 1:0] d6i;
	reg signed [nb - 1:0] d7i;
	reg signed [nb - 1:0] d8i;
	always @(posedge CLK)
		if (ED) begin
			dr <= DIR;
			d1r <= dr;
			d2r <= d1r;
			d3r <= d2r;
			d4r <= d3r;
			d5r <= d4r;
			d6r <= d5r;
			d7r <= d6r;
			d8r <= d7r;
			di <= DII;
			d1i <= di;
			d2i <= d1i;
			d3i <= d2i;
			d4i <= d3i;
			d5i <= d4i;
			d6i <= d5i;
			d7i <= d6i;
			d8i <= d7i;
		end
	reg signed [nb:0] s1r;
	reg signed [nb:0] s1d1r;
	reg signed [nb:0] s1d2r;
	reg signed [nb:0] s1d3r;
	reg signed [nb:0] s1d4r;
	reg signed [nb:0] s1d5r;
	reg signed [nb:0] s1d6r;
	reg signed [nb:0] s1d7r;
	reg signed [nb:0] s1d8r;
	reg signed [nb:0] s1i;
	reg signed [nb:0] s1d1i;
	reg signed [nb:0] s1d2i;
	reg signed [nb:0] s1d3i;
	reg signed [nb:0] s1d4i;
	reg signed [nb:0] s1d5i;
	reg signed [nb:0] s1d6i;
	reg signed [nb:0] s1d7i;
	reg signed [nb:0] s1d8i;
	reg signed [nb:0] s2r;
	reg signed [nb:0] s2d1r;
	reg signed [nb:0] s2d2r;
	reg signed [nb:0] s2d3r;
	reg signed [nb:0] s2d4r;
	reg signed [nb:0] s2d5r;
	reg signed [nb:0] s2d6r;
	reg signed [nb:0] s2d7r;
	reg signed [nb:0] s2d8r;
	reg signed [nb:0] m4_12r;
	reg signed [nb:0] s2i;
	reg signed [nb:0] s2d1i;
	reg signed [nb:0] s2d2i;
	reg signed [nb:0] s2d3i;
	reg signed [nb:0] s2d4i;
	reg signed [nb:0] s2d5i;
	reg signed [nb:0] s2d6i;
	reg signed [nb:0] s2d7i;
	reg signed [nb:0] s2d8i;
	reg signed [nb:0] m4_12i;
	always @(posedge CLK) begin
		if (ED && ((((((((ct == 9) || (ct == 10)) || (ct == 11)) || (ct == 12)) || (ct == 13)) || (ct == 14)) || (ct == 15)) || (ct == 0))) begin
			s1r <= d8r + dr;
			s1i <= d8i + di;
			s2r <= d8r - dr;
			s2i <= d8i - di;
		end
		if (ED) begin
			s1d1r <= s1r;
			s1d2r <= s1d1r;
			s1d1i <= s1i;
			s1d2i <= s1d1i;
			s1d3r <= s1d2r;
			s1d3i <= s1d2i;
			s1d4r <= s1d3r;
			s1d4i <= s1d3i;
			s1d5r <= s1d4r;
			s1d5i <= s1d4i;
			s1d6r <= s1d5r;
			s1d6i <= s1d5i;
			s1d7r <= s1d6r;
			s1d7i <= s1d6i;
			s1d8r <= s1d7r;
			s1d8i <= s1d7i;
			s2d1r <= s2r;
			s2d2r <= s2d1r;
			s2d1i <= s2i;
			s2d2i <= s2d1i;
			s2d3r <= s2d2r;
			s2d3i <= s2d2i;
			s2d4r <= s2d3r;
			s2d4i <= s2d3i;
			s2d5r <= s2d4r;
			s2d5i <= s2d4i;
			s2d6r <= s2d5r;
			s2d6i <= s2d5i;
			s2d7r <= s2d6r;
			s2d7i <= s2d6i;
			s2d8r <= s2d7r;
			s2d8i <= s2d7i;
			if (ct == 2) begin
				m4_12r <= s2d8r;
				m4_12i <= s2d8i;
			end
			else if (ct == 6) begin
				m4_12r <= s2d8i;
				m4_12i <= -s2d8r;
			end
		end
	end
	reg signed [nb + 1:0] s3r;
	reg signed [nb + 1:0] s3d1r;
	reg signed [nb + 1:0] s3d2r;
	reg signed [nb + 1:0] s3d3r;
	reg signed [nb + 1:0] s3d4r;
	reg signed [nb + 1:0] s3d5r;
	reg signed [nb + 1:0] s3d6r;
	reg signed [nb + 1:0] s3i;
	reg signed [nb + 1:0] s3d1i;
	reg signed [nb + 1:0] s3d2i;
	reg signed [nb + 1:0] s3d3i;
	reg signed [nb + 1:0] s3d4i;
	reg signed [nb + 1:0] s3d5i;
	reg signed [nb + 1:0] s3d6i;
	always @(posedge CLK)
		if (ED) begin
			case (ct)
				14, 15: begin
					s3r <= s1d4r + s1r;
					s3i <= s1d4i + s1i;
				end
				0, 1: begin
					s3r <= s1d6r - s1d2r;
					s3i <= s1d6i - s1d2i;
				end
				2, 3: begin
					s3r <= s1d6r + s1d2r;
					s3i <= s1d6i + s1d2i;
				end
				4, 5: begin
					s3r <= s1d8r - s1d4r;
					s3i <= s1d8i - s1d4i;
				end
			endcase
			s3d1r <= s3r;
			s3d1i <= s3i;
			s3d2r <= s3d1r;
			s3d2i <= s3d1i;
			s3d3r <= s3d2r;
			s3d3i <= s3d2i;
			s3d4r <= s3d3r;
			s3d4i <= s3d3i;
			s3d5r <= s3d4r;
			s3d5i <= s3d4i;
			s3d6r <= s3d5r;
			s3d6i <= s3d5i;
		end
	reg signed [nb + 2:0] s4r;
	reg signed [nb + 2:0] s4d1r;
	reg signed [nb + 2:0] s4d2r;
	reg signed [nb + 2:0] s4d3r;
	reg signed [nb + 2:0] s4d4r;
	reg signed [nb + 2:0] s4d5r;
	reg signed [nb + 2:0] s4d6r;
	reg signed [nb + 2:0] s4d7r;
	reg signed [nb + 2:0] m3r;
	reg signed [nb + 2:0] s4i;
	reg signed [nb + 2:0] s4d1i;
	reg signed [nb + 2:0] s4d2i;
	reg signed [nb + 2:0] s4d3i;
	reg signed [nb + 2:0] s4d4i;
	reg signed [nb + 2:0] s4d5i;
	reg signed [nb + 2:0] s4d6i;
	reg signed [nb + 2:0] s4d7i;
	reg signed [nb + 2:0] m3i;
	always @(posedge CLK)
		if (ED) begin
			if ((ct == 3) | (ct == 4)) begin
				s4r <= s3d4r + s3r;
				s4i <= s3d4i + s3i;
			end
			else if (((ct == 5) | (ct == 6)) | (ct == 8)) begin
				s4r <= s3d6r - s3d2r;
				s4i <= s3d6i - s3d2i;
			end
			else if (ct == 7) begin
				s4r <= s3d1r + s3d5r;
				s4i <= s3d1i + s3d5i;
			end
			s4d1r <= s4r;
			s4d1i <= s4i;
			s4d2r <= s4d1r;
			s4d2i <= s4d1i;
			s4d3r <= s4d2r;
			s4d3i <= s4d2i;
			s4d4r <= s4d3r;
			s4d4i <= s4d3i;
			s4d5r <= s4d4r;
			s4d5i <= s4d4i;
			s4d6r <= s4d5r;
			s4d6i <= s4d5i;
			s4d7r <= s4d6r;
			s4d7i <= s4d6i;
			if (ct == 7) begin
				m3r <= s3d6r;
				m3i <= s3d6i;
			end
		end
	wire em707;
	wire mpyj7;
	assign em707 = (((ct == 8) || (ct == 10)) || (ct == 1)) || (ct == 5);
	assign mpyj7 = (ct == 8) || (ct == 5);
	reg signed [nb + 2:0] s7r;
	reg signed [nb + 2:0] s7d1r;
	reg signed [nb + 2:0] s7i;
	reg signed [nb + 2:0] s7d1i;
	wire signed [nb + 2:0] m707r;
	wire signed [nb + 2:0] m707i;
	wire signed [nb + 2:0] m70r;
	wire signed [nb + 2:0] m70i;
	assign m70r = ((ct == 1) || (ct == 5) ? s7r : s4r);
	assign m70i = ((ct == 1) || (ct == 5) ? s7i : s4i);
	MPUC707 #(.nb(nb + 3)) UM707(
		.CLK(CLK),
		.EI(ED),
		.ED(em707),
		.MPYJ(mpyj7),
		.DR(m70r),
		.DI(m70i),
		.DOR(m707r),
		.DOI(m707i)
	);
	reg signed [nb + 2:0] s3jr;
	reg signed [nb + 2:0] s3ji;
	reg signed [nb + 2:0] m10r;
	reg signed [nb + 2:0] m10i;
	always @(posedge CLK)
		if (ED) begin
			case (ct)
				11: begin
					s3jr <= s3d6i;
					s3ji <= -s3d6r;
				end
				14: begin
					s3jr <= s4d7i;
					s3ji <= -s4d7r;
				end
			endcase
			if (ct == 1) begin
				m10r <= s3jr;
				m10i <= s3ji;
			end
		end
	reg signed [nb + 3:0] s5r;
	reg signed [nb + 3:0] s5d1r;
	reg signed [nb + 3:0] s5d2r;
	reg signed [nb + 3:0] s5d3r;
	reg signed [nb + 3:0] s5d4r;
	reg signed [nb + 3:0] s5d5r;
	reg signed [nb + 3:0] s5d6r;
	reg signed [nb + 3:0] s5d7r;
	reg signed [nb + 3:0] s5d8r;
	reg signed [nb + 3:0] s5d9r;
	reg signed [nb + 3:0] s5d10r;
	reg signed [nb + 3:0] m2r;
	reg signed [nb + 3:0] m2dr;
	reg signed [nb + 3:0] s5i;
	reg signed [nb + 3:0] s5d1i;
	reg signed [nb + 3:0] s5d2i;
	reg signed [nb + 3:0] s5d3i;
	reg signed [nb + 3:0] s5d4i;
	reg signed [nb + 3:0] s5d5i;
	reg signed [nb + 3:0] s5d6i;
	reg signed [nb + 3:0] s5d7i;
	reg signed [nb + 3:0] s5d8i;
	reg signed [nb + 3:0] s5d9i;
	reg signed [nb + 3:0] s5d10i;
	reg signed [nb + 3:0] m2i;
	reg signed [nb + 3:0] m2di;
	always @(posedge CLK)
		if (ED) begin
			case (ct)
				10: begin
					s5r <= s4d5r + s4d6r;
					s5i <= s4d5i + s4d6i;
				end
				11: begin
					s5r <= s4d7r - s4d6r;
					s5i <= s4d7i - s4d6i;
				end
				12: begin
					s5r <= m707r + s3jr;
					s5i <= m707i + s3ji;
				end
				13: begin
					s5r <= m707r - s3jr;
					s5i <= m707i - s3ji;
				end
				14: begin
					s5r <= m3r + m707r;
					s5i <= m3i + m707i;
				end
				15: begin
					s5r <= m3r - m707r;
					s5i <= m3i - m707i;
				end
				6: begin
					s5d10r <= s5d9r;
					s5d10i <= s5d9i;
				end
			endcase
			if ((((ct == 4) || (ct == 5)) || (ct == 6)) || (ct == 7)) begin
				s5d9r <= s5d8r;
				s5d9i <= s5d8i;
			end
			s5d1r <= s5r;
			s5d1i <= s5i;
			s5d2r <= s5d1r;
			s5d2i <= s5d1i;
			s5d3r <= s5d2r;
			s5d3i <= s5d2i;
			s5d4r <= s5d3r;
			s5d4i <= s5d3i;
			s5d5r <= s5d4r;
			s5d5i <= s5d4i;
			s5d6r <= s5d5r;
			s5d6i <= s5d5i;
			s5d7r <= s5d6r;
			s5d7i <= s5d6i;
			s5d8r <= s5d7r;
			s5d8i <= s5d7i;
			if (ct == 13) begin
				m2r <= s4d7r;
				m2i <= s4d7i;
			end
			if (ct == 1) begin
				m2dr <= m2r;
				m2di <= m2i;
			end
		end
	reg signed [nb + 3:0] s6r;
	reg signed [nb + 3:0] s6i;
	always @(posedge CLK)
		if (ED)
			case (ct)
				13: begin
					s6r <= s5d2r;
					s6i <= s5d2i;
				end
				15: begin
					s6r <= s5d2r + s5r;
					s6i <= s5d2i + s5i;
				end
				1: begin
					s6r <= m2r + s3jr;
					s6i <= m2i + s3ji;
				end
				3: begin
					s6r <= s5d3r + s5d5r;
					s6i <= s5d3i + s5d5i;
				end
				5: begin
					s6r <= s5d9r;
					s6i <= s5d9i;
				end
				7: begin
					s6r <= s5d7r - s5d9r;
					s6i <= s5d7i - s5d9i;
				end
				9: begin
					s6r <= m2dr - m10r;
					s6i <= m2di - m10i;
				end
				11: begin
					s6r <= s5d9r - s5d10r;
					s6i <= s5d9i - s5d10i;
				end
			endcase
	always @(posedge CLK)
		if (ED)
			case (ct)
				15: begin
					s7r <= s2d2r - s2r;
					s7i <= s2d2i - s2i;
				end
				0: begin
					s7r <= s2d4r - s2r;
					s7i <= s2d4i - s2i;
					s7d1r <= s7r;
					s7d1i <= s7i;
				end
				1: begin
					s7r <= s2d6r - s2r;
					s7i <= s2d6i - s2i;
				end
				2: begin
					s7r <= s7r - s7d1r;
					s7i <= s7i - s7d1i;
				end
				3: begin
					s7r <= s2d8r + s2d2r;
					s7i <= s2d8i + s2d2i;
				end
				4: begin
					s7r <= s2d8r + s2d4r;
					s7i <= s2d8i + s2d4i;
					s7d1r <= s7r;
					s7d1i <= s7i;
				end
				5: begin
					s7r <= s2d8r + s2d6r;
					s7i <= s2d8i + s2d6i;
				end
				6: begin
					s7r <= s7r + s7d1r;
					s7i <= s7i + s7d1i;
				end
			endcase
	wire em541;
	wire mpyj541;
	wire signed [nb + 2:0] m541r;
	wire signed [nb + 2:0] m541i;
	assign em541 = (ct == 0) || (ct == 4);
	assign mpyj541 = ct == 4;
	MPUC541 #(.nb(nb + 3)) UM541(
		.CLK(CLK),
		.EI(ED),
		.ED(em541),
		.MPYJ(mpyj541),
		.DR(s7r),
		.DI(s7i),
		.DOR(m541r),
		.DOI(m541i)
	);
	wire em1307;
	wire mpyj1307;
	wire signed [nb + 3:0] m1307r;
	wire signed [nb + 3:0] m1307i;
	assign em1307 = (ct == 2) || (ct == 6);
	assign mpyj1307 = ct == 6;
	MPUC1307 #(.nb(nb + 3)) UM1307(
		.CLK(CLK),
		.EI(ED),
		.ED(em1307),
		.MPYJ(mpyj1307),
		.DR(s7r),
		.DI(s7i),
		.DOR(m1307r),
		.DOI(m1307i)
	);
	wire em383;
	wire mpyj383;
	wire c383;
	wire signed [nb + 2:0] m383r;
	wire signed [nb + 2:0] m383i;
	assign em383 = (ct == 3) || (ct == 7);
	assign mpyj383 = ct == 7;
	assign c383 = ct == 3;
	MPUC924_383 #(.nb(nb + 3)) UM383(
		.CLK(CLK),
		.EI(ED),
		.ED(em383),
		.MPYJ(mpyj383),
		.C383(c383),
		.DR(s7r),
		.DI(s7i),
		.DOR(m383r),
		.DOI(m383i)
	);
	reg signed [nb + 2:0] m8_17r;
	reg signed [nb + 2:0] m8_17i;
	reg signed [nb + 2:0] m9_16r;
	reg signed [nb + 2:0] m9_16i;
	always @(posedge CLK)
		if (ED) begin
			if ((ct == 4) || (ct == 8)) begin
				m9_16r <= m541r;
				m9_16i <= m541i;
			end
			if ((ct == 6) || (ct == 10)) begin
				m8_17r <= m1307r[nb + 2:0];
				m8_17i <= m1307i[nb + 2:0];
			end
		end
	reg signed [nb + 2:0] s8r;
	reg signed [nb + 2:0] s8i;
	reg signed [nb + 2:0] s8d1r;
	reg signed [nb + 2:0] s8d2r;
	reg signed [nb + 2:0] s8d3r;
	reg signed [nb + 2:0] s8d4r;
	reg signed [nb + 2:0] s8d1i;
	reg signed [nb + 2:0] s8d2i;
	reg signed [nb + 2:0] s8d3i;
	reg signed [nb + 2:0] s8d4i;
	always @(posedge CLK) begin
		if (ED)
			case (ct)
				5, 9: begin
					s8r <= m4_12r + m707r;
					s8i <= m4_12i + m707i;
				end
				6, 10: begin
					s8r <= m4_12r - m707r;
					s8i <= m4_12i - m707i;
				end
				7: begin
					s8r <= m8_17r - m383r;
					s8i <= m8_17i - m383i;
				end
				8: begin
					s8r <= m9_16r - m383r;
					s8i <= m9_16i - m383i;
				end
				11: begin
					s8r <= m383r - m9_16r;
					s8i <= m383i - m9_16i;
				end
				12: begin
					s8r <= m383r - m8_17r;
					s8i <= m383i - m8_17i;
				end
			endcase
		s8d1r <= s8r;
		s8d1i <= s8i;
		s8d2r <= s8d1r;
		s8d2i <= s8d1i;
		s8d3r <= s8d2r;
		s8d3i <= s8d2i;
		s8d4r <= s8d3r;
		s8d4i <= s8d3i;
	end
	reg signed [nb + 3:0] s9r;
	reg signed [nb + 3:0] s9d1r;
	reg signed [nb + 3:0] s9d2r;
	reg signed [nb + 3:0] s9d3r;
	reg signed [nb + 3:0] s9d4r;
	reg signed [nb + 3:0] s9d5r;
	reg signed [nb + 3:0] s9d6r;
	reg signed [nb + 3:0] s9d7r;
	reg signed [nb + 3:0] s9d8r;
	reg signed [nb + 3:0] s9d9r;
	reg signed [nb + 3:0] s9d10r;
	reg signed [nb + 3:0] s9d11r;
	reg signed [nb + 3:0] s9d12r;
	reg signed [nb + 3:0] s9d13r;
	reg signed [nb + 3:0] s9i;
	reg signed [nb + 3:0] s9d1i;
	reg signed [nb + 3:0] s9d2i;
	reg signed [nb + 3:0] s9d3i;
	reg signed [nb + 3:0] s9d4i;
	reg signed [nb + 3:0] s9d5i;
	reg signed [nb + 3:0] s9d6i;
	reg signed [nb + 3:0] s9d7i;
	reg signed [nb + 3:0] s9d8i;
	reg signed [nb + 3:0] s9d9i;
	reg signed [nb + 3:0] s9d10i;
	reg signed [nb + 3:0] s9d11i;
	reg signed [nb + 3:0] s9d12i;
	reg signed [nb + 3:0] s9d13i;
	always @(posedge CLK)
		if (ED) begin
			case (ct)
				8, 9, 12: begin
					s9r <= s8r + s8d2r;
					s9i <= s8i + s8d2i;
				end
				13: begin
					s9r <= s8d2r - s8r;
					s9i <= s8d2i - s8i;
				end
				10, 11, 14: begin
					s9r <= s8d4r - s8d2r;
					s9i <= s8d4i - s8d2i;
				end
				15: begin
					s9r <= s8d4r + s8d2r;
					s9i <= s8d4i + s8d2i;
				end
			endcase
			s9d1r <= s9r;
			s9d1i <= s9i;
			s9d2r <= s9d1r;
			s9d2i <= s9d1i;
			s9d3r <= s9d2r;
			s9d3i <= s9d2i;
			s9d4r <= s9d3r;
			s9d4i <= s9d3i;
			s9d5r <= s9d4r;
			s9d5i <= s9d4i;
			s9d6r <= s9d5r;
			s9d6i <= s9d5i;
			s9d7r <= s9d6r;
			s9d7i <= s9d6i;
			s9d8r <= s9d7r;
			s9d8i <= s9d7i;
			s9d9r <= s9d8r;
			s9d9i <= s9d8i;
			if (ct != 8) begin
				s9d10r <= s9d9r;
				s9d10i <= s9d9i;
				s9d11r <= s9d10r;
				s9d11i <= s9d10i;
			end
			if ((((ct == 4) || (ct == 5)) || (ct == 7)) || (ct == 9)) begin
				s9d12r <= s9d11r;
				s9d12i <= s9d11i;
			end
			if (ct == 5) begin
				s9d13r <= s9d12r;
				s9d13i <= s9d12i;
			end
		end
	reg signed [nb + 3:0] s10r;
	reg signed [nb + 3:0] s10i;
	reg signed [nb + 3:0] s10dr;
	reg signed [nb + 3:0] s10di;
	always @(posedge CLK) begin
		if (ED)
			case (ct)
				13: begin
					s10r <= s9d4r + s9r;
					s10i <= s9d4i + s9i;
				end
				15: begin
					s10r <= s9d3r - s9d1r;
					s10i <= s9d3i - s9d1i;
				end
				1: begin
					s10r <= s9d7r + s9d1r;
					s10i <= s9d7i + s9d1i;
				end
				3: begin
					s10r <= s9d8r - s9d4r;
					s10i <= s9d8i - s9d4i;
				end
				5: begin
					s10r <= s9d10r + s9d6r;
					s10i <= s9d10i + s9d6i;
				end
				7: begin
					s10r <= s9d12r - s9d7r;
					s10i <= s9d12i - s9d7i;
				end
				9: begin
					s10r <= s9d12r + s9d10r;
					s10i <= s9d12i + s9d10i;
				end
				11: begin
					s10r <= s9d13r - s9d12r;
					s10i <= s9d13i - s9d12i;
				end
			endcase
		s10dr <= s10r;
		s10di <= s10i;
	end
	wire selo;
	assign selo = ct - ((ct / 2) * 2);
	assign DOR = (selo ? s10dr : s6r);
	assign DOI = (selo ? s10di : s6i);
endmodule
