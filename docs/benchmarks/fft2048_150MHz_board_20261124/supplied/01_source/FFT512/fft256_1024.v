`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module fft256_1024 (
	RST,
	ED,
	CLK,
	START,
	DIR,
	DII,
	RDY,
	DOR,
	DOI
);
	parameter signed [31:0] NB = 16;
	parameter signed [31:0] TW = 16;
	parameter signed [31:0] N = 256;
	input wire RST;
	input wire ED;
	input wire CLK;
	input wire START;
	input wire signed [NB - 1:0] DIR;
	input wire signed [NB - 1:0] DII;
	output reg RDY;
	output reg signed [NB - 1:0] DOR;
	output reg signed [NB - 1:0] DOI;
	localparam [0:0] USE_FFT256 = N == 256;
	localparam signed [31:0] FFT256_POINTS = 256;
	localparam signed [31:0] RADIX4_POINTS = 1024;
	localparam signed [31:0] RADIX4_SPAN = 256;
	generate
		if (USE_FFT256) begin : gen_direct_fft256
			wire fft_ovf1;
			wire fft_ovf2;
			wire [7:0] fft_addr;
			wire [1:1] sv2v_tmp_fft256_i_RDY;
			always @(*) RDY = sv2v_tmp_fft256_i_RDY;
			wire [NB:1] sv2v_tmp_fft256_i_O_fft_real;
			always @(*) DOR = sv2v_tmp_fft256_i_O_fft_real;
			wire [NB:1] sv2v_tmp_fft256_i_O_fft_imag;
			always @(*) DOI = sv2v_tmp_fft256_i_O_fft_imag;
			fft256 #(.nb(NB)) fft256_i(
				.CLK(CLK),
				.RST(RST),
				.ED(ED),
				.START(START),
				.SHIFT(4'd0),
				.DR(DIR),
				.DI(DII),
				.RDY(sv2v_tmp_fft256_i_RDY),
				.OVF1(fft_ovf1),
				.OVF2(fft_ovf2),
				.ADDR(fft_addr),
				.O_fft_real(sv2v_tmp_fft256_i_O_fft_real),
				.O_fft_imag(sv2v_tmp_fft256_i_O_fft_imag)
			);
		end
		else begin : gen_radix4_fft256
			reg [3:0] state;
			reg [9:0] input_cnt;
			reg [7:0] sample_cnt;
			reg [1:0] lane_idx;
			reg [9:0] out_cnt;
			reg signed [NB - 1:0] frame_re [0:1023];
			reg signed [NB - 1:0] frame_im [0:1023];
			reg fft256_start;
			wire fft256_rdy;
			reg signed [NB - 1:0] fft256_dr;
			reg signed [NB - 1:0] fft256_di;
			wire signed [NB - 1:0] fft256_or;
			wire signed [NB - 1:0] fft256_oi;
			wire fft256_ovf1;
			wire fft256_ovf2;
			wire [7:0] fft256_addr;
			reg signed [(RADIX4_SPAN * NB) - 1:0] r4_in0_re;
			reg signed [(RADIX4_SPAN * NB) - 1:0] r4_in0_im;
			reg signed [(RADIX4_SPAN * NB) - 1:0] r4_in1_re;
			reg signed [(RADIX4_SPAN * NB) - 1:0] r4_in1_im;
			reg signed [(RADIX4_SPAN * NB) - 1:0] r4_in2_re;
			reg signed [(RADIX4_SPAN * NB) - 1:0] r4_in2_im;
			reg signed [(RADIX4_SPAN * NB) - 1:0] r4_in3_re;
			reg signed [(RADIX4_SPAN * NB) - 1:0] r4_in3_im;
			wire signed [(RADIX4_POINTS * NB) - 1:0] r4_out_re;
			wire signed [(RADIX4_POINTS * NB) - 1:0] r4_out_im;
			reg r4_start;
			wire r4_valid;
			wire r4_busy;
			fft256 #(.nb(NB)) fft256_i(
				.CLK(CLK),
				.RST(RST),
				.ED(ED),
				.START(fft256_start),
				.SHIFT(4'd0),
				.DR(fft256_dr),
				.DI(fft256_di),
				.RDY(fft256_rdy),
				.OVF1(fft256_ovf1),
				.OVF2(fft256_ovf2),
				.ADDR(fft256_addr),
				.O_fft_real(fft256_or),
				.O_fft_imag(fft256_oi)
			);
			radix4_merge_stage #(
				.NB(NB),
				.TW(TW),
				.N(RADIX4_POINTS),
				.SPAN(RADIX4_SPAN)
			) radix4_i(
				.clk(CLK),
				.rst(RST),
				.start(r4_start),
				.in0_re(r4_in0_re),
				.in0_im(r4_in0_im),
				.in1_re(r4_in1_re),
				.in1_im(r4_in1_im),
				.in2_re(r4_in2_re),
				.in2_im(r4_in2_im),
				.in3_re(r4_in3_re),
				.in3_im(r4_in3_im),
				.out_valid(r4_valid),
				.busy(r4_busy),
				.out_re(r4_out_re),
				.out_im(r4_out_im)
			);
			always @(posedge CLK)
				if (RST) begin
					state <= 4'd0;
					input_cnt <= 1'sb0;
					sample_cnt <= 1'sb0;
					lane_idx <= 1'sb0;
					out_cnt <= 1'sb0;
					fft256_start <= 1'b0;
					r4_start <= 1'b0;
					fft256_dr <= 1'sb0;
					fft256_di <= 1'sb0;
					DOR <= 1'sb0;
					DOI <= 1'sb0;
					RDY <= 1'b0;
				end
				else begin
					fft256_start <= 1'b0;
					r4_start <= 1'b0;
					RDY <= 1'b0;
					if (ED)
						case (state)
							4'd0:
								if (START) begin
									input_cnt <= 1'sb0;
									state <= 4'd1;
								end
							4'd1: begin
								frame_re[input_cnt] <= DIR;
								frame_im[input_cnt] <= DII;
								input_cnt <= input_cnt + 1'b1;
								if (input_cnt == 1023) begin
									lane_idx <= 1'sb0;
									sample_cnt <= 1'sb0;
									state <= 4'd2;
								end
							end
							4'd2: begin
								sample_cnt <= 1'sb0;
								fft256_start <= 1'b1;
								state <= 4'd3;
							end
							4'd3: begin
								fft256_dr <= frame_re[(4 * sample_cnt) + lane_idx];
								fft256_di <= frame_im[(4 * sample_cnt) + lane_idx];
								sample_cnt <= sample_cnt + 1'b1;
								if (sample_cnt == 255) begin
									sample_cnt <= 1'sb0;
									state <= 4'd4;
								end
							end
							4'd4:
								if (fft256_rdy) begin
									sample_cnt <= 1'sb0;
									state <= 4'd5;
								end
							4'd5: begin
								case (lane_idx)
									2'd0: begin
										r4_in0_re[(255 - sample_cnt) * NB+:NB] <= fft256_or;
										r4_in0_im[(255 - sample_cnt) * NB+:NB] <= fft256_oi;
									end
									2'd1: begin
										r4_in1_re[(255 - sample_cnt) * NB+:NB] <= fft256_or;
										r4_in1_im[(255 - sample_cnt) * NB+:NB] <= fft256_oi;
									end
									2'd2: begin
										r4_in2_re[(255 - sample_cnt) * NB+:NB] <= fft256_or;
										r4_in2_im[(255 - sample_cnt) * NB+:NB] <= fft256_oi;
									end
									default: begin
										r4_in3_re[(255 - sample_cnt) * NB+:NB] <= fft256_or;
										r4_in3_im[(255 - sample_cnt) * NB+:NB] <= fft256_oi;
									end
								endcase
								sample_cnt <= sample_cnt + 1'b1;
								if (sample_cnt == 255) begin
									sample_cnt <= 1'sb0;
									state <= 4'd6;
								end
							end
							4'd6:
								if (lane_idx == 2'd3)
									state <= 4'd7;
								else begin
									lane_idx <= lane_idx + 1'b1;
									state <= 4'd2;
								end
							4'd7: begin
								r4_start <= 1'b1;
								state <= 4'd8;
							end
							4'd8:
								if (r4_valid) begin
									out_cnt <= 1'sb0;
									state <= 4'd9;
								end
							4'd9: begin
								RDY <= 1'b1;
								out_cnt <= 1'sb0;
								state <= 4'd10;
							end
							4'd10: begin
								DOR <= r4_out_re[(1023 - out_cnt) * NB+:NB];
								DOI <= r4_out_im[(1023 - out_cnt) * NB+:NB];
								out_cnt <= out_cnt + 1'b1;
								if (out_cnt == 1023)
									state <= 4'd0;
							end
						endcase
				end
		end
	endgenerate
endmodule
