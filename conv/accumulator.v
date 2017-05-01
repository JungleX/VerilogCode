`timescale 1ns / 1ps
`include "bit_width.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/04/20 21:07:59
// Design Name: 
// Module Name: accumulator
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

module accumulator(
    input clk,  
    input rst,  
    input ena,
    
    input [`IMG_DATA_WIDTH * 2 - 1:0] inData,
    input [`IMG_DATA_WIDTH - 1:0] inBias,
    
    output [`IMG_DATA_WIDTH - 1:0] out
    );
    
    reg [`IMG_DATA_WIDTH * 2 - 1:0] data;
    reg [`IMG_DATA_WIDTH - 1:0] bias;
    wire [`IMG_DATA_WIDTH - 1:0] fout_8;
   
    adder_signed_8 adder(.CLK(clk), .A(data[`IMG_DATA_WIDTH - 1:0]),  .B(bias),  .S(fout_8));

    assign out = fout_8;
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            data <= `IMG_DATA_WIDTH * 2'b0;
            bias <= `IMG_DATA_WIDTH'b0;
            //fout_8 <= `IMG_DATA_WIDTH'b0;
        end
    end
    
    always @(negedge clk) begin
        if(ena) begin
            // clk1
            data <= inData;
            bias <= inBias;
            // clk2 
            // fout_8 
        end
    end        
    
endmodule
