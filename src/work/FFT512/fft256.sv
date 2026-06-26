//FPGA/MATLAB/simulink���湤����
//΢�Ź��ںţ�matworld
`timescale 1 ns / 1 ps
module fft256( 
              CLK,
				  RST,
				  ED,
				  START,
				  SHIFT,
				  DR,
				  DI,
				  RDY,
				  OVF1,
				  OVF2,
				  ADDR,
				  O_fft_real,
				  O_fft_imag
				  );
				  
	parameter nb =16;	  	 		//nb is the data bit width

	input CLK ;        			//Clock signal is less than 300 MHz for the Xilinx Virtex5 FPGA        
	input RST ;				//Reset signal, is the synchronous one with respect to CLK
	input ED ;					//=1 enables the operation (eneabling CLK)
	input START ;  			// its falling edge starts the transform or the serie of transforms  
	input [3:0] SHIFT ;		// bits 1,0 -shift left code in the 1-st stage
	input [nb-1:0] DR ;		// Real part of the input data,  0-th data goes just after 
	input [nb-1:0] DI ;		//Imaginary part of the input data
	
	
	output RDY ;   			// in the next cycle after RDY=1 the 0-th result is present 
	output OVF1 ;			// 1 signals that an overflow occured in the 1-st stage 
	output OVF2 ;			// 1 signals that an overflow occured in the 2-nd stage 
	output [7:0] ADDR ;	//result data address/number
	
	output[nb-1:0]O_fft_real;	//Real part of the output data (16-bit truncated), the 0-th result is present in the cycle after RDY=1
	output[nb-1:0]O_fft_imag;	//Imaginary part of the output data (16-bit truncated)
	
	logic RDY ;
	logic OVF1 ;
	logic OVF2 ;
	logic [7:0] ADDR ;
	logic [nb+3:0] DOR ;//Real part of the output data, the bit width can be decreased when instantiating the core
	logic [nb+3:0] DOI ;//Imaginary part of the output data
	logic [nb-1:0] O_fft_real;
	logic [nb-1:0] O_fft_imag;
	
	logic [3:0] SHIFT ;	   	// bits 3,2 -shift left code in the 2-nd stage
	logic [nb-1:0] DR ;	    // the START signal or after 255-th data of the previous transform
	logic [nb-1:0] DI ;
	logic START ;			 	// and resets the overflow detectors
	logic ED ;
	logic RST ;
	logic CLK ;
	
	
	logic [nb-1:0] dr1,di1;
	logic [nb+1:0] dr3,di3,dr4,di4, dr5,di5 ;
	logic [nb+3:0] dr2,di2;
	logic [nb+5:0] dr6,di6; 	
	logic [nb+3:0] dr7,di7,dr8,di8;   
	logic rdy1,rdy2,rdy3,rdy4,rdy5,rdy6,rdy7,rdy8;			 
	logic [7:0] addri ;
												    // input buffer =8-bit inversion ordering
	BUFRAM256C #(nb) U_BUF1(.CLK(CLK), .RST(RST), .ED(ED),	.START(START),
	.DR(DR),	.DI(DI),			.RDY(rdy1),	.DOR(dr1), .DOI(di1));	   
	
	//1-st stage of FFT
	FFT16 #(nb) U_FFT1(.CLK(CLK), .RST(RST), .ED(ED),
		.START(rdy1),.DIR(dr1),.DII(di1),
		.RDY(rdy2),	.DOR(dr2),.	DOI(di2));	
	
	logic [1:0] shiftl=	 SHIFT[1:0]; 
	CNORM #(nb) U_NORM1( .CLK(CLK),	.ED(ED),  //1-st normalization unit
		.START(rdy2),	// overflow detector reset
		.DR(dr2),	.DI(di2),
		.SHIFT(shiftl), //shift left bit number
		.OVF(OVF1),
		.RDY(rdy3),
		.DOR(dr3),.DOI(di3));	
		
	// rotator to the angles proportional to PI/32
	ROTATOR64 #(nb+2) U_MPU (.CLK(CLK),.RST(RST),.ED(ED),
		.START(rdy3),. DR(dr3),.DI(di3),
		.RDY(rdy4), .DOR(dr4),	.DOI(di4));
	
	BUFRAM256C #(nb+2) U_BUF2(.CLK(CLK),.RST(RST),.ED(ED),	// intermediate buffer =8-bit inversion ordering
		.START(rdy4),. DR(dr4),.DI(di4),
		.RDY(rdy5), .DOR(dr5),	.DOI(di5));	 
	
	//2-nd stage of FFT
	FFT16 #(nb+2) U_FFT2(.CLK(CLK), .RST(RST), .ED(ED),
		.START(rdy5),. DIR(dr5),.DII(di5),
		.RDY(rdy6), .DOR(dr6),	.DOI(di6));
	
	logic [1:0] shifth=	 SHIFT[3:2]; 
	//2-nd normalization unit
	CNORM #(nb+2) U_NORM2 ( .CLK(CLK),	.ED(ED),
		.START(rdy6),	// overflow detector reset
		.DR(dr6),	.DI(di6),
		.SHIFT(shifth), //shift left bit number
		.OVF(OVF2),
		.RDY(rdy7),
		.DOR(dr7),	.DOI(di7));


		BUFRAM256C  #(nb+4) 	Ubuf3(.CLK(CLK),.RST(RST),.ED(ED),	// intermediate buffer =8-bit inversion ordering
		.START(rdy7),. DR(dr7),.DI(di7),
		.RDY(rdy8), .DOR(dr8),	.DOI(di8));	 	

	

	
//	`ifdef FFT256parambuffers3  	 	// 3-data buffer configuratiion 		   
	always_ff @ (posedge CLK)	begin	//POINTER to the result samples
			if (RST)
				addri<=8'b0000_0000;
			else if (rdy8==1 )  
				addri<=8'b0000_0000;
			else if (ED)
				addri<=addri+1; 
		end
	
		assign ADDR=  addri ;
	assign	DOR=dr8;
	assign	DOI=di8;
	assign	RDY=rdy8;	

 //Output - truncate to 16 bits (take upper bits [19:4])
assign O_fft_real = DOR[nb+3:4];
assign O_fft_imag = DOI[nb+3:4];
endmodule
