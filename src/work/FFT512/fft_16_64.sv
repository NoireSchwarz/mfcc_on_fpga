`timescale 1ns / 1ps

module fft_16_64 #(
    parameter int NB = 16,
    parameter int TW = 16,
    parameter int N = 16
)(
    input  logic                 RST,
    input  logic                 ED,
    input  logic                 CLK,
    input  logic                 START,
    input  logic signed [NB-1:0] DIR,
    input  logic signed [NB-1:0] DII,
    output logic                 RDY, 
    output logic signed [NB+3:0] DOR,
    output logic signed [NB+3:0] DOI
);

    localparam bit USE_FFT16  = (N == 16);
    localparam bit USE_RADIX4 = (N == 64);
    localparam int FFT16_POINTS  = 16;
    localparam int RADIX4_POINTS = 64;
    localparam int RADIX4_SPAN   = 16;


    generate
        if (USE_FFT16) begin : gen_direct_fft16
            FFT16 #(.nb(NB)) fft16_i (
                .CLK(CLK),
                .RST(RST),
                .ED(ED),
                .START(START),
                .DIR(DIR),
                .DII(DII),
                .RDY(RDY),
                .DOR(DOR),
                .DOI(DOI)
            );
        end else begin : gen_radix4_fft16
            typedef enum logic [3:0] {
                IDLE,
                LOAD_INPUT,
                START_FFT16,
                FEED_FFT16,
                WAIT_FFT16,
                CAPTURE_FFT16,
                NEXT_LANE,
                START_MERGE,
                RUN_MERGE,
                RDY_PULSE,
                STREAM_OUTPUT
            } state_t;

            state_t state;
            logic [5:0] input_cnt;
            logic [3:0] sample_cnt;
            logic [1:0] lane_idx;
            logic [5:0] out_cnt;

            logic signed [NB-1:0] frame_re [0:RADIX4_POINTS-1];
            logic signed [NB-1:0] frame_im [0:RADIX4_POINTS-1];

            logic                 fft16_start;
            logic                 fft16_rdy;
            logic signed [NB-1:0] fft16_dr;
            logic signed [NB-1:0] fft16_di;
            logic signed [NB+3:0] fft16_or;
            logic signed [NB+3:0] fft16_oi;
            logic signed [NB-1:0] fft16_res_re;
            logic signed [NB-1:0] fft16_res_im;

            logic signed [NB-1:0] r4_in0_re [0:RADIX4_SPAN-1];
            logic signed [NB-1:0] r4_in0_im [0:RADIX4_SPAN-1];
            logic signed [NB-1:0] r4_in1_re [0:RADIX4_SPAN-1];
            logic signed [NB-1:0] r4_in1_im [0:RADIX4_SPAN-1];
            logic signed [NB-1:0] r4_in2_re [0:RADIX4_SPAN-1];
            logic signed [NB-1:0] r4_in2_im [0:RADIX4_SPAN-1];
            logic signed [NB-1:0] r4_in3_re [0:RADIX4_SPAN-1];
            logic signed [NB-1:0] r4_in3_im [0:RADIX4_SPAN-1];
            logic signed [NB-1:0] r4_out_re [0:RADIX4_POINTS-1];
            logic signed [NB-1:0] r4_out_im [0:RADIX4_POINTS-1];
            logic                 r4_start;
            logic                 r4_valid;
            logic                 r4_busy;

            assign fft16_res_re = fft16_or[NB+3:4];
            assign fft16_res_im = fft16_oi[NB+3:4];

            FFT16 #(.nb(NB)) fft16_i (
                .CLK(CLK),
                .RST(RST),
                .ED(ED),
                .START(fft16_start),
                .DIR(fft16_dr),
                .DII(fft16_di),
                .RDY(fft16_rdy),
                .DOR(fft16_or),
                .DOI(fft16_oi)
            );

            radix4_merge_stage #(
                .NB(NB),
                .TW(TW),
                .N(RADIX4_POINTS),
                .SPAN(RADIX4_SPAN)
            ) radix4_i (
                .clk(CLK),
                .rst(RST),
                .start(r4_start),
                .in0_re(r4_in0_re),
                .in0_im(r4_in0_im),
                .in1_re(r4_in1_re),
                .in1_im(r4_in1_im),
                .in2_re(r4_in2_re),
                .in2_im(r4_in2_im),
                .in3_re(r4_in3_re),
                .in3_im(r4_in3_im),
                .out_valid(r4_valid),
                .busy(r4_busy),
                .out_re(r4_out_re),
                .out_im(r4_out_im)
            );

            always_ff @(posedge CLK) begin
                if (RST) begin
                    state       <= IDLE;
                    input_cnt   <= '0;
                    sample_cnt  <= '0;
                    lane_idx    <= '0;
                    out_cnt     <= '0;
                    fft16_start <= 1'b0;
                    r4_start    <= 1'b0;
                    fft16_dr    <= '0;
                    fft16_di    <= '0;
                    DOR         <= '0;
                    DOI         <= '0;
                    RDY         <= 1'b0;
                end else begin
                    fft16_start <= 1'b0;
                    r4_start    <= 1'b0;
                    RDY         <= 1'b0;

                    if (ED) begin
                        case (state)
                            IDLE: begin
                                if (START) begin
                                    input_cnt <= '0;
                                    state     <= LOAD_INPUT;
                                end
                            end

                            LOAD_INPUT: begin
                                frame_re[input_cnt] <= DIR;
                                frame_im[input_cnt] <= DII;
                                input_cnt           <= input_cnt + 1'b1;

                                if (input_cnt == RADIX4_POINTS - 1) begin
                                    lane_idx   <= '0;
                                    sample_cnt <= '0;
                                    state      <= START_FFT16;
                                end
                            end

                            START_FFT16: begin
                                sample_cnt  <= '0;
                                fft16_start <= 1'b1;
                                state       <= FEED_FFT16;
                            end

                            FEED_FFT16: begin
                                fft16_dr <= frame_re[(4 * sample_cnt) + lane_idx];
                                fft16_di <= frame_im[(4 * sample_cnt) + lane_idx];
                                sample_cnt <= sample_cnt + 1'b1;

                                if (sample_cnt == FFT16_POINTS - 1) begin
                                    sample_cnt <= '0;
                                    state      <= WAIT_FFT16;
                                end
                            end

                            WAIT_FFT16: begin
                                if (fft16_rdy) begin
                                    sample_cnt <= '0;
                                    state      <= CAPTURE_FFT16;
                                end
                            end

                            CAPTURE_FFT16: begin
                                case (lane_idx)
                                    2'd0: begin
                                        r4_in0_re[sample_cnt] <= fft16_res_re;
                                        r4_in0_im[sample_cnt] <= fft16_res_im;
                                    end
                                    2'd1: begin
                                        r4_in1_re[sample_cnt] <= fft16_res_re;
                                        r4_in1_im[sample_cnt] <= fft16_res_im;
                                    end
                                    2'd2: begin
                                        r4_in2_re[sample_cnt] <= fft16_res_re;
                                        r4_in2_im[sample_cnt] <= fft16_res_im;
                                    end
                                    default: begin
                                        r4_in3_re[sample_cnt] <= fft16_res_re;
                                        r4_in3_im[sample_cnt] <= fft16_res_im;
                                    end
                                endcase

                                sample_cnt <= sample_cnt + 1'b1;
                                if (sample_cnt == FFT16_POINTS - 1) begin
                                    sample_cnt <= '0;
                                    state      <= NEXT_LANE;
                                end
                            end

                            NEXT_LANE: begin
                                if (lane_idx == 2'd3) begin
                                    state <= START_MERGE;
                                end else begin
                                    lane_idx <= lane_idx + 1'b1;
                                    state    <= START_FFT16;
                                end
                            end

                            START_MERGE: begin
                                r4_start <= 1'b1;
                                state    <= RUN_MERGE;
                            end

                            RUN_MERGE: begin
                                if (r4_valid) begin
                                    out_cnt <= '0;
                                    state   <= RDY_PULSE;
                                end
                            end

                            RDY_PULSE: begin
                                RDY <= 1'b1;
                                out_cnt <= '0;
                                state <= STREAM_OUTPUT;
                            end

                            STREAM_OUTPUT: begin
                                DOR <= {r4_out_re[out_cnt], 4'b0000};
                                DOI <= {r4_out_im[out_cnt], 4'b0000};
                                out_cnt <= out_cnt + 1'b1;

                                if (out_cnt == RADIX4_POINTS - 1) begin
                                    state <= IDLE;
                                end
                            end
                        endcase
                    end
                end
            end
        end
    endgenerate

endmodule
