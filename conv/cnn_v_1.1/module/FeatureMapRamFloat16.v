`timescale 1ns / 1ps

`include "CNN_Parameter.vh"

module FeatureMapRamFloat16(
	input clk,

	input ena_add_write, // 0: not add; 1: add 

	input ena_zero_w, // 0: not write; 1: write
	input [`WRITE_ADDR_WIDTH - 1:0] zero_start_addr,
	input [`WRITE_ADDR_WIDTH - 1:0] zero_end_addr,

	input ena_w, // 0: not write; 1: write
	input [`WRITE_ADDR_WIDTH - 1:0] addr_write,
	input [`PARA_Y*`DATA_WIDTH - 1:0] din,

	input ena_para_w, // 0: not write; 1: write
	input [`WRITE_ADDR_WIDTH - 1:0] addr_para_write, // single index, one by one
	input [`FM_SIZE_WIDTH - 1:0] fm_out_size,
	input [`PARA_Y*`PARA_KERNEL*`DATA_WIDTH - 1:0] para_din,

	input ena_r, // 0: not read; 1: read
	input [`READ_ADDR_WIDTH - 1:0] addr_read,
	input [`READ_ADDR_WIDTH - 1:0] sub_addr_read,

	input ena_pool_r, // 0: not read; 1: read
	input [`READ_ADDR_WIDTH - 1:0] addr_pool_read,

	output reg write_ready,
	output reg [`PARA_Y*`DATA_WIDTH - 1:0] dout
    );

	reg [`DATA_WIDTH - 1:0] ram_array [0:`FM_RAM_MAX - 1];

	reg clk_count;

	// addition
	reg add_a_tvalid;
	reg [`PARA_Y*`PARA_KERNEL*`DATA_WIDTH - 1:0] add_a_tdata;
	reg add_b_tvalid;
	reg [`PARA_Y*`PARA_KERNEL*`DATA_WIDTH - 1:0] add_b_tdata;

	wire [`PARA_Y*`PARA_KERNEL - 1:0] add_re_tvalid;
	wire [`DATA_WIDTH - 1:0] add_re_tdata[0:`PARA_Y*`PARA_KERNEL - 1] ;
	generate
		genvar add_i;
		for (add_i = 0; add_i < `PARA_Y*`PARA_KERNEL; add_i = add_i + 1)
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
		for (i = 0; i < `FM_RAM_MAX; i = i + 1)
		begin
			ram_array[i] = 0;
		end
	end

	always @(posedge clk) begin
		if (ena_zero_w == 1) begin
			for (i = zero_start_addr; i < zero_end_addr; i = i + 1)
			begin
				ram_array[i] = 0;
			end
		end
		else if (ena_w == 1) begin // init write
			if (ena_add_write == 0) begin // not add
				// ======== Begin: update data not add ========
				ram_array[addr_write*`PARA_Y + 0] <= din[`DATA_WIDTH*1 - 1:`DATA_WIDTH*0];
				ram_array[addr_write*`PARA_Y + 1] <= din[`DATA_WIDTH*2 - 1:`DATA_WIDTH*1];
				ram_array[addr_write*`PARA_Y + 2] <= din[`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
				// ======== End: update data not add ========
			end
			else if (ena_add_write == 1) begin // add
				if (clk_count == 0) begin
					write_ready <= 0;

					// ======== Begin: add operation ========
					add_a_tdata <= {
									ram_array[addr_write*`PARA_Y + 2],
									ram_array[addr_write*`PARA_Y + 1],
									ram_array[addr_write*`PARA_Y]
								};
					// ======== End: add operation ========

					add_b_tdata <= din;

					clk_count	<= 1;
				end
				else begin
					write_ready	<= 1;

					// ======== Begin: update data add ========
					ram_array[addr_write*`PARA_Y + 0] <= add_re_tdata[0];
					ram_array[addr_write*`PARA_Y + 1] <= add_re_tdata[1];
					ram_array[addr_write*`PARA_Y + 2] <= add_re_tdata[2];
					// ======== End: update data add ========

					clk_count	<= 0;
				end
			end
		end
		else if(ena_para_w == 1) begin // para write
			if (ena_add_write == 0) begin // not add
				// ======== Begin: update feature map data add ========
				ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*0 + 0]	<= para_din[`DATA_WIDTH*1 - 1:`DATA_WIDTH*0];
				ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*0 + 1]	<= para_din[`DATA_WIDTH*2 - 1:`DATA_WIDTH*1];
				ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*0 + 2]	<= para_din[`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];

				ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*1 + 0]	<= para_din[`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
				ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*1 + 1]	<= para_din[`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
				ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*1 + 2]	<= para_din[`DATA_WIDTH*6 - 1:`DATA_WIDTH*5];
				// ======== End: update feature map data add ========
			end
			else if (ena_add_write == 1) begin // add
				if (clk_count == 0) begin
					write_ready <= 0;

					// ======== Begin: add operation ========
					add_a_tdata <= {
									ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*1 + 2],
									ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*1 + 1],
									ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*1 + 0],

									ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*0 + 2],
									ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*0 + 1],
									ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*0 + 0]
								};
					// ======== End: add operation ========

					add_b_tdata <= para_din;

					clk_count	<= 1;
				end
				else begin
					write_ready	<= 1;

					// ======== Begin: update feature map data add ========
					ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*0 + 0]	<= add_re_tdata[0];
					ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*0 + 1]	<= add_re_tdata[1];
					ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*0 + 2]	<= add_re_tdata[2];

					ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*1 + 0]	<= add_re_tdata[3];
					ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*1 + 1]	<= add_re_tdata[4];
					ram_array[addr_para_write + ((fm_out_size+`PARA_X-1)/`PARA_X)*(((fm_out_size+`PARA_Y-1)/`PARA_Y)*`PARA_Y)*1 + 2]	<= add_re_tdata[5];
					// ======== End: update feature map data add ========

					clk_count	<= 0;
				end
			end
		end
	end

	always @(clk) begin
		if (ena_r == 1) begin // conv read
			// ======== Begin: conv read out ========
			dout <= {
						ram_array[addr_read*`PARA_Y+sub_addr_read+2],
						ram_array[addr_read*`PARA_Y+sub_addr_read+1],
						ram_array[addr_read*`PARA_Y+sub_addr_read]
					};
			// ======== End: conv read out ========
		end
		else if(ena_pool_r == 1) begin // pool read
			// ======== Begin: pool read out ========
			dout <= {
						ram_array[addr_pool_read+`POOL_SIZE*2],
						ram_array[addr_pool_read+`POOL_SIZE*1],
						ram_array[addr_pool_read+`POOL_SIZE*0]
					};
			// ======== End: pool read out ========
		end
	end
endmodule