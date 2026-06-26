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
input ED ; //operation enable
input [nb-1:0]  DI;  //Imaginary part of data
input [nb-1:0]  DR ; //Real part of data
input START ;		   //1-st Data is entered after this impulse 
	
	
output [nb-1:0]  DOI ; //Imaginary part of data
output [nb-1:0]  DOR ; //Real part of data
output RDY ;	   //repeats START impulse following the output data
		 
	
logic RST ;
logic CLK ;
	
logic [nb-1:0]  DI ;
logic [nb-1:0]  DR ;
logic START ;	
logic [nb-1:0]  DOI ;	
logic [nb-1:0]  DOR ;	
logic RDY ;		
	
	
	logic [7:0] addrw;
	logic sd1,sd2;
	always_ff @ (posedge CLK)	  //address counter for twiddle factors
		begin
			if (RST) begin
					addrw<=0;
					sd1<=0;
					sd2<=0;
				end
			else if (START && ED)  begin
					addrw[7:0]<=0;
					sd1<=START;
					sd2<=0;		 
				end
			else if (ED) 	  begin
					addrw<=addrw+1; 
					sd1<=START;
					sd2<=sd1;
					RDY<=sd2;	 
				end
		end			  

	logic signed [nw-1:0] wr,wi; //twiddle factor coefficients
	//twiddle factor ROM
	WROM256 UROM( .ADDR(addrw),	.WR(wr),.WI(wi) );	
		
		
	logic signed [nb-1 : 0] drd,did;
	logic signed [nw-1 : 0] wrd,wid;
	logic signed [nw+nb-1 : 0] drri,drii,diri,diii;
	logic signed [nb:0] drr,dri,dir,dii,dwr,dwi;
	
	assign  drri=drd*wrd;  
	assign	diri=did*wrd;  
	assign	drii=drd*wid;
	assign	diii=did*wid;  
	
	always_ff @ (posedge CLK)	 //complex multiplier	 
		begin
			if (ED) begin	
					drd<=DR;
					did<=DI;
					wrd<=wr;
					wid<=wi;
					drr<=drri[nw+nb-1 :nw-1]; //msbs of multiplications are stored
					dri<=drii[nw+nb-1 : nw-1];
					dir<=diri[nw+nb-1 : nw-1];
					dii<=diii[nw+nb-1 : nw-1];
					dwr<=drr - dii;				
					dwi<=dri + dir;  
				end	 
		end 		
	assign DOR=dwr[nb:1];       
	assign DOI=dwi[nb:1];
	
endmodule
