`timescale 1ns / 1ps

module padding(
	input inReady,

	input [10:0] x, // 0 <= x < fmX
	input [10:0] y, // 0 <= y < fmY

	input [63:0] baseAddr,

	input [10:0] fmX,
	input [10:0] fmY,

	input [3:0] paddingUp,
	input [3:0] paddingDown,
	input [3:0] paddingLeft,
	input [3:0] paddingRight,

	output reg [63:0] realAddr,
	output reg [1:0] realAddrEn, // 0: false value; 1: false realAddr, padding location; 2: true realAddr, feature map location
	output reg outReady
    );

	always @(*) begin
		if (inReady) begin
			outReady = 0;
			realAddrEn = 0;

			if (x <= paddingUp) begin
				realAddrEn = 1;
			end
			else if((x >= (fmX + paddingUp)) 
				 && (x <  (fmX + paddingUp + paddingDown))) begin
				realAddrEn = 1;
			end
			else if (y <= paddingLeft) begin
				realAddrEn = 1;
			end
			else if((y >= (fmY + paddingLeft)) 
				 && (y <  (fmY + paddingLeft + paddingRight))) begin
				realAddrEn = 1;
			end
			else begin
				realAddrEn = 2;
				realAddr = baseAddr + x + y * fmX;
			end

			outReady = 1;
		end
	end
endmodule
