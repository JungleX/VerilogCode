`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/25 16:32:58
// Design Name: 
// Module Name: multX11
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

module multX11(
	input clk,
    input rst,
    input ena,
 
    input [`CONV_MAX_LINE_SIZE - 1:0] data,     
    
    input [`CONV_MAX_LINE_SIZE - 1:0] weight,    

    output reg [`DATA_WIDTH - 1:0] out
    );

	reg [`CONV_MAX_LINE_SIZE - 1:0] loadData;
	reg [`CONV_MAX_LINE_SIZE - 1:0] loadWeight;
	reg [`CONV_MAX_LINE_SIZE - 1:0] mulResult;

	wire [`DATA_WIDTH - 1:0] mult[0:`CONV_MAX]; 

	always @(posedge clk or posedge rst) begin
        if(!rst) begin
            //reset registers
            loadData = 0;
            loadWeight = 0;
            mulResult = 0;

            out = 0;
        end
    end

    always @(negedge clk) begin
    //always @(posedge clk) begin
    	if(ena && rst) begin
            // clk1
            // load data matrix and filter data
            loadData   <= data;
            loadWeight <= weight;

           	// clk2
            //  multiplication
            mulResult[`DATA_WIDTH - 1   :0]              <= mult[0];
            mulResult[`DATA_WIDTH*2 - 1 :`DATA_WIDTH]    <= mult[1];
            mulResult[`DATA_WIDTH*3 - 1 :`DATA_WIDTH*2]  <= mult[2];
            mulResult[`DATA_WIDTH*4 - 1 :`DATA_WIDTH*3]  <= mult[3];
            mulResult[`DATA_WIDTH*5 - 1 :`DATA_WIDTH*4]  <= mult[4];
            mulResult[`DATA_WIDTH*6 - 1 :`DATA_WIDTH*5]  <= mult[5];
            mulResult[`DATA_WIDTH*7 - 1 :`DATA_WIDTH*6]  <= mult[6];
            mulResult[`DATA_WIDTH*8 - 1 :`DATA_WIDTH*7]  <= mult[7];
            mulResult[`DATA_WIDTH*9 - 1 :`DATA_WIDTH*8]  <= mult[8];
            mulResult[`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]  <= mult[9];
            mulResult[`DATA_WIDTH*11 - 1:`DATA_WIDTH*10] <= mult[10];

            // clk3
            // addition
            out <= mulResult[`DATA_WIDTH - 1   :0] 
            	 + mulResult[`DATA_WIDTH*2 - 1 :`DATA_WIDTH] 
            	 + mulResult[`DATA_WIDTH*3 - 1 :`DATA_WIDTH*2]
            	 + mulResult[`DATA_WIDTH*4 - 1 :`DATA_WIDTH*3]
            	 + mulResult[`DATA_WIDTH*5 - 1 :`DATA_WIDTH*4]
            	 + mulResult[`DATA_WIDTH*6 - 1 :`DATA_WIDTH*5]
            	 + mulResult[`DATA_WIDTH*7 - 1 :`DATA_WIDTH*6]
            	 + mulResult[`DATA_WIDTH*8 - 1 :`DATA_WIDTH*7]
            	 + mulResult[`DATA_WIDTH*9 - 1 :`DATA_WIDTH*8]
            	 + mulResult[`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]
            	 + mulResult[`DATA_WIDTH*11 - 1:`DATA_WIDTH*10];
        end
    end
endmodule
