`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module mfcc_core (
	clk,
	reset,
	s_axis_tdata,
	m_axis_tdata,
	s_axis_tready,
	s_axis_tvalid,
	m_axis_tready,
	m_axis_tvalid,
	m_axis_tlast
);
	parameter N = 512;
	parameter STRIDE = 256;
	parameter PRE_EMPH_COEFF = 16'd31785;
	parameter LOG_FLOOR_LOG2 = -16;
	parameter DCT_USE_MATRIX = 0;
	parameter OUT_WIDTH = 1;
	parameter DCT_DATA_W = 16;
	parameter DCT_SKEW_OUT_W = 24;
	parameter DCT_OUT_W = DCT_SKEW_OUT_W + 2;
	parameter POWER_SPEC_OUT_W = 32;
	parameter FILTER_BANK_OUT_W = 16;
	parameter RESHAPE_POINTS = 64;
	parameter M_AXIS_DATA_W = DCT_OUT_W;
	input clk;
	input reset;
	input [15:0] s_axis_tdata;
	output wire signed [(OUT_WIDTH * M_AXIS_DATA_W) - 1:0] m_axis_tdata;
	output wire s_axis_tready;
	input s_axis_tvalid;
	input m_axis_tready;
	output wire m_axis_tvalid;
	output wire m_axis_tlast;
	wire [15:0] d_hamming_input;
	wire [15:0] d_power_spec_input;
	wire [31:0] d_filter_bank_input;
	wire [(64 * FILTER_BANK_OUT_W) - 1:0] filter_bank_output;
	reg signed [(64 * DCT_OUT_W) - 1:0] dct_output;
	wire signed [(64 * DCT_DATA_W) - 1:0] q_dct_input;
	wire pow_spec_ready;
	wire d_frame_valid;
	wire filt_bank_ready;
	wire d_pow_spec_valid;
	wire reshape_ready;
	wire filt_bank_valid;
	wire q_filt_bank_valid;
	wire signed [DCT_OUT_W - 1:0] dct_serial_data;
	wire [5:0] dct_serial_index;
	wire dct_serial_valid;
	wire dct_serial_ready;
	reg dct_valid;
	wire dct_ready;
	wire dct_ovf_skew;
	wire dct_ovf_dct;
	prepare_input #(
		.N(N),
		.STRIDE(STRIDE),
		.PRE_EMPH_COEFF(PRE_EMPH_COEFF)
	) my_in(
		.clk(clk),
		.reset(reset),
		.in(s_axis_tdata),
		.out(d_hamming_input),
		.s_ready(s_axis_tready),
		.s_valid(s_axis_tvalid),
		.m_ready(pow_spec_ready),
		.m_valid(d_frame_valid)
	);
	hamming #(.N(N)) my_hamming(
		.clk(clk),
		.reset(reset),
		.in(d_hamming_input),
		.out(d_power_spec_input),
		.on(d_frame_valid & pow_spec_ready)
	);
	// BRAM FFT / fft2x backend: sample and bin handshakes stay end-to-end.
	power_spectrum #(.N(N)) my_pow_spec(
		.clk(clk),
		.reset(reset),
		.in(d_power_spec_input),
		.out(d_filter_bank_input),
		.s_ready(pow_spec_ready),
		.s_valid(d_frame_valid),
		.s_last(1'b0),
		.m_ready(filt_bank_ready),
		.m_valid(d_pow_spec_valid),
		.m_last()
	);
	filter_bank #(
		.N(N / 2),
		.NFILT(64),
		.FLOOR_LOG2(LOG_FLOOR_LOG2)
	) my_filt_bank(
		.clk(clk),
		.reset(reset),
		.in(d_filter_bank_input),
		.out(filter_bank_output),
		.s_ready(filt_bank_ready),
		.s_valid(d_pow_spec_valid),
		.m_ready(dct_ready),
		.m_valid(filt_bank_valid)
	);
	assign dct_serial_ready = !dct_valid;
	assign q_filt_bank_valid = filt_bank_valid;
	genvar _gv_i_2;
	function automatic signed [DCT_DATA_W - 1:0] sv2v_cast_ECF3B_signed;
		input reg signed [DCT_DATA_W - 1:0] inp;
		sv2v_cast_ECF3B_signed = inp;
	endfunction
	generate
		for (_gv_i_2 = 0; _gv_i_2 < 64; _gv_i_2 = _gv_i_2 + 1) begin : gen_dct_input
			localparam i = _gv_i_2;
			assign q_dct_input[(63 - i) * DCT_DATA_W+:DCT_DATA_W] = sv2v_cast_ECF3B_signed($signed(filter_bank_output[(63 - i) * FILTER_BANK_OUT_W+:FILTER_BANK_OUT_W]));
		end
		if (DCT_USE_MATRIX) begin : gen_matrix_reference
			wire [(64 * DCT_DATA_W) - 1:0] flat_input;
			genvar _gv_i_3;
			for (_gv_i_3 = 0; _gv_i_3 < 64; _gv_i_3 = _gv_i_3 + 1) begin : gen_pack
				localparam i = _gv_i_3;
				assign flat_input[i * DCT_DATA_W+:DCT_DATA_W] = q_dct_input[(63 - i) * DCT_DATA_W+:DCT_DATA_W];
			end
			dct64_matrix #(
				.DATA_W(DCT_DATA_W),
				.C_OUT_W(DCT_OUT_W),
				.COEFF_FILE("dct64_coeff_q14.mem")
			) my_dct(
				.clk(clk),
				.rst(reset),
				.shift(4'b0000),
				.s_data(flat_input),
				.s_valid(q_filt_bank_valid),
				.s_ready(dct_ready),
				.m_data(dct_serial_data),
				.m_index(dct_serial_index),
				.m_valid(dct_serial_valid),
				.m_ready(dct_serial_ready),
				.ovf_skew(dct_ovf_skew),
				.ovf_dct(dct_ovf_dct)
			);
		end
		else begin : gen_skew
			dct64_serial #(
				.DATA_W(DCT_DATA_W),
				.SKEW_OUT_W(DCT_SKEW_OUT_W),
				.C_OUT_W(DCT_OUT_W)
			) my_dct(
				.clk(clk),
				.rst(reset),
				.shift(4'b1010),
				.s_data(q_dct_input),
				.s_valid(q_filt_bank_valid),
				.s_ready(dct_ready),
				.m_data(dct_serial_data),
				.m_index(dct_serial_index),
				.m_valid(dct_serial_valid),
				.m_ready(dct_serial_ready),
				.ovf_skew(dct_ovf_skew),
				.ovf_dct(dct_ovf_dct)
			);
		end
		if (OUT_WIDTH != 64) begin : genblk3
			reshape_output #(
				.OUT_WIDTH(OUT_WIDTH),
				.DATA_WIDTH(DCT_OUT_W),
				.INPUT_POINTS(RESHAPE_POINTS)
			) my_out(
				.clk(clk),
				.reset(reset),
				.in(dct_output),
				.out(m_axis_tdata),
				.s_ready(reshape_ready),
				.s_valid(dct_valid),
				.m_ready(m_axis_tready),
				.m_valid(m_axis_tvalid),
				.m_last(m_axis_tlast)
			);
		end
		else begin : genblk3
			assign m_axis_tdata = dct_output;
			assign reshape_ready = m_axis_tready;
			assign m_axis_tvalid = dct_valid;
			assign m_axis_tlast = dct_valid;
		end
	endgenerate
	always @(posedge clk or posedge reset)
		if (reset) begin
			dct_valid <= 1'b0;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < 64; i = i + 1)
					dct_output[(63 - i) * DCT_OUT_W+:DCT_OUT_W] <= 1'sb0;
			end
		end
		else begin
			if (dct_valid && reshape_ready)
				dct_valid <= 1'b0;
			if (dct_serial_valid && dct_serial_ready) begin
				dct_output[(63 - dct_serial_index) * DCT_OUT_W+:DCT_OUT_W] <= dct_serial_data;
				if (dct_serial_index == 6'd63)
					dct_valid <= 1'b1;
			end
		end
endmodule
