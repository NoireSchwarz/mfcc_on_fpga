`timescale 1ns/1ps
// Registered Mel products/accumulation and a tagged logarithm pipeline.
module filter_bank (clk,reset,in,out,s_valid,s_ready,m_valid,m_ready);
    parameter signed [31:0] N=256;
    parameter signed [31:0] NFILT=64;
    parameter signed [31:0] FLOOR_LOG2=-16;
    parameter COEFF_FILE="mel_sparse_q15.mem";
    parameter LOG_FILE="log20_mantissa_q20.mem";
    input wire clk,reset;
    input wire [31:0] in;
    output reg [(NFILT*16)-1:0] out;
    input wire s_valid,m_ready;
    output wire s_ready,m_valid;
    localparam signed [31:0] ROW_IDX=clog2(N)-3;
    localparam signed [31:0] ENERGY_FRAC_BITS=45-clog2(2*N);
    localparam [63:0] ENERGY_FLOOR=64'd1 << (ENERGY_FRAC_BITS+FLOOR_LOG2);
    localparam [1:0] COLLECT=0,DRAIN=1,CONVERT=2,HOLD=3;
    reg [1:0] state;
    reg [clog2(N)-1:0] bin_index;
    reg [6:0] log_index;
    reg [45:0] coeff_rom [0:8191];
    reg [23:0] log_rom [0:1023];
    reg [63:0] energy [0:NFILT-1];
    wire [45:0] entry=coeff_rom[(ROW_IDX*1024)+bin_index];
    wire [6:0] band_a=entry[45:39],band_b=entry[22:16];
    wire [15:0] weight_a=entry[38:23],weight_b=entry[15:0];
    wire input_fire=s_valid && s_ready;
    reg [31:0] power_bin_q;
    reg [15:0] weight_a_q,weight_b_q;
    reg [6:0] input_band_a_q,input_band_b_q;
    reg input_valid_q,input_last_q;
    reg [47:0] product_a_q,product_b_q;
    reg [6:0] band_a_q,band_b_q;
    reg product_valid,product_last;

    // L0: indexed energy read and floor clamp.
    reg [63:0] log_energy_q;
    reg [63:0] clamped_energy;
    // L1: leading-one position, with the energy delayed alongside it.
    reg [63:0] exponent_energy_q;
    reg [5:0] exponent_q;
    integer exponent;
    // L2: normalized mantissa address; retain the associated exponent.
    reg [63:0] normalized_energy;
    reg [9:0] mantissa_address_q;
    reg signed [31:0] exponent_delta_q;
    // L3: register the constant product and the parallel ROM read.
    reg signed [31:0] exponent_product_q;
    reg [23:0] mantissa_q;
    // L4: add the two Q20 terms; L5: bias/shift into the output word.
    reg signed [31:0] log_scaled_q;
    wire signed [31:0] log_rounded=log_scaled_q+32'sd2048;
    wire signed [15:0] log_value=log_rounded >>> 12;
    reg [4:0] log_valid;
    reg [5:0] log_tag [0:4];
    wire log_issue=(state==CONVERT) && (log_index<NFILT);
    integer i,integer_bit;

    initial begin
        if(NFILT!=64) begin
            $display("Fatal: generate a matching ROM before changing NFILT");
            $finish(1);
        end
        if((ENERGY_FRAC_BITS+FLOOR_LOG2)<0 || FLOOR_LOG2 < -21 || FLOOR_LOG2>0) begin
            $display("Fatal: log floor outside representable Q8 energy range");
            $finish(1);
        end
        $readmemh(COEFF_FILE,coeff_rom);
        $readmemh(LOG_FILE,log_rom);
    end
    assign s_ready=(state==COLLECT) && !reset;
    assign m_valid=(state==HOLD);
    always @(*) begin
        clamped_energy=energy[(log_index<NFILT)?log_index:0];
        if(clamped_energy<ENERGY_FLOOR)
            clamped_energy=ENERGY_FLOOR;
        exponent=0;
        for(integer_bit=0;integer_bit<64;integer_bit=integer_bit+1)
            if(log_energy_q[integer_bit]) exponent=integer_bit;
        normalized_energy=exponent_energy_q << (6'd63-exponent_q);
    end
    always @(posedge clk or posedge reset)
        if(reset) begin
            state<=COLLECT;bin_index<=0;log_index<=0;
            product_valid<=0;product_last<=0;
            input_valid_q<=0;input_last_q<=0;
            input_band_a_q<=7'd127;input_band_b_q<=7'd127;
            band_a_q<=7'd127;band_b_q<=7'd127;
            log_valid<=0;
            for(i=0;i<5;i=i+1) log_tag[i]<=0;
            for(i=0;i<NFILT;i=i+1) begin
                energy[i]<=0;
                out[(NFILT-1-i)*16+:16]<=0;
            end
        end else begin
            // M0 isolates ROM selection from multiplication.
            input_valid_q<=input_fire;
            if(input_fire) begin
                power_bin_q<=in;weight_a_q<=weight_a;weight_b_q<=weight_b;
                input_band_a_q<=band_a;input_band_b_q<=band_b;
                input_last_q<=(bin_index==N-1);
            end
            // M1 contains only the two multiplications and tag alignment.
            product_valid<=input_valid_q;
            if(input_valid_q) begin
                product_a_q<=power_bin_q*weight_a_q;
                product_b_q<=power_bin_q*weight_b_q;
                band_a_q<=input_band_a_q;band_b_q<=input_band_b_q;
                product_last<=input_last_q;
            end
            // M2 commits one bin per clock. B retains the original priority
            // if both destination fields select the same energy word.
            if(product_valid) begin
                if(band_a_q<NFILT) energy[band_a_q]<=energy[band_a_q]+product_a_q;
                if(band_b_q<NFILT) energy[band_b_q]<=energy[band_b_q]+product_b_q;
            end
            log_valid<={log_valid[3:0],log_issue};
            if(log_issue) begin
                log_energy_q<=clamped_energy;
                log_tag[0]<=log_index[5:0];
                log_index<=log_index+1'b1;
            end
            if(log_valid[0]) begin
                exponent_energy_q<=log_energy_q;
                exponent_q<=exponent[5:0];
                log_tag[1]<=log_tag[0];
            end
            if(log_valid[1]) begin
                mantissa_address_q<=normalized_energy[62:53];
                exponent_delta_q<=$signed({1'b0,exponent_q})-ENERGY_FRAC_BITS;
                log_tag[2]<=log_tag[1];
            end
            if(log_valid[2]) begin
                exponent_product_q<=exponent_delta_q*32'sd6313057;
                mantissa_q<=log_rom[mantissa_address_q];
                log_tag[3]<=log_tag[2];
            end
            if(log_valid[3]) begin
                log_scaled_q<=exponent_product_q+$signed({1'b0,mantissa_q});
                log_tag[4]<=log_tag[3];
            end
            if(log_valid[4]) begin
                out[(NFILT-1-log_tag[4])*16+:16]<=log_value;
                if(log_tag[4]==NFILT-1) state<=HOLD;
            end
            case(state)
                COLLECT: if(input_fire) begin
                    if(bin_index==N-1) begin
                        bin_index<=0;state<=DRAIN;
                    end else bin_index<=bin_index+1'b1;
                end
                // The last product commits now; L0 reads on the next edge.
                DRAIN: if(product_valid && product_last) begin
                    log_index<=0;state<=CONVERT;
                end
                HOLD: if(m_ready) begin
                    for(i=0;i<NFILT;i=i+1) energy[i]<=0;
                    state<=COLLECT;
                end
                default: begin end
            endcase
        end
    function integer clog2;
        input integer value;
        integer remaining;
        begin
            remaining=value-1;clog2=0;
            while(remaining>0) begin
                clog2=clog2+1;remaining=remaining>>1;
            end
        end
    endfunction
endmodule
