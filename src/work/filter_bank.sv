`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/15/2019 12:19:58 AM
// Design Name:
// Module Name: filter_bank
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module filter_bank #(
    parameter int N = 256,
    parameter int NFILT = 64,
    parameter COEFF_FILE = "mel_filter_coeff_rom_nfilt64.mem"
)(
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] in,
    output logic [15:0] out [0:NFILT-1],
    input  logic        s_valid,
    output logic        s_ready,
    output logic        m_valid,
    input  logic        m_ready
);

    localparam int ROM_COLS = 1024;
    localparam int ROM_ROWS = 8;
    localparam int ROM_DEPTH = ROM_ROWS * ROM_COLS;
    // N is the number of power-spectrum bins consumed by this stage.
    localparam int ROW_IDX = $clog2(N) - 3;
    localparam int COUNTER_W = $clog2(NFILT + 2);


    logic [15:0] coeff_rom [0:ROM_DEPTH-1];
    logic [15:0] filt_shift_reg [0:N-1];
    logic [15:0] filt;
    logic        new_window [0:2];
    logic [15:0] bank_shift_reg [0:NFILT-1];
    logic [COUNTER_W-1:0] d_counter;
    logic [COUNTER_W-1:0] q_counter;
    logic        in_ready;
    logic        in_valid [0:2];
    logic [31:0] q_in;
    logic [31:0] product [0:1];
    logic [31:0] inverse [0:1];
    logic [31:0] q_ascending;
    logic [31:0] d_ascending;
    logic [31:0] q_descending;
    logic [31:0] d_descending;
    logic [31:0] accumulation;
    logic [15:0] dB;

    initial begin
        $readmemh(COEFF_FILE, coeff_rom);
        for (int i = 0; i < N; i++) begin
            filt_shift_reg[i] = coeff_rom[(ROW_IDX * ROM_COLS) + i];
        end
    end

    assign s_ready = in_ready && !m_valid;
    assign in_valid[0] = s_valid;
    assign filt = filt_shift_reg[0];
    assign new_window[0] = (filt == 16'd32768);

    assign inverse[0] = q_in - product[0];
    assign accumulation = q_ascending + product[1];

    assign out = bank_shift_reg;
    assign m_valid = (q_counter == COUNTER_W'(NFILT));

    dB_LUT dB_calculator (
        .in(q_descending),
        .out(dB),
        .on(new_window[2])
    );

    mult_gen_1 mult_im (
        .CLK(clk),
        .A(in),
        .B(filt),
        .P(product[0])
    );

    always_comb begin
        if (in_valid[2] && s_ready) begin
            if (new_window[2]) begin
                d_ascending = '0;
                d_descending = accumulation;
                d_counter = q_counter + 1'b1;
            end else begin
                d_ascending = accumulation;
                d_descending = q_descending + inverse[1];
                d_counter = q_counter;
            end
        end else begin
            d_ascending = q_ascending;
            d_descending = q_descending;
            if (m_valid && m_ready) begin
                d_counter = '0;
            end else begin
                d_counter = q_counter;
            end
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            in_ready <= 1'b0;
            q_in <= '0;
            new_window[1] <= 1'b0;
            new_window[2] <= 1'b0;
            in_valid[1] <= 1'b0;
            in_valid[2] <= 1'b0;
            product[1] <= '0;
            inverse[1] <= '0;
            q_counter <= '0;
            q_ascending <= '0;
            q_descending <= '0;

            for (int i = 0; i < N; i++) begin
                filt_shift_reg[i] <= coeff_rom[(ROW_IDX * ROM_COLS) + i];
            end

            for (int i = 0; i < NFILT; i++) begin
                bank_shift_reg[i] <= '0;
            end
        end else begin
            in_ready <= 1'b1;
            q_in <= in;
            new_window[1] <= new_window[0];
            new_window[2] <= new_window[1];
            in_valid[1] <= in_valid[0];
            in_valid[2] <= in_valid[1];
            product[1] <= product[0];
            inverse[1] <= inverse[0];
            q_counter <= d_counter;
            q_ascending <= d_ascending;
            q_descending <= d_descending;

            if (s_valid && s_ready) begin
                filt_shift_reg[N-1] <= filt_shift_reg[0];
                filt_shift_reg[0:N-2] <= filt_shift_reg[1:N-1];
            end

            if (new_window[2] && in_valid[2]) begin
                bank_shift_reg[NFILT-1] <= dB;
                bank_shift_reg[0:NFILT-2] <= bank_shift_reg[1:NFILT-1];
            end
        end
    end
endmodule
