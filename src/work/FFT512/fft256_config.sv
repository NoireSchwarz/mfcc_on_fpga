// SystemVerilog generated from Verilog

	
`timescale 10 ps / 1ps

//input data bit width
`define FFT256paramnb parameter nb =16;

//twiddle factor bit width
`define FFT256paramnw parameter nw =10;

//when is absent then FFT, when is present then IFFT 
//`define FFT256paramifft ;	

//buffer number 2 or 3
`define FFT256parambuffers3	

// buffer type: 1 ports in RAMS else -2 ports RAMS
//`define FFT256bufferports1

//Coeficient  bit width is increased  to high
//`define FFT256bitwidth_coef_high


//Rounding butterfly results
//`define FFT256round 	