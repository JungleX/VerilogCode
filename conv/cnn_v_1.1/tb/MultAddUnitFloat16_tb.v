`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/12 10:30:02
// Design Name: 
// Module Name: MultAddUnitFloat16_tb
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

`define clk_period 10

`define DATA_WIDTH		16 // 16 bits float
`define CLK_NUM_WIDTH	8

module MultAddUnitFloat16_tb(

    );

	reg clk;
	reg rst;

	reg [`DATA_WIDTH - 1:0] mult_a;
	reg [`DATA_WIDTH - 1:0] mult_b;
	reg [`CLK_NUM_WIDTH - 1:0] clk_num;

	wire result_ready;
	wire [`DATA_WIDTH - 1:0] mult_add_result;

	MultAddUnitFloat16 mult_add_unit(
		.clk(clk),
		.rst(rst), // 0: reset; 1: none;

		.mult_a(mult_a),
		.mult_b(mult_b),

		.clk_num(clk_num), // set the clk number, after clk_count clks, the output is ready

		.result_ready(result_ready), // 1: rady; 0: not ready;
		.mult_add_result(mult_add_result)
    );

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0
    	rst = 1;

    	#(`clk_period/2)
    	// reset
    	rst = 0;

    	#`clk_period
    	rst = 1;

    	clk_num	= 4;
    	mult_a	= 16'h3c00; // 1
    	mult_b	= 16'h4000; // 2
    	// 4000

    	#`clk_period
    	mult_a	= 16'h4000; // 2
    	mult_b	= 16'h4000; // 2
    	// 4400

    	#`clk_period
    	mult_a	= 16'h4000; // 2
    	mult_b	= 16'h4200; // 3
    	// 4600

		#`clk_period
    	mult_a	= 16'h3c00; // 1
    	mult_b	= 16'h4000; // 2
    	// 4000

    	#(`clk_period*2)
    	clk_num	= 2;
    	mult_a	= 16'h3c00; // 1
    	mult_b	= 16'h4000; // 2
    	// 4000

    	#`clk_period
    	mult_a	= 16'h4000; // 2
    	mult_b	= 16'h4000; // 2
    	// 4400

    	#`clk_period
    	mult_a	= 0;
    	mult_b	= 0; 

    	#(`clk_period*2)
    	rst = 0;
    end
endmodule