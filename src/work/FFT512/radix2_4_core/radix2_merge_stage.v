`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module radix2_merge_stage (
	clk,
	rst,
	start,
	even_re,
	even_im,
	odd_re,
	odd_im,
	out_valid,
	busy,
	out_re,
	out_im
);
	parameter signed [31:0] NB = 16;
	parameter signed [31:0] TW = 16;
	parameter signed [31:0] N = 512;
	parameter signed [31:0] HALF = N / 2;
	input wire clk;
	input wire rst;
	input wire start;
	input wire signed [(HALF * NB) - 1:0] even_re;
	input wire signed [(HALF * NB) - 1:0] even_im;
	input wire signed [(HALF * NB) - 1:0] odd_re;
	input wire signed [(HALF * NB) - 1:0] odd_im;
	output reg out_valid;
	output reg busy;
	output reg signed [(N * NB) - 1:0] out_re;
	output reg signed [(N * NB) - 1:0] out_im;
	localparam signed [31:0] STRIDE = 2048 / N;
	localparam [1:0] MODE_RADIX2 = 2'd1;
	reg [1:0] state;
	reg [clog2(HALF) - 1:0] cnt;
	reg kernel_start;
	wire kernel_valid;
	wire kernel_busy;
	wire signed [TW - 1:0] tw_re;
	wire signed [TW - 1:0] tw_im;
	wire [10:0] tw_addr;
	wire signed [NB - 1:0] y0_re;
	wire signed [NB - 1:0] y0_im;
	wire signed [NB - 1:0] y1_re;
	wire signed [NB - 1:0] y1_im;
	wire signed [NB - 1:0] unused_y2_re;
	wire signed [NB - 1:0] unused_y2_im;
	wire signed [NB - 1:0] unused_y3_re;
	wire signed [NB - 1:0] unused_y3_im;
	wire [31:0] tw_addr_raw;
	assign tw_addr_raw = cnt * STRIDE;
	assign tw_addr = tw_addr_raw[10:0];
	WROM2048 #(.TW(TW)) twiddle_i(
		.ADDR(tw_addr),
		.WR(tw_re),
		.WI(tw_im)
	);
	localparam signed [31:0] sv2v_uu_kernel_i_NB = NB;
	localparam signed [sv2v_uu_kernel_i_NB - 1:0] sv2v_uu_kernel_i_ext_x2_re_0 = 1'sb0;
	localparam signed [sv2v_uu_kernel_i_NB - 1:0] sv2v_uu_kernel_i_ext_x2_im_0 = 1'sb0;
	localparam signed [sv2v_uu_kernel_i_NB - 1:0] sv2v_uu_kernel_i_ext_x3_re_0 = 1'sb0;
	localparam signed [sv2v_uu_kernel_i_NB - 1:0] sv2v_uu_kernel_i_ext_x3_im_0 = 1'sb0;
	localparam signed [31:0] sv2v_uu_kernel_i_TW = TW;
	localparam signed [sv2v_uu_kernel_i_TW - 1:0] sv2v_uu_kernel_i_ext_w2_re_0 = 1'sb0;
	localparam signed [sv2v_uu_kernel_i_TW - 1:0] sv2v_uu_kernel_i_ext_w2_im_0 = 1'sb0;
	localparam signed [sv2v_uu_kernel_i_TW - 1:0] sv2v_uu_kernel_i_ext_w3_re_0 = 1'sb0;
	localparam signed [sv2v_uu_kernel_i_TW - 1:0] sv2v_uu_kernel_i_ext_w3_im_0 = 1'sb0;
	fft_merge_kernel #(
		.NB(NB),
		.TW(TW)
	) kernel_i(
		.clk(clk),
		.rst(rst),
		.start(kernel_start),
		.mode(MODE_RADIX2),
		.x0_re(even_re[((HALF - 1) - cnt) * NB+:NB]),
		.x0_im(even_im[((HALF - 1) - cnt) * NB+:NB]),
		.x1_re(odd_re[((HALF - 1) - cnt) * NB+:NB]),
		.x1_im(odd_im[((HALF - 1) - cnt) * NB+:NB]),
		.x2_re(sv2v_uu_kernel_i_ext_x2_re_0),
		.x2_im(sv2v_uu_kernel_i_ext_x2_im_0),
		.x3_re(sv2v_uu_kernel_i_ext_x3_re_0),
		.x3_im(sv2v_uu_kernel_i_ext_x3_im_0),
		.w1_re(tw_re),
		.w1_im(tw_im),
		.w2_re(sv2v_uu_kernel_i_ext_w2_re_0),
		.w2_im(sv2v_uu_kernel_i_ext_w2_im_0),
		.w3_re(sv2v_uu_kernel_i_ext_w3_re_0),
		.w3_im(sv2v_uu_kernel_i_ext_w3_im_0),
		.valid(kernel_valid),
		.busy(kernel_busy),
		.y0_re(y0_re),
		.y0_im(y0_im),
		.y1_re(y1_re),
		.y1_im(y1_im),
		.y2_re(unused_y2_re),
		.y2_im(unused_y2_im),
		.y3_re(unused_y3_re),
		.y3_im(unused_y3_im)
	);
	always @(posedge clk)
		if (rst) begin
			state <= 2'd0;
			cnt <= 1'sb0;
			out_valid <= 1'b0;
			busy <= 1'b0;
			kernel_start <= 1'b0;
		end
		else begin
			kernel_start <= 1'b0;
			out_valid <= 1'b0;
			case (state)
				2'd0: begin
					busy <= 1'b0;
					if (start) begin
						cnt <= 1'sb0;
						busy <= 1'b1;
						state <= 2'd1;
					end
				end
				2'd1: begin
					kernel_start <= 1'b1;
					state <= 2'd2;
				end
				2'd2:
					if (kernel_valid) begin
						out_re[((N - 1) - cnt) * NB+:NB] <= y0_re;
						out_im[((N - 1) - cnt) * NB+:NB] <= y0_im;
						out_re[((N - 1) - (cnt + HALF)) * NB+:NB] <= y1_re;
						out_im[((N - 1) - (cnt + HALF)) * NB+:NB] <= y1_im;
						if (cnt == (HALF - 1)) begin
							out_valid <= 1'b1;
							busy <= 1'b0;
							state <= 2'd0;
						end
						else begin
							cnt <= cnt + 1'b1;
							state <= 2'd1;
						end
					end
			endcase
		end

    // Verilog-2001 constant function (replaces the Verilog-2005 $clog2).
    function integer clog2;
        input integer value;
        integer remaining;
        begin
            remaining = value - 1;
            clog2 = 0;
            while (remaining > 0) begin
                clog2 = clog2 + 1;
                remaining = remaining >> 1;
            end
        end
    endfunction
endmodule
