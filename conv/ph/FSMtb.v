`timescale 1ns / 1ps

`define clk_period 10

`include "CNN_Parameter.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/30 10:55:14
// Design Name: 
// Module Name: FSMtb
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


module FSMtb();
    reg clk;
    reg rst;
    reg transmission_start;
    
    FSM fsm(
         //input clk_p,
         //input clk_n,
         .clk(clk),
         .rst(rst),
         .transmission_start(transmission_start),
        );

initial
clk = 1'b0;
always #(`clk_period/2) clk = ~clk;

initial begin
    #0
       
    #(`clk_period * 0.3)
    rst <= 1;
    
    #(`clk_period * 0.7)
    rst <= 0;
    
    #(`clk_period * 0.3)
    transmission_start <= 1;
end
endmodule
