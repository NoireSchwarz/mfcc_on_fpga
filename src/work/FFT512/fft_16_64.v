`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module fft_16_64 (
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
	parameter signed [31:0] N = 16;
	input wire RST;
	input wire ED;
	input wire CLK;
	input wire START;
	input wire signed [NB - 1:0] DIR;
	input wire signed [NB - 1:0] DII;
	output reg RDY;
	output reg signed [NB + 3:0] DOR;
	output reg signed [NB + 3:0] DOI;
	localparam [0:0] USE_FFT16 = N == 16;
	localparam [0:0] USE_RADIX4 = N == 64;
	localparam signed [31:0] FFT16_POINTS = 16;
	localparam signed [31:0] RADIX4_POINTS = 64;
	localparam signed [31:0] RADIX4_SPAN = 16;
	generate
		if (USE_FFT16) begin : gen_direct_fft16
			wire [1:1] sv2v_tmp_fft16_i_RDY;
			always @(*) RDY = sv2v_tmp_fft16_i_RDY;
			wire [((NB + 3) >= 0 ? NB + 4 : 1 - (NB + 3)):1] sv2v_tmp_fft16_i_DOR;
			always @(*) DOR = sv2v_tmp_fft16_i_DOR;
			wire [((NB + 3) >= 0 ? NB + 4 : 1 - (NB + 3)):1] sv2v_tmp_fft16_i_DOI;
			always @(*) DOI = sv2v_tmp_fft16_i_DOI;
			FFT16 #(.nb(NB)) fft16_i(
				.CLK(CLK),
				.RST(RST),
				.ED(ED),
				.START(START),
				.DIR(DIR),
				.DII(DII),
				.RDY(sv2v_tmp_fft16_i_RDY),
				.DOR(sv2v_tmp_fft16_i_DOR),
				.DOI(sv2v_tmp_fft16_i_DOI)
			);
		end
		else if (N == 64 && NB == 16 && TW == 16) begin : gen_bram_fft64
			wire bram_rdy;
			wire signed [19:0] bram_re, bram_im;
			always @(*) RDY = bram_rdy;
			always @(*) DOR = bram_re;
			always @(*) DOI = bram_im;
			fft64_bram_legacy bram_i(
				.CLK(CLK), .RST(RST), .ED(ED), .START(START),
				.DIR(DIR), .DII(DII), .RDY(bram_rdy), .DOR(bram_re), .DOI(bram_im)
			);
		end
		else begin : gen_radix4_fft16
			reg [3:0] state;
			reg [5:0] input_cnt;
			reg [3:0] sample_cnt;
			reg [1:0] lane_idx;
			reg [5:0] out_cnt;
			reg signed [NB - 1:0] frame_re [0:63];
			reg signed [NB - 1:0] frame_im [0:63];
			reg fft16_start;
			wire fft16_rdy;
			reg signed [NB - 1:0] fft16_dr;
			reg signed [NB - 1:0] fft16_di;
			wire signed [NB + 3:0] fft16_or;
			wire signed [NB + 3:0] fft16_oi;
			wire signed [NB - 1:0] fft16_res_re;
			wire signed [NB - 1:0] fft16_res_im;
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
			assign fft16_res_re = fft16_or[NB + 3:4];
			assign fft16_res_im = fft16_oi[NB + 3:4];
			FFT16 #(.nb(NB)) fft16_i(
				.CLK(CLK),
				.RST(RST),
				.ED(ED),
				.START(fft16_start),
				.DIR(fft16_dr),
				.DII(fft16_di),
				.RDY(fft16_rdy),
				.DOR(fft16_or),
				.DOI(fft16_oi)
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
					fft16_start <= 1'b0;
					r4_start <= 1'b0;
					fft16_dr <= 1'sb0;
					fft16_di <= 1'sb0;
					DOR <= 1'sb0;
					DOI <= 1'sb0;
					RDY <= 1'b0;
				end
				else begin
					fft16_start <= 1'b0;
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
								if (input_cnt == 63) begin
									lane_idx <= 1'sb0;
									sample_cnt <= 1'sb0;
									state <= 4'd2;
								end
							end
							4'd2: begin
								sample_cnt <= 1'sb0;
								fft16_start <= 1'b1;
								state <= 4'd3;
							end
							4'd3: begin
								fft16_dr <= frame_re[(4 * sample_cnt) + lane_idx];
								fft16_di <= frame_im[(4 * sample_cnt) + lane_idx];
								sample_cnt <= sample_cnt + 1'b1;
								if (sample_cnt == 15) begin
									sample_cnt <= 1'sb0;
									state <= 4'd4;
								end
							end
							4'd4:
								if (fft16_rdy) begin
									sample_cnt <= 1'sb0;
									state <= 4'd5;
								end
							4'd5: begin
								case (lane_idx)
									2'd0: begin
										r4_in0_re[(15 - sample_cnt) * NB+:NB] <= fft16_res_re;
										r4_in0_im[(15 - sample_cnt) * NB+:NB] <= fft16_res_im;
									end
									2'd1: begin
										r4_in1_re[(15 - sample_cnt) * NB+:NB] <= fft16_res_re;
										r4_in1_im[(15 - sample_cnt) * NB+:NB] <= fft16_res_im;
									end
									2'd2: begin
										r4_in2_re[(15 - sample_cnt) * NB+:NB] <= fft16_res_re;
										r4_in2_im[(15 - sample_cnt) * NB+:NB] <= fft16_res_im;
									end
									default: begin
										r4_in3_re[(15 - sample_cnt) * NB+:NB] <= fft16_res_re;
										r4_in3_im[(15 - sample_cnt) * NB+:NB] <= fft16_res_im;
									end
								endcase
								sample_cnt <= sample_cnt + 1'b1;
								if (sample_cnt == 15) begin
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
								DOR <= {r4_out_re[(63 - out_cnt) * NB+:NB], 4'b0000};
								DOI <= {r4_out_im[(63 - out_cnt) * NB+:NB], 4'b0000};
								out_cnt <= out_cnt + 1'b1;
								if (out_cnt == 63)
									state <= 4'd0;
							end
						endcase
				end
		end
	endgenerate
endmodule
