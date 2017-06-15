`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/06/12 20:05:25
// Design Name: 
// Module Name: pcie_controller
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


module pcie_controller(
	input pcieConClk,
	input pcieConRst,

	// pcie 
	input [31:0] sigIn,         // idle write done sig(1 bit), write FM done sig(1 bit), update kernel done sig(1 bit), undefine(29 bits)

	output reg [31:0] sigOut_1, // 0: init prepare ram data(1 bit), 1: write FM sig(1 bit), 2: updata kernel sig(1 bit), 3: updata kernel number(1 bit for 2 kernel), undefine(28 bits)
	output reg [31:0] sigOut_2, // write FM data(16 bits), undefine(16 bits)
	output reg [31:0] sigOut_3, // write FM address(32 bits)

	// cnn
	input [9:0] runlayer,

	output reg writeInitDone,

	input writeFM,
	input [15:0] writeFMData,
	input [32:0] writeFMAddr,
	output reg writeFMDone,

	input updateKernel,
	input updateKernelNumber,
	output reg updateKernelDone
    );

	parameter   IDLE  = 10'b0;

	always @(posedge pcieConClk or posedge pcieConRst) begin
		if(!pcieConRst) begin // reset
			sigOut_1 <= 32'b0;
			sigOut_2 <= 32'b0;
			sigOut_3 <= 32'b0;

			writeInitDone    <= 0;
			writeFMDone      <= 0;
			updateKernelDone <= 0;
		end
	end

	always @(posedge pcieConClk) begin
		if(pcieConRst) begin 
			if (runlayer == IDLE) begin
				sigOut_1[0:0] <= 1;
			end

			// write fm
			if (writeFM == 1) begin
				sigOut_1[1:1]  <= 1;
				sigOut_2[15:0] <= writeFMData;
				sigOut_3       <= writeFMAddr;
			end
			else if (writeFM == 0) begin
				sigOut_1[1:1]  <= 0;
			end

			// update kernel
			if (updateKernel == 1) begin
				sigOut_1[2:2]  <= 1;
				sigOut_1[3:3]  <= updateKernelNumber;
			end
			else if (updateKernel == 0) begin
				sigOut_1[2:2]  <= 0;
			end

			writeInitDone    <= sigIn[0:0];
			writeFMDone      <= sigIn[1:1];
			updateKernelDone <= sigIn[2:2];
		end
	end

endmodule
