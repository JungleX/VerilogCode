`timescale 1ns / 1ps

`define clk_period 10

`define DATA_WIDTH		16 // 16 bits float
`define CLK_NUM_WIDTH	8

module MaxPoolUnitFloat16_tb();

	reg clk;
	reg rst;

	reg [`DATA_WIDTH - 1:0] cmp_data;
	reg [`CLK_NUM_WIDTH - 1:0] data_num;

	wire result_ready;
	wire [`DATA_WIDTH - 1:0] max_pool_result;

	MaxPoolUnitFloat16 maxCmp(
		.clk(clk),
		.rst(rst), // 0: reset; 1: none;

		.cmp_data(cmp_data),

		.data_num(data_num), // set the clk number, after clk_count clks, the output is ready

		.result_ready(result_ready), // 1: rady; 0: not ready;
		.max_pool_result(max_pool_result)
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

    	data_num	= 3;
    	cmp_data = 16'h4000;

    	#`clk_period
    	cmp_data = 16'h3c00;

    	#`clk_period
    	cmp_data = 16'h4700;

        // need data_num + 2 clks to get result
        // wait for 2 clks after submit the last number
        #(`clk_period*2)

    	#`clk_period
    	data_num	= 3;
    	cmp_data = 16'h4000;

    	#`clk_period
    	cmp_data = 16'h4400;

    	#`clk_period
    	cmp_data = 16'h4200;

        #(`clk_period*2)

        #`clk_period
        data_num    = 4;
        cmp_data = 16'h4800;

        #`clk_period
        cmp_data = 16'h4000;

        #`clk_period
        cmp_data = 16'h4400;

        #`clk_period
        cmp_data = 16'h4200;

        #(`clk_period*2)

        #`clk_period
        rst = 0;
    end
endmodule
