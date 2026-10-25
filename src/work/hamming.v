`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module hamming (
	clk,
	reset,
	in,
	out,
	on
);
	parameter signed [31:0] N = 512;
	parameter COEFF_FILE = "hamming_coeff_rom.mem";
	input wire clk;
	input wire reset;
	input wire [15:0] in;
	output wire [15:0] out;
	input wire on;
	localparam signed [31:0] ROM_COLS = 2048;
	localparam signed [31:0] ROM_ROWS = 8;
	localparam signed [31:0] ROM_DEPTH = ROM_ROWS * ROM_COLS;
	localparam signed [31:0] ROW_IDX = clog2(N) - 4;
	reg [15:0] coeff_rom [0:ROM_DEPTH - 1];
	reg [(N * 16) - 1:0] shift_reg;
	wire signed [31:0] result;
	initial begin
		$readmemh(COEFF_FILE, coeff_rom);
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < N; i = i + 1)
				shift_reg[((N - 1) - i) * 16+:16] = coeff_rom[(ROW_IDX * ROM_COLS) + i];
		end
	end
	assign result = $signed(shift_reg[(N - 1) * 16+:16]) * $signed(in);
	assign out = result >>> 14;
	always @(posedge clk)
		if (reset) begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < N; i = i + 1)
				shift_reg[((N - 1) - i) * 16+:16] <= coeff_rom[(ROW_IDX * ROM_COLS) + i];
		end
		else if (on) begin
			shift_reg[((N - 1) - (N - 1)) * 16+:16] <= shift_reg[(N - 1) * 16+:16];
			shift_reg[16 * ((N - 1) - (0 >= (N - 2) ? 0 : (0 >= (N - 2) ? 3 - N : N - 1) - 1))+:16 * (0 >= (N - 2) ? 3 - N : N - 1)] <= shift_reg[16 * ((N - 1) - (1 >= (N - 1) ? 1 : (1 + (1 >= (N - 1) ? 3 - N : N - 1)) - 1))+:16 * (1 >= (N - 1) ? 3 - N : N - 1)];
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
