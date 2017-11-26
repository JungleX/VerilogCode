`timescale 1ns / 1ps

`include "CNN_Parameter.vh"

module WeightRamFloat16(
	input clk,
	
	input ena_w, // 0: not write; 1: write
	input [`WEIGHT_WRITE_ADDR_WIDTH - 1:0] addr_write,
	input [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH - 1:0] din, // write a slice weight(ks*ks, eg:3*3=9) each time

	// conv read
	input ena_r, // 0: not read; 1: read

	// fc read
	input ena_fc_r, // 0: not read; 1: read
	input [`FM_SIZE_WIDTH - 1:0] fm_total_size,

	// read address
	input [`WEIGHT_READ_ADDR_WIDTH - 1:0] addr_read,

	output reg [`PARA_Y*`DATA_WIDTH - 1:0] dout
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
		if (ena_w == 1) begin // write
			// ======== Begin: write data ========
			ram_array[addr_write + 0] <= din[`DATA_WIDTH*1 - 1:`DATA_WIDTH*0];
			ram_array[addr_write + 1] <= din[`DATA_WIDTH*2 - 1:`DATA_WIDTH*1];
			ram_array[addr_write + 2] <= din[`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
			ram_array[addr_write + 3] <= din[`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
			ram_array[addr_write + 4] <= din[`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
			ram_array[addr_write + 5] <= din[`DATA_WIDTH*6 - 1:`DATA_WIDTH*5];
			ram_array[addr_write + 6] <= din[`DATA_WIDTH*7 - 1:`DATA_WIDTH*6];
			ram_array[addr_write + 7] <= din[`DATA_WIDTH*8 - 1:`DATA_WIDTH*7];
			ram_array[addr_write + 8] <= din[`DATA_WIDTH*9 - 1:`DATA_WIDTH*8];
			ram_array[addr_write + 9] <= din[`DATA_WIDTH*10 - 1:`DATA_WIDTH*9];
			ram_array[addr_write + 10] <= din[`DATA_WIDTH*11 - 1:`DATA_WIDTH*10];
			ram_array[addr_write + 11] <= din[`DATA_WIDTH*12 - 1:`DATA_WIDTH*11];
			ram_array[addr_write + 12] <= din[`DATA_WIDTH*13 - 1:`DATA_WIDTH*12];
			ram_array[addr_write + 13] <= din[`DATA_WIDTH*14 - 1:`DATA_WIDTH*13];
			ram_array[addr_write + 14] <= din[`DATA_WIDTH*15 - 1:`DATA_WIDTH*14];
			ram_array[addr_write + 15] <= din[`DATA_WIDTH*16 - 1:`DATA_WIDTH*15];
			ram_array[addr_write + 16] <= din[`DATA_WIDTH*17 - 1:`DATA_WIDTH*16];
			ram_array[addr_write + 17] <= din[`DATA_WIDTH*18 - 1:`DATA_WIDTH*17];
			ram_array[addr_write + 18] <= din[`DATA_WIDTH*19 - 1:`DATA_WIDTH*18];
			ram_array[addr_write + 19] <= din[`DATA_WIDTH*20 - 1:`DATA_WIDTH*19];
			ram_array[addr_write + 20] <= din[`DATA_WIDTH*21 - 1:`DATA_WIDTH*20];
			ram_array[addr_write + 21] <= din[`DATA_WIDTH*22 - 1:`DATA_WIDTH*21];
			ram_array[addr_write + 22] <= din[`DATA_WIDTH*23 - 1:`DATA_WIDTH*22];
			ram_array[addr_write + 23] <= din[`DATA_WIDTH*24 - 1:`DATA_WIDTH*23];
			ram_array[addr_write + 24] <= din[`DATA_WIDTH*25 - 1:`DATA_WIDTH*24];
			// ======== Begin: write data ========
		end
	end

	always @(clk) begin
		if (ena_r == 1) begin // read
			dout[`DATA_WIDTH - 1:0] <= ram_array[addr_read];
		end
		else if(ena_fc_r == 1) begin // fc read
			// ======== Begin: fc read data ========
			dout <= {
						ram_array[addr_read+fm_total_size*2],
						ram_array[addr_read+fm_total_size*1],
						ram_array[addr_read+fm_total_size*0]
					};
			// ======== End: fc read data ========
		end
	end

endmodule