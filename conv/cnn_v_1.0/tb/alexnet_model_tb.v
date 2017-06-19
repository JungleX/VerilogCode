`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/06/15 20:58:46
// Design Name: 
// Module Name: alexnet_model_tb
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

`include "alexnet_parameters.vh"

`define clk_period 10

module alexnet_model_tb();

	reg clk;
	reg modelRst;

	wire [9:0] runLayer;

	wire writeInitDone;

	wire writeFM;
	wire [`DATA_WIDTH - 1:0] writeFMData;
	wire [31:0] writeFMAddr;
	wire writeFMDone;

	wire updateKernel;
	wire updateKernelNumber;
	wire updateKernelDone;
	
	wire FMReadEn;
	wire [`DATA_WIDTH - 1:0] FMReadData;
	wire [31:0] FMReadAddr;

	wire weightReadEn;
	wire [`DATA_WIDTH - 1:0] weightReadData;
	wire [31:0] weightReadAddr;

	wire biasReadEn;
	wire [`DATA_WIDTH - 1:0] biasReadData;
	wire biasReadAddr;

	alexnet_model alexnet(
		.clk(clk),
	 	.modelRst(modelRst),

		.runLayer(runLayer),

		.writeInitDone(writeInitDone),

		.writeFM(writeFM),
		.writeFMData(writeFMData),
		.writeFMAddr(writeFMAddr),
		.writeFMDone(writeFMDone),
	
		.updateKernel(updateKernel),
		.updateKernelNumber(updateKernelNumber),
		.updateKernelDone(updateKernelDone),

		.FMReadEn(FMReadEn),
		.FMReadData(FMReadData),
		.FMReadAddr(FMReadAddr),

		.weightReadEn(weightReadEn),
		.weightReadData(weightReadData),
		.weightReadAddr(weightReadAddr),

		.biasReadEn(biasReadEn),
		.biasReadData(biasReadData),
		.biasReadAddr(biasReadAddr)
    );

	reg pcieConRst;

	wire [31:0] sig;
	wire [31:0] sig_1;
	wire [31:0] sig_2;
	wire [31:0] sig_3;

	pcie_controller pcie_con(
		.pcieConClk(clk),
		.pcieConRst(pcieConRst),

	// pcie 
		.sigIn(sig),        

		.sigOut_1(sig_1),
		.sigOut_2(sig_2), 
		.sigOut_3(sig_3), 

	// cnn
		.runlayer(runLayer),

		.writeInitDone(writeInitDone),

		.writeFM(writeFM),
		.writeFMData(writeFMData),
		.writeFMAddr(writeFMAddr),
		.writeFMDone(writeFMDone),

		.updateKernel(updateKernel),
		.updateKernelNumber(updateKernelNumber),
		.updateKernelDone(updateKernelDone)
    );

	reg fileRst;

	wire FMWea;
	wire FMWriteEn;
	wire [15:0] FMWriteData;
	wire [18:0] FMWriteAddr;

	wire weightWea;
	wire weightWriteEn;
	wire [15:0] weightWriteData;
	wire [12:0] weightWriteAddr;

	wire biasWea;
	wire biasWriteEn;
	wire [15:0] biasWriteData;
	wire biasWriteAddr ;
	
	file_data_controller file_con(
		.clk(clk),
		.rst(fileRst),

		.sig_1(sig_1), 
		.sig_2(sig_2), 
		.sig_3(sig_3),

		.sig(sig),

		.FMWea(FMWea),
		.FMWriteEn(FMWriteEn),
    	.FMWriteData(FMWriteData),      
    	.FMWriteAddr(FMWriteAddr),       
    
    	.weightWea(weightWea),
    	.weightWriteEn(weightWriteEn),
    	.weightWriteData(weightWriteData), 
    	.weightWriteAddr(weightWriteAddr),
    	
    	.biasWea(biasWea),
    	.biasWriteEn(biasWriteEn),
    	.biasWriteData(biasWriteData),     
    	.biasWriteAddr(biasWriteAddr)
    );

    layer_ram layerRam(
        .addra(FMWriteAddr[18:0]),
        .clka(clk),
        .dina(FMWriteData),
        .ena(FMWriteEn),
        .wea(FMWea),
        
        .addrb(FMReadAddr[18:0]),
        .clkb(clk),
        .doutb(FMReadData),
        .enb(FMReadEn)
    );

    weight_ram weightRam(
        .addra(weightWriteAddr[12:0]),
        .clka(clk),
        .dina(weightWriteData),
        .ena(weightWriteEn),
        .wea(weightWea),
        
        .addrb(weightReadAddr[12:0]),
        .clkb(clk),
        .doutb(weightReadData),
        .enb(weightReadEn)   
    );
    
    bias_ram biasRam(
        .addra(biasWriteAddr),
        .clka(clk),
        .dina(biasWriteData),
        .ena(biasWriteEn),
        .wea(biasWea),
        
        .addrb(biasReadAddr),
        .clkb(clk),
        .doutb(biasReadData),
        .enb(biasReadEn)    
    );

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0 // reset
    	modelRst   = 0;
    	pcieConRst = 0;
    	fileRst    = 0;

    	#`clk_period
    	modelRst   = 1;
    	pcieConRst = 1;
    	fileRst    = 1;


    end

endmodule
