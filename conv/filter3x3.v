`timescale 1ns/1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/04/13 18:00:43
// Design Name: 
// Module Name: filter3x3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:    
// 计算过程分为3个clk的流水
// 输入数据后第三个clk下降沿输出计算结果
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "bit_width.vh"

module filter3x3(
    input clk,
    input rst,
    input ena,
 
    //data matrix
    input [`IMG_DATA_MATRIX_WIDTH - 1:0] inMatrix,
    //filter matrix
    input [`IMG_DATA_MATRIX_WIDTH - 1:0] filterMatrix,

    output [`IMG_DATA_WIDTH * 2 - 1:0] out
    );
  
    reg [`IMG_DATA_WIDTH * 2 - 1:0] fout;

    reg [`IMG_DATA_LINE_WIDTH - 1:0] DataLine1;
    reg [`IMG_DATA_LINE_WIDTH - 1:0] DataLine2;
    reg [`IMG_DATA_LINE_WIDTH - 1:0] DataLine3;
  
    reg  [`IMG_DATA_LINE_WIDTH - 1:0] fLine1;
    reg  [`IMG_DATA_LINE_WIDTH - 1:0] fLine2;
    reg  [`IMG_DATA_LINE_WIDTH - 1:0] fLine3;
  
    reg [`IMG_DATA_LINE_WIDTH - 1:0] mulLine1;
    reg [`IMG_DATA_LINE_WIDTH - 1:0] mulLine2;
    reg [`IMG_DATA_LINE_WIDTH - 1:0] mulLine3;
  
    wire [`IMG_DATA_LINE_WIDTH - 1:0] mult_1;  
    wire [`IMG_DATA_LINE_WIDTH - 1:0] mult_2;
    wire [`IMG_DATA_LINE_WIDTH - 1:0] mult_3;
  
    // 8 bits, signed integer
    mult_gen_signed_8 mult11(.CLK(clk), .A(DataLine1[`IMG_DATA_WIDTH - 1:0]),   .B(fLine1[`IMG_DATA_WIDTH - 1:0]),   .P(mult_1[`IMG_DATA_WIDTH - 1:0]));
    mult_gen_signed_8 mult12(.CLK(clk), .A(DataLine1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),  .B(fLine1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),  .P(mult_1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]));
    mult_gen_signed_8 mult13(.CLK(clk), .A(DataLine1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]), .B(fLine1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]), .P(mult_1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]));
  
    mult_gen_signed_8 mult21(.CLK(clk), .A(DataLine2[`IMG_DATA_WIDTH - 1:0]),   .B(fLine2[`IMG_DATA_WIDTH - 1:0]),   .P(mult_2[`IMG_DATA_WIDTH - 1:0]));
    mult_gen_signed_8 mult22(.CLK(clk), .A(DataLine2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),  .B(fLine2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),  .P(mult_2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]));                                                                                          
    mult_gen_signed_8 mult23(.CLK(clk), .A(DataLine2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]), .B(fLine2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]), .P(mult_2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]));
  
    mult_gen_signed_8 mult31(.CLK(clk), .A(DataLine3[`IMG_DATA_WIDTH - 1:0]),   .B(fLine3[`IMG_DATA_WIDTH - 1:0]),   .P(mult_3[`IMG_DATA_WIDTH - 1:0]));
    mult_gen_signed_8 mult32(.CLK(clk), .A(DataLine3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),  .B(fLine3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),  .P(mult_3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]));
    mult_gen_signed_8 mult33(.CLK(clk), .A(DataLine3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]), .B(fLine3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]), .P(mult_3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]));
 
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            //reset registers
            DataLine1 <= `IMG_DATA_LINE_WIDTH'b0;
            DataLine2 <= `IMG_DATA_LINE_WIDTH'b0;
            DataLine3 <= `IMG_DATA_LINE_WIDTH'b0;
    
            fLine1 <= `IMG_DATA_LINE_WIDTH'b0;
            fLine2 <= `IMG_DATA_LINE_WIDTH'b0;
            fLine3 <= `IMG_DATA_LINE_WIDTH'b0;
       
            mulLine1 <= `IMG_DATA_LINE_WIDTH'b0;
            mulLine2 <= `IMG_DATA_LINE_WIDTH'b0;
            mulLine3 <= `IMG_DATA_LINE_WIDTH'b0;
        
            fout <= `IMG_DATA_WIDTH * 2'b0;
        end
    end
 
    assign out = fout;
  
    always @(negedge clk) begin
    // clk2 时，mult_x 的计算会在上升沿做，占用一个时钟周期，所以整体在下降沿赋值，才能在一个周期内接收到对应的计算结果
    //always @(posedge clk) begin
        if(ena) begin
            // clk1
            // load input matrix and filter data to DataLine and fLine
            DataLine3 <= inMatrix[`IMG_DATA_LINE_WIDTH - 1:0];
            DataLine2 <= inMatrix[`IMG_DATA_LINE_WIDTH * 2 - 1:`IMG_DATA_LINE_WIDTH];
            DataLine1 <= inMatrix[`IMG_DATA_LINE_WIDTH * 3 - 1:`IMG_DATA_LINE_WIDTH * 2];
            fLine3 <= filterMatrix[`IMG_DATA_LINE_WIDTH - 1:0];
            fLine2 <= filterMatrix[`IMG_DATA_LINE_WIDTH * 2 - 1:`IMG_DATA_LINE_WIDTH];
            fLine1 <= filterMatrix[`IMG_DATA_LINE_WIDTH * 3 - 1:`IMG_DATA_LINE_WIDTH * 2];
  
            // clk2
            //  multiplication
            // 上升沿的时候做计算，得到mult_X，此时，即下降沿事赋值给mulLineX 
            mulLine1[`IMG_DATA_WIDTH - 1:0]                        <= mult_1[`IMG_DATA_WIDTH - 1:0];
            mulLine1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]      <= mult_1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH];
            mulLine1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2] <= mult_1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2];
              
            mulLine2[`IMG_DATA_WIDTH - 1:0]                        <= mult_2[`IMG_DATA_WIDTH - 1:0];
            mulLine2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]      <= mult_2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH];
            mulLine2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2] <= mult_2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2];
              
            mulLine3[`IMG_DATA_WIDTH - 1:0]                        <= mult_3[`IMG_DATA_WIDTH - 1:0];
            mulLine3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]      <= mult_3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH];
            mulLine3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2] <= mult_3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2];
    
            // clk3
            // addition
            fout <= mulLine1[`IMG_DATA_WIDTH - 1:0] + mulLine1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH] + mulLine1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]
                  + mulLine2[`IMG_DATA_WIDTH - 1:0] + mulLine2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH] + mulLine2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]
                  + mulLine3[`IMG_DATA_WIDTH - 1:0] + mulLine3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH] + mulLine3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2];
        end
    end

endmodule
