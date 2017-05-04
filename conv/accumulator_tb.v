`timescale 1ns / 1ps
`include "bit_width.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company:  SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/04/20 21:26:21
// Design Name: 
// Module Name: accumulator_tb
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

module accumulator_tb();
    reg clk;
    //reg [`IMG_DATA_WIDTH_DOUBLE - 1:0] inData;
    reg [`IMG_DATA_WIDTH_DOUBLE - 1:0] inData;
    reg [`IMG_DATA_WIDTH - 1:0] inBias;
    wire [`IMG_DATA_WIDTH - 1:0] fout;
    
    adder madder(.CLK(clk), .A(inData[`IMG_DATA_WIDTH - 1:0]),  .B(inBias),  .S(fout));
    
    initial 
    begin
        clk = 1'b1;
        repeat (20) clk = #5 ~clk;
    end
    
    initial
    begin
        #10
        inData = `IMG_DATA_WIDTH_DOUBLE'd3;
        inBias = `IMG_DATA_WIDTH'd2;
        
        #10
        inData = `IMG_DATA_WIDTH_DOUBLE'd7;
        inBias = `IMG_DATA_WIDTH'd5;
    end
    
endmodule
