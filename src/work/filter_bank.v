`timescale 1ns/1ps
// Converted from current MFCC SV; see source_manifest.json.
module filter_bank (
	clk,
	reset,
	in,
	out,
	s_valid,
	s_ready,
	m_valid,
	m_ready
);
	reg _sv2v_0;
	parameter signed [31:0] N = 256;
	parameter signed [31:0] NFILT = 64;
	parameter signed [31:0] FLOOR_LOG2 = -16;
	parameter COEFF_FILE = "mel_sparse_q15.mem";
	parameter LOG_FILE = "log20_mantissa_q20.mem";
	input wire clk;
	input wire reset;
	input wire [31:0] in;
	output reg [(NFILT * 16) - 1:0] out;
	input wire s_valid;
	output wire s_ready;
	output wire m_valid;
	input wire m_ready;
	localparam signed [31:0] ROW_IDX = clog2(N) - 3;
	localparam signed [31:0] ENERGY_FRAC_BITS = 45 - clog2(2 * N);
	localparam [63:0] ENERGY_FLOOR = 64'd1 << (ENERGY_FRAC_BITS + FLOOR_LOG2);
	reg [1:0] state;
	reg [clog2(N) - 1:0] bin_index;
	reg [6:0] log_index;
	reg [45:0] coeff_rom [0:8191];
	reg [23:0] log_rom [0:1023];
	reg [63:0] energy [0:NFILT - 1];
	wire [45:0] entry = coeff_rom[(ROW_IDX * 1024) + bin_index];
	wire [6:0] band_a = entry[45:39];
	wire [6:0] band_b = entry[22:16];
	wire [15:0] weight_a = entry[38:23];
	wire [15:0] weight_b = entry[15:0];
	wire [47:0] product_a = in * weight_a;
	wire [47:0] product_b = in * weight_b;
	reg [63:0] clamped_energy;
	reg [63:0] normalized_energy;
	integer exponent;
	reg signed [31:0] log_scaled;
	reg signed [15:0] log_value;
	initial begin
		if (NFILT != 64) begin
			$display("Fatal [%0t] src\work\filter_bank.sv:39:26 - filter_bank.<unnamed_block>.<unnamed_block>\n msg: ", $time, "Generate a matching ROM before changing NFILT");
			$finish(1);
		end
		if ((((ENERGY_FRAC_BITS + FLOOR_LOG2) < 0) || (FLOOR_LOG2 < -21)) || (FLOOR_LOG2 > 0)) begin
			$display("Fatal [%0t] src\work\filter_bank.sv:41:13 - filter_bank.<unnamed_block>.<unnamed_block>\n msg: ", $time, "Log floor outside representable Q8 energy range");
			$finish(1);
		end
		$readmemh(COEFF_FILE, coeff_rom);
		$readmemh(LOG_FILE, log_rom);
	end
	assign s_ready = state == 2'd0;
	assign m_valid = state == 2'd2;
	always @(*) begin
		if (_sv2v_0)
			;
		clamped_energy = energy[(log_index < NFILT ? log_index : 0)];
		if (clamped_energy < ENERGY_FLOOR)
			clamped_energy = ENERGY_FLOOR;
		exponent = 0;
		begin : sv2v_autoblock_1
			reg signed [31:0] b;
			for (b = 0; b < 64; b = b + 1)
				if (clamped_energy[b])
					exponent = b;
		end
		normalized_energy = clamped_energy << (63 - exponent);
		log_scaled = ((exponent - ENERGY_FRAC_BITS) * 32'sd6313057) + $signed({1'b0, log_rom[normalized_energy[62:53]]});
		log_value = (log_scaled + 32'sd2048) >>> 12;
	end
	always @(posedge clk or posedge reset)
		if (reset) begin
			state <= 2'd0;
			bin_index <= 0;
			log_index <= 0;
			begin : sv2v_autoblock_2
				reg signed [31:0] i;
				for (i = 0; i < NFILT; i = i + 1)
					begin
						energy[i] <= 0;
						out[((NFILT - 1) - i) * 16+:16] <= 0;
					end
			end
		end
		else
			case (state)
				2'd0:
					if (s_valid && s_ready) begin
						if (band_a < NFILT)
							energy[band_a] <= energy[band_a] + product_a;
						if (band_b < NFILT)
							energy[band_b] <= energy[band_b] + product_b;
						if (bin_index == (N - 1)) begin
							bin_index <= 0;
							log_index <= 0;
							state <= 2'd1;
						end
						else
							bin_index <= bin_index + 1'b1;
					end
				2'd1: begin
					out[((NFILT - 1) - log_index) * 16+:16] <= log_value;
					if (log_index == (NFILT - 1))
						state <= 2'd2;
					else
						log_index <= log_index + 1'b1;
				end
				2'd2:
					if (m_valid && m_ready) begin
						begin : sv2v_autoblock_3
							reg signed [31:0] i;
							for (i = 0; i < NFILT; i = i + 1)
								energy[i] <= 0;
						end
						state <= 2'd0;
					end
				default: state <= 2'd0;
			endcase
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
