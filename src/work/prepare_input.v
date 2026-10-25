`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module prepare_input (
	clk,
	reset,
	in,
	out,
	s_valid,
	s_ready,
	m_valid,
	m_ready
);
	parameter N = 512;
	parameter STRIDE = 64;
	parameter PRE_EMPH_COEFF = 16'd0;
	input clk;
	input reset;
	input [15:0] in;
	output wire [15:0] out;
	input s_valid;
	output wire s_ready;
	output wire m_valid;
	input m_ready;
	localparam CW = clog2(N + 1);
	reg [15:0] frame [0:N - 1];
	reg [CW - 1:0] collected;
	reg [CW - 1:0] output_index;
	reg emitting;
	reg signed [15:0] previous_sample;
	wire signed [31:0] pre_product = $signed(PRE_EMPH_COEFF) * previous_sample;
	wire signed [31:0] emphasized = $signed(in) - (pre_product >>> 15);
	assign s_ready = !emitting;
	assign m_valid = emitting;
	assign out = frame[(N - 1) - output_index];
	initial if ((STRIDE < 1) || (STRIDE > N)) begin
		$display("Fatal [%0t] src\work\prepare_input.sv:23:39 - prepare_input.<unnamed_block>.<unnamed_block>\n msg: ", $time, "Require 1 <= STRIDE <= N");
		$finish(1);
	end
	always @(posedge clk or posedge reset)
		if (reset) begin
			collected <= 0;
			output_index <= 0;
			emitting <= 0;
			previous_sample <= 0;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < N; i = i + 1)
					frame[i] <= 0;
			end
		end
		else begin
			if (s_valid && s_ready) begin
				if (emphasized > 32767)
					frame[0] <= 16'h7fff;
				else if (emphasized < -32768)
					frame[0] <= 16'h8000;
				else
					frame[0] <= emphasized[15:0];
				begin : sv2v_autoblock_2
					reg signed [31:0] i;
					for (i = 1; i < N; i = i + 1)
						frame[i] <= frame[i - 1];
				end
				previous_sample <= $signed(in);
				if (collected == (STRIDE - 1)) begin
					collected <= 0;
					output_index <= 0;
					emitting <= 1;
				end
				else
					collected <= collected + 1'b1;
			end
			if (m_valid && m_ready) begin
				if (output_index == (N - 1)) begin
					emitting <= 0;
					output_index <= 0;
				end
				else
					output_index <= output_index + 1'b1;
			end
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
