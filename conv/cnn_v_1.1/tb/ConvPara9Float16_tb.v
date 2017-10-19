`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/14 22:39:39
// Design Name: 
// Module Name: ConvPara9Float16_tb
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
`define UNIT_NUM		9
`define RET_SIZE		144 // 16*9 = 144

module ConvPara9Float16_tb();

	reg clk;
	reg rst;

	reg [`DATA_WIDTH*3 - 1:0] fm_1;
	reg [`DATA_WIDTH*3 - 1:0] fm_2;
	reg [`DATA_WIDTH*3 - 1:0] fm_3;

	reg [`DATA_WIDTH - 1:0] weight;

	reg [`CLK_NUM_WIDTH - 1:0] clk_num;

	wire result_ready;
	wire [`RET_SIZE - 1:0] result_buffer;

    ConvPara9Float16 conv(
		.clk(clk),
		.rst(rst), // 0: reset; 1: none;

		.fm_1(fm_1),
		.fm_2(fm_2),
		.fm_3(fm_3),

		.weight(weight),

		.clk_num(clk_num),

		.result_ready(result_ready), // 1: rady; 0: not ready;
		.result_buffer(result_buffer)
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

    	// 0
		#`clk_period
    	rst = 1;
    	clk_num = 8;
    	fm_1 = {16'h0000, 16'h0000, 16'h0000;
    	fm_2 = {16'h4000, 16'h3c00, 16'h0000};
    	fm_3 = {16'h4200, 16'h4000, 16'h0000};

    	weight = 16'h3c00;

    	// 1
    	#`clk_period
        fm_1[`DATA_WIDTH - 1:0] = 16'h0000;
        fm_2[`DATA_WIDTH - 1:0] = 16'h4200;
        fm_3[`DATA_WIDTH - 1:0] = 16'h4400;
    	/*fm_1 = {16'h4700, 16'h4700, 16'h3c00};
    	fm_2 = {16'h4500, 16'h4800, 16'h3c00};
    	fm_3 = {16'h4400, 16'h4880, 16'h3c00};*/

    	weight = 16'h4000;

    	// 2
    	#`clk_period
        fm_1[`DATA_WIDTH - 1:0] = 16'h0000;
        fm_2[`DATA_WIDTH - 1:0] = 16'h3c00;
        fm_3[`DATA_WIDTH - 1:0] = 16'h4000;

    	weight = 16'h4200;

    	// 3
    	#`clk_period
    	fm_3 = {16'h4000, 16'h3c00, 16'h0000};

    	weight = 16'h3c00;
    	
    	// 4
    	#`clk_period
    	fm_3[`DATA_WIDTH - 1:0] = 16'h4400;

    	weight = 16'h4000;
    	
    	// 5
    	#`clk_period
        fm_3[`DATA_WIDTH - 1:0] = 16'h4200;

		weight = 16'h3c00;
    	
    	// 6
    	#`clk_period
    	fm_3 = {16'h4000, 16'h4200, 16'h0000};

    	weight = 16'h0000;
    	
    	// 7
    	#`clk_period
    	fm_3[`DATA_WIDTH - 1:0] = 16'h3c00;

    	weight = 16'h4000;
    	
    	// 8
    	#`clk_period
        fm_3[`DATA_WIDTH - 1:0] = 16'h4400;

    	weight = 16'h3c00;

    	// 9 output ready
    	// #`clk_period

    	#`clk_period
        if (result_ready == 1) begin
            rst = 0;
        end

        #`clk_period
        if (result_ready == 1) begin
            rst = 0;
        end

        #`clk_period
        if (result_ready == 1) begin
            rst = 0;
        end

        #`clk_period
        if (result_ready == 1) begin
            rst = 0;
        end

        #`clk_period
        if (result_ready == 1) begin
            rst = 0;
        end

        #`clk_period
        if (result_ready == 1) begin
            rst = 0;
        end

    end
    
endmodule
