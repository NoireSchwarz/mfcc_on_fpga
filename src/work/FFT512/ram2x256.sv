// DESCRIPTION	:	2-port RAM

`timescale 1 ns / 1 ps
  

module RAM2x256C( 
                 CLK,
					  ED,
					  WE,
					  ODD,
					  ADDRW,
					  ADDRR,
					  DR,
					  DI,
					  DOR,
					  DOI);
					  
	parameter nb =16;	
	
	
	output [nb-1:0] DOR ;
	logic [nb-1:0] DOR ;
	output [nb-1:0] DOI ;
	logic [nb-1:0] DOI ;
	input CLK ;
	logic CLK ;
	input ED ;
	logic ED ;
	input WE ;	     //write enable
	logic WE ;
	input ODD ;	  // RAM part switshing
	logic ODD ;
	input [7:0] ADDRW ;
	logic [7:0] ADDRW ;
	input [7:0] ADDRR ;
	logic [7:0] ADDRR ;
	input [nb-1:0] DR ;
	logic [nb-1:0] DR ;
	input [nb-1:0] DI ;
	logic [nb-1:0] DI ;	
	
	logic oddd,odd2;
	always_ff @ (posedge CLK) begin //switch which reswiches the RAM parts
			if (ED)	begin
					oddd<=ODD;
					odd2<=oddd;
				end
		end 
	`ifdef 	FFT256bufferports1
	//One-port RAMs are used
	logic we0,we1;
	logic [nb-1:0] dor0,dor1,doi0,doi1;
	logic [7:0] addr0,addr1;		   
	
	
	
	assign	addr0 =ODD?  ADDRW: ADDRR;		//MUXA0
	assign	addr1 = ~ODD? ADDRW:ADDRR;	// MUXA1
	assign	we0   =ODD?  WE: 0;		     // MUXW0: 
	assign	we1   =~ODD? WE: 0;			 // MUXW1:
	
	//1-st half - write when odd=1	 read when odd=0
	RAM256 #(nb) URAM0(.CLK(CLK),.ED(ED),.WE(we0), .ADDR(addr0),.DI(DR),.DO(dor0)); // 
	RAM256 #(nb) URAM1(.CLK(CLK),.ED(ED),.WE(we0), .ADDR(addr0),.DI(DI),.DO(doi0));	 
	
	//2-d half
	RAM256 #(nb) URAM2(.CLK(CLK),.ED(ED),.WE(we1), .ADDR(addr1),.DI(DR),.DO(dor1));//	  
	RAM256 #(nb) URAM3(.CLK(CLK),.ED(ED),.WE(we1), .ADDR(addr1),.DI(DI),.DO(doi1));		
	
	assign	DOR=~odd2? dor0 : dor1;		 // MUXDR: 
	assign	DOI=~odd2? doi0 : doi1;	//  MUXDI:
	
	`else 		
	//Two-port RAM is used
	logic [8:0] addrr2;
	logic [8:0] addrw2;
	logic [2*nb-1:0] di;
	assign addrr2 = {ODD,ADDRR};
	assign addrw2 = {~ODD,ADDRW};
	assign di = {DR,DI};

	//logic [2*nb-1:0] doi;	
	logic [2*nb-1:0] doi;	
	
	(* ram_style = "block", ramstyle = "M10K" *) logic [2*nb-1:0] ram [511:0];
	logic [8:0] read_addra;
	always_ff @ (posedge CLK) begin
			if (ED)
				begin
					if (WE)
						ram[addrw2] <= di;
					read_addra <= addrr2;	
				   doi <= ram[read_addra];			
				end
		end
	//assign 	 
	
	assign	DOR=doi[2*nb-1:nb];		 // Real read data 
	assign	DOI=doi[nb-1:0];		 // Imaginary read data
	
	
	`endif 	
endmodule
