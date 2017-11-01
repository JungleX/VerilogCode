`timescale 1ns / 1ps

`define DATA_WIDTH		16  // 16 bits float

`define KERNEL_SIZE_MAX			5

`define WEIGHT_RAM_MAX			100 

`define WEIGHT_READ_ADDR_WIDTH	10  
`define WEIGHT_WRITE_ADDR_WIDTH	5 

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
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 0] <= din[`DATA_WIDTH*1 - 1:`DATA_WIDTH*0];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 1] <= din[`DATA_WIDTH*2 - 1:`DATA_WIDTH*1];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 2] <= din[`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 3] <= din[`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 4] <= din[`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 5] <= din[`DATA_WIDTH*6 - 1:`DATA_WIDTH*5];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 6] <= din[`DATA_WIDTH*7 - 1:`DATA_WIDTH*6];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 7] <= din[`DATA_WIDTH*8 - 1:`DATA_WIDTH*7];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 8] <= din[`DATA_WIDTH*9 - 1:`DATA_WIDTH*8];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 9] <= din[`DATA_WIDTH*10 - 1:`DATA_WIDTH*9];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 10] <= din[`DATA_WIDTH*11 - 1:`DATA_WIDTH*10];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 11] <= din[`DATA_WIDTH*12 - 1:`DATA_WIDTH*11];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 12] <= din[`DATA_WIDTH*13 - 1:`DATA_WIDTH*12];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 13] <= din[`DATA_WIDTH*14 - 1:`DATA_WIDTH*13];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 14] <= din[`DATA_WIDTH*15 - 1:`DATA_WIDTH*14];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 15] <= din[`DATA_WIDTH*16 - 1:`DATA_WIDTH*15];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 16] <= din[`DATA_WIDTH*17 - 1:`DATA_WIDTH*16];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 17] <= din[`DATA_WIDTH*18 - 1:`DATA_WIDTH*17];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 18] <= din[`DATA_WIDTH*19 - 1:`DATA_WIDTH*18];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 19] <= din[`DATA_WIDTH*20 - 1:`DATA_WIDTH*19];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 20] <= din[`DATA_WIDTH*21 - 1:`DATA_WIDTH*20];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 21] <= din[`DATA_WIDTH*22 - 1:`DATA_WIDTH*21];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 22] <= din[`DATA_WIDTH*23 - 1:`DATA_WIDTH*22];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 23] <= din[`DATA_WIDTH*24 - 1:`DATA_WIDTH*23];
			ram_array[addr_write*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX + 24] <= din[`DATA_WIDTH*25 - 1:`DATA_WIDTH*24];
			// ======== Begin: write data ========
		end
	end

	always @(clk) begin
		if (ena_wr == 0) begin // read
			dout <= ram_array[addr_read];
		end
	end

endmodule