`timescale 1ns / 1ps

`define clk_period 10

`define DATA_WIDTH		16  // 16 bits float

`define KERNEL_SIZE_MAX	5

`define WEIGHT_RAM_MAX			27 

`define WEIGHT_READ_ADDR_WIDTH	10  
`define WEIGHT_WRITE_ADDR_WIDTH	5 

module WeightRamFloat16_tb();

	reg clk;
	reg ena_wr; // 0: read; 1: write

	reg [`WEIGHT_WRITE_ADDR_WIDTH - 1:0] addr_write;
	reg [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH - 1:0] din; // write a slice weight(ks*ks, eg:3*3=9) each time

	reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] addr_read;

	wire [`DATA_WIDTH - 1:0] dout; // read a value each time

	WeightRamFloat16 weight_ram(
		.clk(clk),
		.ena_wr(ena_wr), // 0: read; 1: write

		.addr_write(addr_write),
		.din(din), // write a slice weight(ks*ks, eg:3*3=9) each time

		.addr_read(addr_read),

		.dout(dout) // read a value each time
	);

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0

    	#(`clk_period/2)
    	// write
    	#`clk_period
    	ena_wr = 1;
    	addr_write = 0;
    	din = {16'h3c00, 16'h4000, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h3c00}; // 3*3=9

    	// write
    	#`clk_period
    	ena_wr = 1;
    	addr_write = 1;
    	din = {16'h0000, 16'h4200, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h3c00};

    	// read
    	#`clk_period
    	ena_wr = 0;
    	addr_read = 0;

    	// read
    	#`clk_period
    	ena_wr = 0;
    	addr_read = 1;

    	// read
    	#`clk_period
    	ena_wr = 0;
    	addr_read = `KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX+3; //3*3+1;

    end
endmodule
