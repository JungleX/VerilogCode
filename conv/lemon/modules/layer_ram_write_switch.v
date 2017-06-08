`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/06/08 15:05:06
// Design Name: 
// Module Name: layer_ram_write_switch
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

module layer_ram_write_switch(
	input [3:0] runLayer, 

	// pcie, write at IDLE
	input [`DATA_WIDTH - 1:0] writeLayerData,
	input [18:0] writeLayerAddr,

	// conv, pool and fc, write at CONV, POOL, FC
	input [`DATA_WIDTH - 1:0] writeOutputLayerData,
	input [18:0] writeOutputLayerAddr,

	output [`DATA_WIDTH - 1:0] writeLayerRAMData,
	output [18:0] writeLayerRAMAddr
    );

	parameter   IDLE  = 4'd0,
                CONV1 = 4'd1,       
                POOL1 = 4'd2,
                CONV2 = 4'd3,       
                POOL2 = 4'd4,
                CONV3 = 4'd5,      
                CONV4 = 4'd6,  
                CONV5 = 4'd7,
                POOL5 = 4'd8,
                FC6   = 4'd9,
                FC7   = 4'd10,
                FC8   = 4'd11;

    assign writeLayerRAMData = runLayer == IDLE ? writeLayerData : writeOutputLayerData;
    assign writeLayerRAMAddr = runLayer == IDLE ? writeLayerAddr : writeOutputLayerAddr;

//    always begin
//    	if (runLayer == IDLE) begin
//    		writeLayerRAMData = writeLayerData;
//    		writeLayerRAMAddr = writeLayerAddr;
//    	end
//    	else begin
//    		writeLayerRAMData = writeOutputLayerData;
//    		writeLayerRAMAddr = writeOutputLayerAddr;
//    	end
//    end
	
endmodule
