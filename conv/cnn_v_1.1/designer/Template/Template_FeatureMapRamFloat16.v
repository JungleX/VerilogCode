`timescale 1ns / 1ps

`define DATA_WIDTH		16  // 16 bits float

`define PARA_Y			SET_PARA_Y	// MAC number of each MAC group

`define RAM_MAX			SET_RAM_MAX 

`define READ_ADDR_WIDTH		SET_READ_WIDTH 
`define WRITE_ADDR_WIDTH	SET_WRITE_WIDTH 

module FeatureMapRamFloat16(
	input clk,
	input ena_wr, // 0: read; 1: write

	input ena_add_write, // 0: not add; 1: add
	input [`WRITE_ADDR_WIDTH - 1:0] addr_write,
	input [`PARA_Y*`DATA_WIDTH - 1:0] din,

	input [`READ_ADDR_WIDTH - 1:0] addr_read,

	output reg write_ready,
	output reg [`PARA_Y*`DATA_WIDTH - 1:0] dout
    );

	reg [`DATA_WIDTH - 1:0] ram_array [0:`RAM_MAX - 1];

	reg clk_count;

	// addition
	reg add_a_tvalid;
	reg [`PARA_Y*`DATA_WIDTH - 1:0] add_a_tdata;
	reg add_b_tvalid;
	reg [`PARA_Y*`DATA_WIDTH - 1:0] add_b_tdata;

	wire [`PARA_Y - 1:0] add_re_tvalid;
	wire [`DATA_WIDTH - 1:0] add_re_tdata[0:`PARA_Y - 1] ;
	generate
		genvar add_i;
		for (add_i = 0; add_i < `PARA_Y; add_i = add_i + 1)
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
				// ======== Begin: update data not add ========
				// ======== End: update data not add ========
			end
			else if (ena_add_write == 1) begin // add
				if (clk_count == 0) begin
					write_ready <= 0;

					// ======== Begin: add operation ========
					add_a_tdata <= {
									ram_array[addr_write*`PARA_Y]
								};
					// ======== End: add operation ========

					add_b_tdata <= din;

					clk_count	<= 1;
				end
				else begin
					write_ready	<= 1;

					// ======== Begin: update data add ========
					// ======== End: update data add ========

					clk_count	<= 0;
				end
			end
			
		end
		else if (ena_wr == 0) begin // read
			// ======== Begin: read out ========
			dout <= {
						ram_array[addr_read*`PARA_Y]
					};
			// ======== End: read out ========
		end
	end
endmodule