`timescale 1ns / 1ps

`define DATA_WIDTH		16  // 16 bits float

`define KERNEL_SIZE_MAX			SET_KERNEL_SIZE_MAX

`define WEIGHT_RAM_MAX			SET_WEIGHT_RAM_MAX 

`define WEIGHT_READ_ADDR_WIDTH	SET_WEIGHT_READ_WIDTH  
`define WEIGHT_WRITE_ADDR_WIDTH	SET_WEIGHT_WRITE_WIDTH 

module WeightRamFloat16(
	input clk,
	input ena_wr, // 0: read; 1: write

	input [`WEIGHT_WRITE_ADDR_WIDTH - 1:0] addr_write,
	input [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH - 1:0] din, // write a slice weight(ks*ks, eg:3*3=9) each time

	input [`WEIGHT_READ_ADDR_WIDTH - 1:0] addr_read,

	output reg [`DATA_WIDTH - 1:0] dout // read a value each time
	);

	reg [`DATA_WIDTH - 1:0] ram_array [0:`WEIGHT_RAM_MAX - 1];

	integer i;
	initial begin
		dout = 0;
		for (i = 0; i < `WEIGHT_RAM_MAX; i = i + 1)
		begin
			ram_array[i] = 0;
		end
	end

	always @(posedge clk) begin
		if (ena_wr == 1) begin // write
			// ======== Begin: write data ========
			// ======== Begin: write data ========
		end
	end

	always @(clk) begin
		if (ena_wr == 0) begin // read
			dout <= ram_array[addr_read];
		end
	end

endmodule