// SystemVerilog generated from Verilog
`timescale 1ns / 1ps

module ROTATOR64(
                 CLK,
                 RST,
                 ED,
                 START,
                 DR,
                 DI,
                 DOR,
                 DOI,
                 RDY
                 );

parameter nb =16;
parameter nw =10;

input RST;
input CLK;
input ED;
input [nb-1:0] DI;
input [nb-1:0] DR;
input START;

output [nb-1:0] DOI;
output [nb-1:0] DOR;
output RDY;

reg [7:0] addrw;
reg sd1;
reg sd2;
reg rdy_r;

wire [7:0] twiddle_exp;
wire [10:0] twiddle_addr;
wire signed [nw-1:0] wr;
wire signed [nw-1:0] wi;
reg signed [nb-1:0] drd;
reg signed [nb-1:0] did;
reg signed [nw-1:0] wrd;
reg signed [nw-1:0] wid;
wire signed [nb:0] rot_re;
wire signed [nb:0] rot_im;
reg signed [nb:0] rot_re_d;
reg signed [nb:0] rot_im_d;
reg signed [nb:0] dwr;
reg signed [nb:0] dwi;

assign twiddle_exp = {4'd0, addrw[7:4]} * {4'd0, addrw[3:0]};
assign twiddle_addr = {twiddle_exp, 3'b000};

WROM2048 #(.TW(nw)) UROM (
    .ADDR(twiddle_addr),
    .WR(wr),
    .WI(wi)
);

complex_twiddle_mul #(
    .NB(nb),
    .TW(nw),
    .OUTW(nb + 1),
    .SHIFT(nw - 1),
    .SHIFT_AFTER_SUM(1'b0)
) complex_twiddle_mul_i (
    .x_re(drd),
    .x_im(did),
    .w_re(wrd),
    .w_im(wid),
    .y_re(rot_re),
    .y_im(rot_im)
);

always @(posedge CLK) begin
    if (RST) begin
        addrw <= 8'd0;
        sd1   <= 1'b0;
        sd2   <= 1'b0;
        rdy_r <= 1'b0;
    end else if (START && ED) begin
        addrw <= 8'd0;
        sd1   <= START;
        sd2   <= 1'b0;
        rdy_r <= 1'b0;
    end else if (ED) begin
        addrw <= addrw + 8'd1;
        sd1   <= START;
        sd2   <= sd1;
        rdy_r <= sd2;
    end
end

always @(posedge CLK) begin
    if (RST) begin
        drd      <= {nb{1'b0}};
        did      <= {nb{1'b0}};
        wrd      <= {nw{1'b0}};
        wid      <= {nw{1'b0}};
        rot_re_d <= {(nb + 1){1'b0}};
        rot_im_d <= {(nb + 1){1'b0}};
        dwr      <= {(nb + 1){1'b0}};
        dwi      <= {(nb + 1){1'b0}};
    end else if (ED) begin
        drd      <= DR;
        did      <= DI;
        wrd      <= wr;
        wid      <= wi;
        rot_re_d <= rot_re;
        rot_im_d <= rot_im;
        dwr      <= rot_re_d;
        dwi      <= rot_im_d;
    end
end

assign DOR = dwr[nb:1];
assign DOI = dwi[nb:1];
assign RDY = rdy_r;

endmodule
