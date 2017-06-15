`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/06/12 21:27:30
// Design Name: 
// Module Name: pcie_controller_tb
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

`define clk_period 10

module pcie_controller_tb();
	reg clk;
	reg pcieConRst;

	reg [31:0] sigIn;

	wire [31:0] sigOut_1;
	wire [31:0] sigOut_2;
	wire [31:0] sigOut_3;

	reg [9:0] runlayer;

	wire writeInitDone;

	reg writeFM;
	reg [15:0] writeFMData;
	reg [32:0] writeFMAddr;
	wire writeFMDone;

	reg updateKernel;
	reg updateKernelNumber;
	wire updateKernelDone;

	pcie_controller pc(
		.pcieConClk(clk),
		.pcieConRst(pcieConRst),

		// pcie 
		.sigIn(sigIn),     

		.sigOut_1(sigOut_1),  
		.sigOut_2(sigOut_2), 
		.sigOut_3(sigOut_3), 

		// cnn
		.runlayer(runlayer),

		.writeInitDone(writeInitDone),

		.writeFM(writeFM),
		.writeFMData(writeFMData),
		.writeFMAddr(writeFMAddr),
		.writeFMDone(writeFMDone),

		.updateKernel(updateKernel),
		.updateKernelNumber(updateKernelNumber),
		.updateKernelDone(updateKernelDone)
    );

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0
    	pcieConRst = 1;

    	#(`clk_period/2)
    	pcieConRst = 0; // reset

    	#`clk_period
    	pcieConRst = 1;
    	sigIn = 32'h0;

    	#`clk_period
    	sigIn = 32'h1; // idle write done

    	#`clk_period
    	sigIn = 32'h3; // idle write done, write FM done

    	#`clk_period
    	sigIn = 32'h7; // idle write done, write FM done, update kernel done

    	#`clk_period
    	sigIn = 32'h6; // write FM done, update kernel done

    	#`clk_period
    	runlayer = 10'b0; // IDLE

    	#`clk_period
    	writeFM = 1;
    	writeFMData = 16'h3c00;
    	writeFMAddr = 32'h0;

    	updateKernel = 1;
    	updateKernelNumber = 0;

    	#`clk_period
    	writeFM = 0;

    	updateKernel = 1;
    	updateKernelNumber = 1;

    	#`clk_period
    	writeFM = 0;

    	updateKernel = 0;

    end

endmodule
