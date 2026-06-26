`timescale 1ns / 1ps
`include "mfcc_config.sv"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/02/2019 10:38:39 PM
// Design Name: 
// Module Name: mfcc
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


module mfcc
    #(
//    parameter SAMPLE_RATE = 20000,
//    parameter clk_f = 200000000,

    parameter N = 512,          // Must be power of 2. Replace shift registers in hamming and filter_bank with python generated line when N is not 512
    parameter STRIDE = 256,     // Must be power of 2
    parameter OUT_WIDTH = 1,    // Must divide RESHAPE_POINTS
    parameter DCT_DATA_W = 16,
    parameter DCT_SKEW_OUT_W = 24,
    parameter DCT_OUT_W = DCT_SKEW_OUT_W + 2,
    parameter POWER_SPEC_OUT_W = 32,
`ifdef MFCC_ENABLE_DCT
    parameter RESHAPE_POINTS = 64,
    parameter M_AXIS_DATA_W = DCT_OUT_W
`else
    parameter RESHAPE_POINTS = N/2,
    parameter M_AXIS_DATA_W = POWER_SPEC_OUT_W
`endif
    )(
    input clk,
    input reset,
    input [15:0] s_axis_tdata,
    output signed [M_AXIS_DATA_W-1:0] m_axis_tdata[OUT_WIDTH],
    
    output s_axis_tready,
    input s_axis_tvalid,
    
    input m_axis_tready,
    output m_axis_tvalid,
    output m_axis_tlast
    );
    
    logic [15:0]q_hamming_input;
    logic [15:0]d_hamming_input;
    logic [15:0]q_power_spec_input;
    logic [15:0]d_power_spec_input;
    logic [31:0]d_filter_bank_input;
    logic [31:0]q_filter_bank_input;
`ifdef MFCC_ENABLE_DCT
    logic [15:0]filter_bank_output[40];
    logic signed [DCT_OUT_W-1:0]dct_output[64];
    logic signed [DCT_DATA_W-1:0]q_dct_input[40];
`else
    logic signed [POWER_SPEC_OUT_W-1:0]power_spec_output[RESHAPE_POINTS];
    localparam POWER_SPEC_COUNTER_W = (RESHAPE_POINTS <= 1) ? 1 : $clog2(RESHAPE_POINTS);
    logic [POWER_SPEC_COUNTER_W-1:0] q_power_spec_counter;
    logic reshape_input_valid;
`endif
    
    logic pow_spec_ready;
    logic q_frame_valid;
    logic qq_frame_valid;
    logic d_frame_valid;
`ifdef MFCC_ENABLE_DCT
    logic filt_bank_ready;
`endif
    logic d_pow_spec_valid;
    logic q_pow_spec_valid;
//    logic pow_spec_last;
    logic reshape_ready;
