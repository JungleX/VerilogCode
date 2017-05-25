`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/25 09:45:18
// Design Name: 
// Module Name: convolution
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

`include "ram_parameters.vh"

module convolution(
	input clk,
	input convRst,

	input [3:0] runLayer,                // which layer to run

	output reg [18:0] layerReadAddr,     // read address of layer RAM
    output reg [9:0] weightReadAddr,     // read address of weight RAM
    output reg biasReadAddr,             // read address of bias RAM

   	output reg convStatus                // conv status, 0:idle or running; 1:done, done means the conv finish and output data is ready
    );

    parameter IDLE  = 4'd0,
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

    reg [3:0] currentLayer;
    reg [18:0] inputStartIndex;
    reg [18:0] outputStartIndex;

    always @(posedge clk or posedge convRst) begin
        if(!convRst) begin // reset
            convStatus = 0;
            inputStartIndex = `LAYER_RAM_START_INDEX_0;
            outputStartIndex = `LAYER_RAM_START_INDEX_1;
            currentLayer = IDLE;
            // todo more 
        end
    end

    always @(posedge clk) begin
    	if(convRst) begin
            case(runLayer)
                IDLE: 
                	begin
                		currentLayer = runLayer;
                	end
                CONV1:
                    begin
                    	if(currentLayer != runLayer) begin
                    		inputStartIndex = `LAYER_RAM_START_INDEX_0;
                            outputStartIndex = `LAYER_RAM_START_INDEX_1;
                    		weightReadAddr = 0;
                    		biasReadAddr = 0;
                            convStatus = 0;
                    	end
                    end
                POOL1:
                    begin
                        currentLayer = runLayer;
                    end 
                CONV2:
                    begin
                      if(currentLayer != runLayer) begin
                        inputStartIndex = `LAYER_RAM_START_INDEX_0;
                        outputStartIndex = `LAYER_RAM_START_INDEX_1;
                        weightReadAddr = 0;
                        biasReadAddr = 0;
                        convStatus = 0;
                      end
                    end
                POOL2:
                    begin
                        currentLayer = runLayer;
                    end
                CONV3:
                    begin
                      if(currentLayer != runLayer) begin
                        inputStartIndex = `LAYER_RAM_START_INDEX_0;
                        outputStartIndex = `LAYER_RAM_START_INDEX_1;
                        weightReadAddr = 0;
                        biasReadAddr = 0;
                        convStatus = 0;
                      end
                    end
                CONV4:
                    begin
                      if(currentLayer != runLayer) begin
                        inputStartIndex = `LAYER_RAM_START_INDEX_1;
                        outputStartIndex = `LAYER_RAM_START_INDEX_0;
                        weightReadAddr = 0;
                        biasReadAddr = 0;
                        convStatus = 0;
                      end
                    end
                CONV5:
                    begin
                      if(currentLayer != runLayer) begin
                        inputStartIndex = `LAYER_RAM_START_INDEX_0;
                        outputStartIndex = `LAYER_RAM_START_INDEX_1;
                        weightReadAddr = 0;
                        biasReadAddr = 0;
                        convStatus = 0;
                      end
                    end
                POOL5:
                    begin
                        currentLayer = runLayer;
                    end
                FC6:
                    begin
                    end 
                FC7:
                    begin
                    end 
                FC8:
                    begin
                    end     
            endcase
        end
    end
    
endmodule
