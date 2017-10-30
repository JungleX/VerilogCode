`timescale 1ns / 1ps

`define DATA_WIDTH		16  // 16 bits float

`define PARA_X			3	// MAC group number
`define PARA_Y			3	// MAC number of each MAC group

`define RAM_MAX			22 // 22*3(PARA_Y)>=64 // Alexnet layer 1 output 55*55*96=290400

`define READ_ADDR_WIDTH		4 // 22 / 3(PARA_Y) <= 8 width:4 // MAX VALUE = RAM_MAX / PARA_Y
`define WRITE_ADDR_WIDTH	2 // 22 / (3*3) (PARA_Y*PARA_X) <= 3 width:2

module FeatureMapRam(
	input clk,
	input ena_wr, // 0: read; 1: write

	input ena_add_write, // 0: not add; 1: add
	input [`WRITE_ADDR_WIDTH - 1:0] addr_write,
	input [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] din,

	input [`READ_ADDR_WIDTH - 1:0] addr_read,

	output reg write_ready,
	output reg [`PARA_Y*`DATA_WIDTH - 1:0] dout
    );

	reg [`DATA_WIDTH - 1:0] ram_array [0:`RAM_MAX - 1];

	reg clk_count;

	// addition
	reg add_a_tvalid;
	reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] add_a_tdata;
	reg add_b_tvalid;
	reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] add_b_tdata;

	wire [`PARA_X*`PARA_Y - 1:0] add_re_tvalid;
	wire [`DATA_WIDTH - 1:0] add_re_tdata[0:`PARA_X*`PARA_X - 1] ;
	generate
		genvar add_i;
		for (add_i = 0; add_i < `PARA_X*`PARA_Y; add_i = add_i + 1)
		begin
			floating_point_add add(
		        .s_axis_a_tvalid(add_a_tvalid),
		        .s_axis_a_tdata(add_a_tdata[`DATA_WIDTH*(add_i+1) - 1:`DATA_WIDTH*add_i]),

		        .s_axis_b_tvalid(add_b_tvalid),
		        .s_axis_b_tdata(add_b_tdata[`DATA_WIDTH*(add_i+1) - 1:`DATA_WIDTH*add_i]),

		        .m_axis_result_tvalid(add_re_tvalid[add_i:add_i]),
		        .m_axis_result_tdata(add_re_tdata[add_i])
		    );
		end
	endgenerate
	integer i;

	initial begin
		dout = 0;
		clk_count = 0;
		for (i = 0; i < `RAM_MAX; i = i + 1)
		begin
			ram_array[i] = 0;
		end
	end

	always @(posedge clk) begin
		if (ena_wr == 1) begin // write
			if (ena_add_write == 0) begin // not add
				ram_array[addr_write*`PARA_X*`PARA_Y] 		<= din[`DATA_WIDTH - 1:0];
				ram_array[addr_write*`PARA_X*`PARA_Y + 1]	<= din[`DATA_WIDTH*2 - 1:`DATA_WIDTH];
				ram_array[addr_write*`PARA_X*`PARA_Y + 2]	<= din[`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
				ram_array[addr_write*`PARA_X*`PARA_Y + 3]	<= din[`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
				ram_array[addr_write*`PARA_X*`PARA_Y + 4]	<= din[`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
				ram_array[addr_write*`PARA_X*`PARA_Y + 5]	<= din[`DATA_WIDTH*6 - 1:`DATA_WIDTH*5];
				ram_array[addr_write*`PARA_X*`PARA_Y + 6]	<= din[`DATA_WIDTH*7 - 1:`DATA_WIDTH*6];
				ram_array[addr_write*`PARA_X*`PARA_Y + 7]	<= din[`DATA_WIDTH*8 - 1:`DATA_WIDTH*7];
				ram_array[addr_write*`PARA_X*`PARA_Y + 8]	<= din[`DATA_WIDTH*9 - 1:`DATA_WIDTH*8];
			end
			else if (ena_add_write == 1) begin // add
				if (clk_count == 0) begin
					write_ready <= 0;

					add_a_tdata <= {ram_array[addr_write*`PARA_X*`PARA_Y + 8], ram_array[addr_write*`PARA_X*`PARA_Y + 7], ram_array[addr_write*`PARA_X*`PARA_Y + 6], 
									ram_array[addr_write*`PARA_X*`PARA_Y + 5], ram_array[addr_write*`PARA_X*`PARA_Y + 4], ram_array[addr_write*`PARA_X*`PARA_Y + 3], 
									ram_array[addr_write*`PARA_X*`PARA_Y + 2], ram_array[addr_write*`PARA_X*`PARA_Y + 1], ram_array[addr_write*`PARA_X*`PARA_Y]};
					add_b_tdata <= din;

					clk_count	<= 1;
				end
				else begin
					write_ready	<= 1;

					ram_array[addr_write*`PARA_X*`PARA_Y] 		<= add_re_tdata[0];
					ram_array[addr_write*`PARA_X*`PARA_Y + 1]	<= add_re_tdata[1];
					ram_array[addr_write*`PARA_X*`PARA_Y + 2]	<= add_re_tdata[2];
					ram_array[addr_write*`PARA_X*`PARA_Y + 3]	<= add_re_tdata[3];
					ram_array[addr_write*`PARA_X*`PARA_Y + 4]	<= add_re_tdata[4];
					ram_array[addr_write*`PARA_X*`PARA_Y + 5]	<= add_re_tdata[5];
					ram_array[addr_write*`PARA_X*`PARA_Y + 6]	<= add_re_tdata[6];
					ram_array[addr_write*`PARA_X*`PARA_Y + 7]	<= add_re_tdata[7];
					ram_array[addr_write*`PARA_X*`PARA_Y + 8]	<= add_re_tdata[8];

					clk_count	<= 0;
				end
			end
			
		end
		else if (ena_wr == 0) begin // read
			dout <= {ram_array[addr_read*`PARA_Y+2], ram_array[addr_read*`PARA_Y+1], ram_array[addr_read*`PARA_Y]};
		end
	end
endmodule
