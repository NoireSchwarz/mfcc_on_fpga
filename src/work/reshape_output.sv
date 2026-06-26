`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2019 12:40:45 AM
// Design Name: 
// Module Name: reshape_output
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

module reshape_output#(
    parameter int OUT_WIDTH = 1,
    parameter int DATA_WIDTH = 16,
    parameter int INPUT_POINTS = 64
)(
    input clk,
    input reset,
    input signed [DATA_WIDTH-1:0] in[INPUT_POINTS],
    output signed [DATA_WIDTH-1:0] out[OUT_WIDTH],
    
    input s_valid,
    output s_ready,
    output m_valid,
    input m_ready,
    output m_last
    );
    localparam OUT_LENGTH = INPUT_POINTS/OUT_WIDTH;
    localparam COUNTER_W = (OUT_LENGTH <= 1) ? 1 : $clog2(OUT_LENGTH + 1);
    
    logic signed [DATA_WIDTH-1:0] banks[OUT_LENGTH][OUT_WIDTH];
    logic [COUNTER_W-1:0] q_counter;
    logic [COUNTER_W-1:0] d_counter;
    
    logic d_valid;
    logic q_valid;
    
    assign m_valid = q_valid;
    assign m_last = q_valid && (q_counter == OUT_LENGTH-1);
    assign out = banks[0];
    assign s_ready = !q_valid;
    
    always_comb begin
        d_counter = q_counter;
        d_valid = q_valid;

        if(s_valid & s_ready) begin
            d_counter = '0;
            d_valid = 1'b1;
        end
        else if(q_valid && m_ready) begin
            if(q_counter == OUT_LENGTH-1) begin
                d_counter = '0;
                d_valid = 1'b0;
            end else begin
                d_counter = q_counter + 1'b1;
                d_valid = 1'b1;
            end
        end
    end
    
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            q_counter <= '0;
            q_valid <= 0;
        end
        else begin
            q_counter <= d_counter;
            q_valid <= d_valid;

              if(s_valid & s_ready) begin
                  for(int i=0; i<OUT_LENGTH; i++) begin
                      for(int j=0; j<OUT_WIDTH; j++) begin
                          banks[i][j] <= in[j + i*OUT_WIDTH];
                      end
                  end
              end
              else if(m_valid & m_ready) begin
                for(int i=0; i<OUT_LENGTH-1; i++) begin
                    banks[i] <= banks[i+1];
                end
              end
        end
    
    end
endmodule
