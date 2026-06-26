// -----------------------------------------------------------------------------
// skew_bufram64.sv
// -----------------------------------------------------------------------------
// Parallel input permutation for the DCT64 skew-DCT stage.
//
// DIN is in natural order din[0]..din[63].  DOUT is arranged as the paper's
// M_64^8 input permutation for the eight skew DCT-II_8 blocks:
//
//   x[i][j] = din[8*j + i]      when j is even
//   x[i][j] = din[8*j + 7 - i]  when j is odd
//
// DOUT lane 8*i+j feeds skew block i input j.
// -----------------------------------------------------------------------------

`ifndef SKEW_BUFRAM64_V
`define SKEW_BUFRAM64_V

`timescale 1 ns / 1 ps

module SKEW_BUFRAM64 #(
    parameter integer DATA_W = 16
)(
    input  var logic signed [DATA_W-1:0] DIN  [0:63],
    output wire signed [DATA_W-1:0] DOUT [0:63]
);

    generate
        for (genvar i = 0; i < 8; i++) begin : GEN_ROW
            for (genvar j = 0; j < 8; j++) begin : GEN_COL
                localparam integer SRC_LANE =
                    ((j % 2) == 0) ? (8*j + i) : (8*j + 7 - i);
                localparam integer DST_LANE = 8*i + j;

                assign DOUT[DST_LANE] = DIN[SRC_LANE];
            end
        end
    endgenerate

endmodule

`endif
