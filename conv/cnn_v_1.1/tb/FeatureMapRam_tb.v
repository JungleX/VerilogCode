`timescale 1ns / 1ps

`define clk_period 10

`define DATA_WIDTH		16  // 16 bits float

`define PARA_X			3	// MAC group number
`define PARA_Y			3	// MAC number of each MAC group

`define RAM_MAX			22 // 22*3(PARA_Y)>=64 // Alexnet layer 1 output 55*55*96=290400

`define READ_ADDR_WIDTH		4 // 22 / 3(PARA_Y) <= 8 width:4 // MAX VALUE = RAM_MAX / PARA_Y
`define WRITE_ADDR_WIDTH	2 // 22 / (3*3) (PARA_Y*PARA_X) <= 3 width:2

module FeatureMapRam_tb();

	reg clk;
	reg ena_wr; // 0: read; 1: write

	reg ena_add_write; // 0: not add; 1: add
	reg [`WRITE_ADDR_WIDTH - 1:0] addr_write;
	reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] din;

	reg [`READ_ADDR_WIDTH - 1:0] addr_read;
	wire write_ready;
	wire [`PARA_Y*`DATA_WIDTH - 1:0] dout;

	FeatureMapRam ram_fm(
		.clk(clk),
		.ena_wr(ena_wr), // 0: read; 1: write

		.ena_add_write(ena_add_write), // 0: not add; 1: add
		.addr_write(addr_write),
		.din(din),

		.addr_read(addr_read),
		.write_ready(write_ready),
		.dout(dout)
    );

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0

    	#(`clk_period/2)

    	// write, not add
    	#`clk_period
    	ena_wr = 1;
    	ena_add_write = 0;
    	addr_write = 0;
    	din = {16'h3c00, 16'h4000, 16'h4200, 16'h4400, 16'h4500, 16'h4600, 16'h4700, 16'h4800, 16'h4880};

    	// write, not add
    	#`clk_period
    	ena_wr = 1;
    	ena_add_write = 0;
    	addr_write = 1;
    	din = {16'h4200, 16'h4000, 16'h4200, 16'h4400, 16'h4500, 16'h4600, 16'h4700, 16'h4800, 16'h4880};

    	// write, add
    	#`clk_period
    	ena_wr = 1;
    	ena_add_write = 1;
    	addr_write = 1;
    	din = {16'h3c00, 16'h4000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4000, 16'h3c00};

    	// write, add, wait
    	#`clk_period

    	// write, add
    	#`clk_period
    	ena_wr = 1;
    	ena_add_write = 1;
    	addr_write = 1;
    	din = {16'h3c00, 16'h3c00, 16'h3c00, 16'h3c00, 16'h3c00, 16'h3c00, 16'h3c00, 16'h3c00, 16'h3c00};

    	// write, add, wait
    	#`clk_period
    	
    	// read
    	#`clk_period
    	ena_wr = 0;
    	addr_read = 0;

    	// read
    	#`clk_period
    	ena_wr = 0;
    	addr_read = 1;
    end
endmodule
