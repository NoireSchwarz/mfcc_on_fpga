`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module radix4_merge_stage (
	clk,
	rst,
	start,
	in0_re,
	in0_im,
	in1_re,
	in1_im,
	in2_re,
	in2_im,
	in3_re,
	in3_im,
	out_valid,
	busy,
	out_re,
	out_im
);
	parameter signed [31:0] NB = 16;
	parameter signed [31:0] TW = 16;
	parameter signed [31:0] N = 64;
	parameter signed [31:0] SPAN = N / 4;
	input wire clk;
	input wire rst;
	input wire start;
	input wire signed [(SPAN * NB) - 1:0] in0_re;
	input wire signed [(SPAN * NB) - 1:0] in0_im;
	input wire signed [(SPAN * NB) - 1:0] in1_re;
	input wire signed [(SPAN * NB) - 1:0] in1_im;
	input wire signed [(SPAN * NB) - 1:0] in2_re;
	input wire signed [(SPAN * NB) - 1:0] in2_im;
	input wire signed [(SPAN * NB) - 1:0] in3_re;
	input wire signed [(SPAN * NB) - 1:0] in3_im;
	output reg out_valid;
	output reg busy;
	output reg signed [(N * NB) - 1:0] out_re;
	output reg signed [(N * NB) - 1:0] out_im;
	localparam signed [31:0] STRIDE = 2048 / N;
	localparam [1:0] MODE_RADIX4 = 2'd2;
	reg [1:0] state;
	reg [clog2(SPAN) - 1:0] cnt;
	reg kernel_start;
	wire kernel_valid;
	wire kernel_busy;
	wire signed [TW - 1:0] tw1_re;
	wire signed [TW - 1:0] tw1_im;
	wire signed [TW - 1:0] tw2_re;
	wire signed [TW - 1:0] tw2_im;
	wire signed [TW - 1:0] tw3_re;
	wire signed [TW - 1:0] tw3_im;
	wire [10:0] tw1_addr;
	wire [10:0] tw2_addr;
	wire [10:0] tw3_addr;
	wire [31:0] tw_base_addr;
	wire [31:0] tw2_addr_raw;
	wire [31:0] tw3_addr_raw;
	wire signed [NB - 1:0] y0_re;
	wire signed [NB - 1:0] y0_im;
	wire signed [NB - 1:0] y1_re;
	wire signed [NB - 1:0] y1_im;
	wire signed [NB - 1:0] y2_re;
	wire signed [NB - 1:0] y2_im;
	wire signed [NB - 1:0] y3_re;
	wire signed [NB - 1:0] y3_im;
	assign tw_base_addr = cnt * STRIDE;
	assign tw2_addr_raw = tw_base_addr << 1;
	assign tw3_addr_raw = tw_base_addr + (tw_base_addr << 1);
	assign tw1_addr = tw_base_addr[10:0];
	assign tw2_addr = tw2_addr_raw[10:0];
	assign tw3_addr = tw3_addr_raw[10:0];
	WROM2048 #(.TW(TW)) twiddle1_i(
		.ADDR(tw1_addr),
		.WR(tw1_re),
		.WI(tw1_im)
	);
	WROM2048 #(.TW(TW)) twiddle2_i(
		.ADDR(tw2_addr),
		.WR(tw2_re),
		.WI(tw2_im)
	);
	WROM2048 #(.TW(TW)) twiddle3_i(
		.ADDR(tw3_addr),
		.WR(tw3_re),
		.WI(tw3_im)
	);
	fft_merge_kernel #(
		.NB(NB),
		.TW(TW)
	) kernel_i(
		.clk(clk),
		.rst(rst),
		.start(kernel_start),
		.mode(MODE_RADIX4),
		.x0_re(in0_re[((SPAN - 1) - cnt) * NB+:NB]),
		.x0_im(in0_im[((SPAN - 1) - cnt) * NB+:NB]),
		.x1_re(in1_re[((SPAN - 1) - cnt) * NB+:NB]),
		.x1_im(in1_im[((SPAN - 1) - cnt) * NB+:NB]),
		.x2_re(in2_re[((SPAN - 1) - cnt) * NB+:NB]),
		.x2_im(in2_im[((SPAN - 1) - cnt) * NB+:NB]),
		.x3_re(in3_re[((SPAN - 1) - cnt) * NB+:NB]),
		.x3_im(in3_im[((SPAN - 1) - cnt) * NB+:NB]),
		.w1_re(tw1_re),
		.w1_im(tw1_im),
		.w2_re(tw2_re),
		.w2_im(tw2_im),
		.w3_re(tw3_re),
		.w3_im(tw3_im),
		.valid(kernel_valid),
		.busy(kernel_busy),
		.y0_re(y0_re),
		.y0_im(y0_im),
		.y1_re(y1_re),
		.y1_im(y1_im),
		.y2_re(y2_re),
		.y2_im(y2_im),
		.y3_re(y3_re),
		.y3_im(y3_im)
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
						out_re[((N - 1) - (cnt + SPAN)) * NB+:NB] <= y1_re;
						out_im[((N - 1) - (cnt + SPAN)) * NB+:NB] <= y1_im;
						out_re[((N - 1) - (cnt + (2 * SPAN))) * NB+:NB] <= y2_re;
						out_im[((N - 1) - (cnt + (2 * SPAN))) * NB+:NB] <= y2_im;
						out_re[((N - 1) - (cnt + (3 * SPAN))) * NB+:NB] <= y3_re;
						out_im[((N - 1) - (cnt + (3 * SPAN))) * NB+:NB] <= y3_im;
						if (cnt == (SPAN - 1)) begin
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
