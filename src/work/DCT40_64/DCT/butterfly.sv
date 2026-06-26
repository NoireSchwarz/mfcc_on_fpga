`timescale 1ns / 1ps

module butterfly #(
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = IN_WIDTH + 1
) (
    output reg signed [OUT_WIDTH-1:0] sum, diff,
    input signed [IN_WIDTH-1:0] x, y,
    input en
    );

always @(*)
begin
  if (en) begin
    sum = {x[IN_WIDTH-1], x} + {y[IN_WIDTH-1], y};
    diff = {x[IN_WIDTH-1], x} - {y[IN_WIDTH-1], y};
  end else begin
    sum = 0;
    diff = 0;
  end
end
endmodule
