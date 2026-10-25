`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module reshape_output (
	clk,
	reset,
	in,
	out,
	s_valid,
	s_ready,
	m_valid,
	m_ready,
	m_last
);
	reg _sv2v_0;
	parameter signed [31:0] OUT_WIDTH = 1;
	parameter signed [31:0] DATA_WIDTH = 16;
	parameter signed [31:0] INPUT_POINTS = 64;
	input clk;
	input reset;
	input signed [(INPUT_POINTS * DATA_WIDTH) - 1:0] in;
	output wire signed [(OUT_WIDTH * DATA_WIDTH) - 1:0] out;
	input s_valid;
	output wire s_ready;
	output wire m_valid;
	input m_ready;
	output wire m_last;
	localparam OUT_LENGTH = INPUT_POINTS / OUT_WIDTH;
	localparam COUNTER_W = (OUT_LENGTH <= 1 ? 1 : clog2(OUT_LENGTH + 1));
	reg signed [(OUT_WIDTH * DATA_WIDTH) - 1:0] banks [0:OUT_LENGTH - 1];
	reg [COUNTER_W - 1:0] q_counter;
	reg [COUNTER_W - 1:0] d_counter;
	reg d_valid;
	reg q_valid;
	assign m_valid = q_valid;
	assign m_last = q_valid && (q_counter == (OUT_LENGTH - 1));
	assign out = banks[0];
	assign s_ready = !q_valid;
	always @(*) begin
		if (_sv2v_0)
			;
		d_counter = q_counter;
		d_valid = q_valid;
		if (s_valid & s_ready) begin
			d_counter = 1'sb0;
			d_valid = 1'b1;
		end
		else if (q_valid && m_ready) begin
			if (q_counter == (OUT_LENGTH - 1)) begin
				d_counter = 1'sb0;
				d_valid = 1'b0;
			end
			else begin
				d_counter = q_counter + 1'b1;
				d_valid = 1'b1;
			end
		end
	end
	always @(posedge clk or posedge reset)
		if (reset) begin
			q_counter <= 1'sb0;
			q_valid <= 0;
		end
		else begin
			q_counter <= d_counter;
			q_valid <= d_valid;
			if (s_valid & s_ready) begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < OUT_LENGTH; i = i + 1)
					begin : sv2v_autoblock_2
						reg signed [31:0] j;
						for (j = 0; j < OUT_WIDTH; j = j + 1)
							banks[i][((OUT_WIDTH - 1) - j) * DATA_WIDTH+:DATA_WIDTH] <= in[((INPUT_POINTS - 1) - (j + (i * OUT_WIDTH))) * DATA_WIDTH+:DATA_WIDTH];
					end
			end
			else if (m_valid & m_ready) begin : sv2v_autoblock_3
				reg signed [31:0] i;
				for (i = 0; i < (OUT_LENGTH - 1); i = i + 1)
					banks[i] <= banks[i + 1];
			end
		end
	initial _sv2v_0 = 0;

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
