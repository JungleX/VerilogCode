`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
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
    reg clk, rst, ena;
    reg [`IMG_DATA_WIDTH * 2 - 1:0] inData;
    reg [`IMG_DATA_WIDTH - 1:0] inBias;
    wire [`IMG_DATA_WIDTH - 1:0] out;
    
    accumulator a(
        .ena(ena),
        .clk(clk),
        .rst(rst),
        .inData(inData),
        .inBias(inBias),
        .out(out)
    );
    
    initial 
    begin
        clk = 1'b1;
        repeat (20) clk = #5 ~clk;
    end
    
    initial
    begin
        #0
        ena = 1'b1;
        rst = 1'b1;
        
        #10
        rst = 1'b0;
        inData = 16'b11;
        inBias = 8'b10;
        
        #10
        inData = 16'b111;
        inBias = 8'b101;
    end
    
endmodule
