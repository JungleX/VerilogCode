`timescale 1ns / 1ps

`define clk_period 10

`include "CNN_Parameter.vh"

module FeatureMapRamFloat16_tb();

	reg clk;
	reg ena_w; 
	reg ena_r;

	reg ena_add_write; // 0: not add; 1: add
	reg [`WRITE_ADDR_WIDTH - 1:0] addr_write;
	reg [`PARA_Y*`DATA_WIDTH - 1:0] din;

	reg [`READ_ADDR_WIDTH - 1:0] addr_read;
	reg [`READ_ADDR_WIDTH - 1:0] sub_addr_read;
	wire write_ready;
	wire [`PARA_Y*`DATA_WIDTH - 1:0] dout;

	FeatureMapRamFloat16 ram_fm(
		.clk(clk),

		.ena_w(ena_w), // 0: read; 1: write
		.ena_add_write(ena_add_write), // 0: not add; 1: add
		.addr_write(addr_write),
		.din(din),

		.ena_r(ena_r),
		.addr_read(addr_read),
		.sub_addr_read(sub_addr_read),
		.write_ready(write_ready),
		.dout(dout)
    );

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0

    	#(`clk_period/2)

    	// PARA_Y = 3 =============================================
    	// write, not add
    	#`clk_period
    	ena_w = 1;
    	ena_add_write = 0;
    	addr_write = 0;
    	din = {16'h3c00, 16'h4000, 16'h4200};

    	ena_r = 0;

    	// write, not add
    	#`clk_period
    	ena_w = 1;
    	ena_add_write = 0;
    	addr_write = 1;
    	din = {16'h4200, 16'h4000, 16'h3c00};

    	// write, add
    	#`clk_period
    	ena_w = 1;
    	ena_add_write = 1;
    	addr_write = 1;
    	din = {16'h3c00, 16'h4000, 16'h3c00};

    	// write, add, wait
    	#`clk_period

    	// write, add and read
    	#`clk_period
    	ena_w = 1;
    	ena_add_write = 1;
    	addr_write = 1;
    	din = {16'h3c00, 16'h3c00, 16'h3c00};

    	ena_r = 1;
    	addr_read = 0;
    	sub_addr_read = 0;

    	// write, add, wait
    	#`clk_period

    	// read
    	#`clk_period
    	ena_w = 0;

    	ena_r = 1;
    	addr_read = 1;
    	sub_addr_read = 0;

    	// read
    	#`clk_period
    	ena_r = 1;
    	addr_read = 1;
    	sub_addr_read = 1;
    	// PARA_Y = 3 ============================================= 

/*
    	// PARA_Y = 2 =============================================
    	// write, not add
    	#`clk_period
    	ena_w = 1;
    	ena_add_write = 0;
    	addr_write = 0;
    	din = {16'h3c00, 16'h4000};

    	ena_r = 0;

    	// write, not add
    	#`clk_period
    	ena_w = 1;
    	ena_add_write = 0;
    	addr_write = 1;
    	din = {16'h4200, 16'h4000};

    	// write, add
    	#`clk_period
    	ena_w = 1;
    	ena_add_write = 1;
    	addr_write = 1;
    	din = {16'h3c00, 16'h4000};

    	// write, add, wait
    	#`clk_period

    	// write, add
    	#`clk_period
    	ena_w = 1;
    	ena_add_write = 1;
    	addr_write = 1;
    	din = {16'h3c00, 16'h3c00};

    	// write, add, wait
    	#`clk_period

    	// read
    	#`clk_period
    	ena_w = 0;

    	ena_r = 1;
    	addr_read = 0;
    	sub_addr_read = 0;

    	// read
    	#`clk_period
    	ena_r = 1;
    	addr_read = 1;
    	sub_addr_read = 0;

    	// read
    	#`clk_period
    	ena_r = 1;
    	addr_read = 1;
    	sub_addr_read = 1;
    	// PARA_Y = 2 ============================================= 
*/
    end
endmodule