`ifdef MFCC_ENABLE_DCT
    logic filt_bank_valid;
    logic q_filt_bank_valid;
    logic dct_valid;
    logic dct_ready;
`endif
    
    prepare_input #(.N(N),
                    .STRIDE(STRIDE)) my_in
                                           (.clk(clk),
                                            .reset(reset),
                                            .in(s_axis_tdata),
                                            .out(d_hamming_input),
                                            .s_ready(s_axis_tready),
                                            .s_valid(s_axis_tvalid),
                                            .m_ready(pow_spec_ready),
                                            .m_valid(d_frame_valid));
    
    hamming#(.N(N)) my_hamming
                                        (.clk(clk),
                                         .reset(reset),
                                         .in(q_hamming_input),
                                         .out(d_power_spec_input),
                                         .on(q_frame_valid & pow_spec_ready)
                                         );
                       
    power_spectrum#(.N(N)) my_pow_spec
                                       (.clk(clk),
                                        .reset(reset),
                                        .in(q_power_spec_input),
                                        .out(d_filter_bank_input),
                                        .s_ready(pow_spec_ready),
                                        .s_valid(qq_frame_valid),
                                        .s_last(1'b0),
`ifdef MFCC_ENABLE_DCT
                                        .m_ready(filt_bank_ready),
`else
                                        .m_ready(!reshape_input_valid),
`endif
                                        .m_valid(d_pow_spec_valid),
                                        .m_last()
                                        );

`ifdef MFCC_ENABLE_DCT
    filter_bank#(.N(N/2)) my_filt_bank
                                             (.clk(clk),
                                              .reset(reset),
                                              .in(q_filter_bank_input),
                                              .out(filter_bank_output),
                                              .s_ready(filt_bank_ready),
                                              .s_valid(q_pow_spec_valid),
                                              .m_ready(dct_ready),
                                              .m_valid(filt_bank_valid)
                                              );

    dct40_64 #(.DATA_W(DCT_DATA_W),
               .SKEW_OUT_W(DCT_SKEW_OUT_W),
               .C_OUT_W(DCT_OUT_W)) my_dct
                                           (.clk(clk),
                                            .rst(reset),
                                            .shift(4'b0000),
                                            .s_data(q_dct_input),
                                            .s_valid(q_filt_bank_valid),
                                            .s_ready(dct_ready),
                                            .m_data(dct_output),
                                            .m_valid(dct_valid),
                                            .m_ready(reshape_ready),
                                            .ovf_skew(),
                                            .ovf_dct());
    
    // dct output is already 64 wide                                          
    if(OUT_WIDTH != 64) begin
        reshape_output#(.OUT_WIDTH(OUT_WIDTH),
                         .DATA_WIDTH(DCT_OUT_W),
                         .INPUT_POINTS(RESHAPE_POINTS)) my_out(.clk(clk),
                                                               .reset(reset),
                                                               .in(dct_output),
                                                               .out(m_axis_tdata),
                                                               .s_ready(reshape_ready),
                                                               .s_valid(dct_valid),
                                                               .m_ready(m_axis_tready),
                                                               .m_valid(m_axis_tvalid),
                                                               .m_last(m_axis_tlast));
    end
    else begin
        assign m_axis_tdata = dct_output;
        assign reshape_ready = m_axis_tready;
        assign m_axis_tvalid = dct_valid;
        assign m_axis_tlast = dct_valid;
    end
`else
    reshape_output#(.OUT_WIDTH(OUT_WIDTH),
                     .DATA_WIDTH(POWER_SPEC_OUT_W),
                     .INPUT_POINTS(RESHAPE_POINTS)) my_out(.clk(clk),
                                                           .reset(reset),
                                                           .in(power_spec_output),
                                                           .out(m_axis_tdata),
                                                           .s_ready(reshape_ready),
                                                           .s_valid(reshape_input_valid),
                                                           .m_ready(m_axis_tready),
                                                           .m_valid(m_axis_tvalid),
                                                           .m_last(m_axis_tlast));
`endif
    
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            q_filter_bank_input <= '0;
            q_pow_spec_valid <= 1'b0;
            q_power_spec_input <= '0;
            q_hamming_input <= '0;
            q_frame_valid <= 1'b0;
            qq_frame_valid <= 1'b0;
`ifdef MFCC_ENABLE_DCT
            q_filt_bank_valid <= 1'b0;
            for(int i=0; i<40; i++) begin
                q_dct_input[i] <= '0;
            end
`else
            q_power_spec_counter <= '0;
            reshape_input_valid <= 1'b0;
            for(int i=0; i<RESHAPE_POINTS; i++) begin
                power_spec_output[i] <= '0;
            end
`endif
        end
        else begin
`ifdef MFCC_ENABLE_DCT
            if(filt_bank_ready) begin
                q_filter_bank_input <= d_filter_bank_input;
                q_pow_spec_valid <= d_pow_spec_valid;
            end
`endif
            if(pow_spec_ready) begin
                q_power_spec_input <= d_power_spec_input;
                q_hamming_input <= d_hamming_input;
            end
`ifdef MFCC_ENABLE_DCT
            q_filt_bank_valid <= 1'b0;
            if(filt_bank_valid && dct_ready) begin
                for(int i=0; i<40; i++) begin
                    q_dct_input[i] <= DCT_DATA_W'(filter_bank_output[i]);
                end
                q_filt_bank_valid <= 1'b1;
            end
`else
            if(reshape_input_valid && reshape_ready) begin
                reshape_input_valid <= 1'b0;
            end

            if(d_pow_spec_valid && !reshape_input_valid) begin
                power_spec_output[q_power_spec_counter] <= POWER_SPEC_OUT_W'(d_filter_bank_input);

                if(q_power_spec_counter == RESHAPE_POINTS-1) begin
                    q_power_spec_counter <= '0;
                    reshape_input_valid <= 1'b1;
                end
                else begin
                    q_power_spec_counter <= q_power_spec_counter + 1'b1;
                end
            end
`endif
            q_frame_valid <= d_frame_valid;
            qq_frame_valid <= q_frame_valid;
        end
    end
endmodule
