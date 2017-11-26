`timescale 1ns / 1ps

`define clk_period 10

`include "CNN_Parameter.vh"

module WeightRamFloat16_tb();

	reg clk;
	reg ena_w; 
	reg ena_r;

	reg [`WEIGHT_WRITE_ADDR_WIDTH - 1:0] addr_write;
	reg [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH - 1:0] din; // write a slice weight(ks*ks, eg:3*3=9) each time

	reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] addr_read;

    reg ena_fc_r; // 0: not read; 1: read
    reg [`FM_SIZE_WIDTH - 1:0] fm_size;

	wire [`PARA_Y*`DATA_WIDTH - 1:0] dout; // read a value each time

	WeightRamFloat16 weight_ram(
		.clk(clk),

		.ena_w(ena_w), // 0: read; 1: write
		.addr_write(addr_write),
		.din(din), // write a slice weight(ks*ks, eg:3*3=9) each time

		.ena_r(ena_r),

        .ena_fc_r(ena_fc_r), // 0: not read; 1: read
        .fm_size(fm_size),

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
    	ena_w <= 1;
    	addr_write <= 0;
    	din <= {16'h3c00, 16'h4000, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h3c00}; // 3*3=9

    	ena_r <= 0;
        ena_fc_r <= 0;

    	// write and read
    	#`clk_period
    	ena_w <= 1;
    	addr_write <= `KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX;
    	din <= {16'h0000, 16'h4200, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h3c00};

        // read
    	ena_r <= 1;
    	addr_read <= 3;

    	#`clk_period
    	ena_r <= 1;
    	addr_read <= 1;

    	#`clk_period
    	ena_r <= 1;
    	addr_read <= `KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX+3; //3*3+1;

        // fc read
        #`clk_period
        ena_r <= 0;
        ena_fc_r <= 1;
        fm_size <= 3;
        addr_read <= 0;

        #`clk_period
        ena_r <= 0;
        ena_fc_r <= 1;
        fm_size <= 3;
        addr_read <= 1;

        #`clk_period
        ena_r <= 0;
        ena_fc_r <= 1;
        fm_size <= 3;
        addr_read <= 2;

        #`clk_period
        ena_r <= 0;
        ena_fc_r <= 1;
        fm_size <= 3;
        addr_read <= 3;

    end
endmodule