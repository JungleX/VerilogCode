`timescale 1ns / 1ps

`define clk_period 10

`include "CNN_Parameter.vh"

module PoolMaxParaScaleFloat16_tb();

	reg clk;

	reg [`POOL_PARA_Y*`DATA_WIDTH - 1:0] input_data;

	reg [`POOL_SIZE_WIDTH - 1:0] pool_size;

	reg mpu_rst;

	wire [`POOL_PARA_Y - 1:0] mpu_out_ready;
	wire [`POOL_PARA_Y*`DATA_WIDTH - 1:0] mpu_result;

	generate
		genvar i;
		for (i = 0; i < `POOL_PARA_Y; i = i + 1)
		begin:identifier_mpu
			MaxPoolUnitFloat16 mpu(
				.clk(clk),
				.rst(mpu_rst), // 0: reset; 1: none;

				.cmp_data(input_data[`DATA_WIDTH*(i+1):`DATA_WIDTH*i]),

				.data_num(pool_size*pool_size), // set the clk number, after clk_count clks, the output is ready

				.result_ready(mpu_out_ready[i:i]), // 1: rady; 0: not ready;
				.max_pool_result(mpu_result[`DATA_WIDTH*(i+1):`DATA_WIDTH*i])
			);
		end
	endgenerate

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0
    	mpu_rst = 1;

    	#(`clk_period/2)
    	// reset
    	mpu_rst = 0;

    	// pool size = 3
    	#`clk_period
    	mpu_rst = 1;

    	pool_size = 3;
    	input_data = {16'h3c00, 16'h4000, 16'h4200};

    	#`clk_period
    	input_data = {16'h4000, 16'h4400, 16'h4200};

    	#`clk_period
    	input_data = {16'h4400, 16'h4600, 16'h4600};

    	#`clk_period
    	input_data = {16'h4200, 16'h4800, 16'h4000};

    	#`clk_period
    	input_data = {16'h4700, 16'h3c00, 16'h4700};

    	#`clk_period
    	input_data = {16'h4600, 16'h4200, 16'h4200};

    	#`clk_period
    	input_data = {16'h3c00, 16'h4500, 16'h4200};

    	#`clk_period
    	input_data = {16'h4000, 16'h4200, 16'h3c00};

    	#`clk_period
    	input_data = {16'h4400, 16'h4000, 16'h4200};

    	#(`clk_period*2)

    	// pool size = 2
    	#`clk_period
    	pool_size = 2;
    	input_data = {16'h3c00, 16'h4000, 16'h4200};

    	#`clk_period
    	input_data = {16'h4400, 16'h4200, 16'h4200};

    	#`clk_period
    	input_data = {16'h3c00, 16'h4500, 16'h4200};

    	#`clk_period
    	input_data = {16'h4500, 16'h4000, 16'h4200};

    	#(`clk_period*2)

    	#`clk_period
    	if (&mpu_out_ready == 1) begin
    		mpu_rst = 0;
    	end
    end
endmodule