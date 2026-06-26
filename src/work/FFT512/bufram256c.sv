//FPGA/MATLAB/simulink���湤����
//΢�Ź��ںţ�matworld
`timescale 1 ns / 1 ps
  
module BUFRAM256C ( CLK ,RST ,ED ,START ,DR ,DI ,RDY ,DOR ,DOI );
	parameter nb =16;
	output RDY ;
	logic RDY ;
	output [nb-1:0] DOR ;
	logic [nb-1:0] DOR ;
	output [nb-1:0] DOI ;
	logic [nb-1:0] DOI ;
	
	input CLK ;
	logic CLK ;
	input RST ;
	logic RST ;
	input ED ;
	logic ED ;
	input START ;
	logic START ;
	input [nb-1:0] DR ;
	logic [nb-1:0] DR ;
	input [nb-1:0] DI ;
	logic [nb-1:0] DI ;
	
	logic odd, we;
	logic [7:0] addrw,addrr;
	logic [8:0] addr;
	logic [9:0] ct2;		//counter for the RDY signal		 		  
	
	always_ff @ (posedge CLK)	//   CTADDR
		begin
			if (RST) begin
					addr<=8'b0000_0000;
					ct2<= 9'b10000_0001;  
				RDY<=1'b0; end
			else if (START) begin 
					addr<=8'b0000_0000;
					ct2<= 8'b0000_0000;  
				RDY<=1'b0;end
			else if (ED)	begin
				RDY<=1'b0;
					addr<=addr+1; 
					if (ct2!=257) 
					ct2<=ct2+1;
					if (ct2==256) 
					 RDY<=1'b1;
				end 
		end
			
	
assign	addrw=	addr[7:0];
assign	odd=addr[8];	   			// signal which switches the 2 parts of the buffer
assign	addrr={addr[3 : 0], addr[7 : 4]};	  // 16-th inverse output address
assign	we = ED;	  
	
	RAM2x256C #(nb)	URAM(.CLK(CLK),.ED(ED),.WE(we),.ODD(odd),
	.ADDRW(addrw),	.ADDRR(addrr),
	.DR(DR),.DI(DI),
	.DOR(DOR),	.DOI(DOI));	   
	
endmodule
