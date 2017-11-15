`timescale 1ns / 1ps

`define clk_period 10

`include "CNN_Parameter.vh"

module AvgPoolUnitFloat16_tb();

	reg clk;
	reg rst;

	reg [`DATA_WIDTH - 1:0] avg_input_data;

	reg [`CLK_NUM_WIDTH - 1:0] data_num;

	wire result_ready;
	wire [`DATA_WIDTH - 1:0] avg_pool_result;

	AvgPoolUnitFloat16 AvgPool(
		.clk(clk),
		.rst(rst), // 0: reset; 1: none;
		.avg_input_data(avg_input_data),

		.data_num(data_num),

		.result_ready(result_ready), // 1: ready; 0: not ready;
		.avg_pool_result(avg_pool_result)
    );

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0
    	rst <= 1;

    	#(`clk_period/2)
    	// reset
    	rst <= 0;

    	#`clk_period
    	rst <= 1;

    	data_num	<= 5;
    	avg_input_data <= 16'h3c00;

    	#`clk_period
    	avg_input_data <= 16'h3c00;

    	#`clk_period
    	avg_input_data <= 16'h3c00;

        #`clk_period
        avg_input_data <= 16'h3c00;

        #`clk_period
        avg_input_data <= 16'h3c00;

        #(`clk_period*3)

        #`clk_period
        data_num    <= 3;
        avg_input_data <= 16'h4000;

        #`clk_period
        avg_input_data <= 16'h3c00;

        #`clk_period
        avg_input_data <= 16'h4200;

        #(`clk_period*3)

        #`clk_period
        rst = 0;
    end
endmodule