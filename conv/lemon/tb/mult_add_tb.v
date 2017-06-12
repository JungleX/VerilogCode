`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/06/12 10:34:53
// Design Name: 
// Module Name: mult_add_tb
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

module mult_add_tb();

	reg clk;
	reg multAddRst;

	reg [`DATA_WIDTH - 1:0] data;
	reg [`DATA_WIDTH - 1:0] weight;
	reg [`DATA_WIDTH - 1:0] sum;

	wire [`DATA_WIDTH - 1:0] multAddResult;

	mult_add ma(
		.clk(clk),
		.multAddRst(multAddRst),

		.data(data),
		.weight(weight),
		.sum(sum),

		.multAddResult(multAddResult)
	);

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0
    	multAddRst = 1;

    	#(`clk_period/2)
    	multAddRst = 0; // reset

    	#`clk_period
    	multAddRst = 1;
    	data = 16'h3c00;   // 1
    	weight = 16'h4200; // 3
    	sum  = 16'h4500;   // 5
    	// 1*3+5=8 4800 

    	#`clk_period
    	multAddRst = 1;
    	data = 16'h4700;   // 7
    	weight = 16'h4b00; // 14
    	sum  = 16'hbc00;   // -1
    	// 7*14-1=97 5610

    end
endmodule
