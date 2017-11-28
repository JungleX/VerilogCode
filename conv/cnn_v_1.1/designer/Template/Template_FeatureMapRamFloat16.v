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
	input [1:0] read_type, // 0: conv read; 1: pool read; 2: fc read;
	input [`READ_ADDR_WIDTH - 1:0] addr_read,
	input [`READ_ADDR_WIDTH - 1:0] sub_addr_read,

	output reg write_ready,
	output reg [`PARA_Y*`DATA_WIDTH - 1:0] dout
    );

	reg [`DATA_WIDTH - 1:0] ram_array [0:`FM_RAM_MAX - 1];

	reg [`CLK_NUM_WIDTH - 1:0] clk_count;

	reg [`DATA_WIDTH - 1:0] para_din_buffer[`PARA_Y*(`PARA_KERNEL-1) - 1:0];

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
		write_ready <= 0;
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
				// ======== End: update data not add ========
			end
			else if (ena_add_write == 1) begin // add
				if (clk_count == 0) begin
					write_ready <= 0;

					// ======== Begin: add operation ========
					add_a_tdata <= {
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
		else if(ena_para_w == 1) begin // para write
			if (ena_add_write == 1) begin // add, for conv layer
				if (clk_count <(`PARA_KERNEL*2) && write_ready == 0) begin
					write_ready <= 0;

					if (clk_count == 0) begin
						// ======== Begin: add operation ========
						add_a_tdata <= {
									};
						// ======== End: add operation ========

						add_b_tdata <= para_din[`DATA_WIDTH*`PARA_Y - 1:0];

						// ======== Begin: data buffer ========
						// ======== End: data buffer ========
					end
					else if ((clk_count-((clk_count/2)*2)) == 0) begin
						// ======== Begin: add operation ========
						add_a_tdata <= {
									};

						add_b_tdata <= {
									};
						// ======== End: add operation ========
					end
					else begin
						// ======== Begin: update feature map data add ========
						// ======== End: update feature map data add ========
					end

					if (clk_count == (`PARA_KERNEL*2-1)) begin
						write_ready	<= 1;
						clk_count	<= 0;
					end
					else begin
						clk_count <= clk_count + 1;
					end
				end
			end
			else if(ena_add_write == 0) begin // not add, for fc layer
				if (clk_count <`PARA_KERNEL && write_ready == 0) begin
					if (clk_count == 0) begin
						// ======== Begin: data write ========
						// ======== End: data write ========

						// ======== Begin: data buffer ========
						// ======== End: data buffer ========
					end
					else begin
						// ======== Begin: data write ========
						// ======== End: data write ========
					end

					if (clk_count == (`PARA_KERNEL-1)) begin
						write_ready	<= 1;
						clk_count	<= 0;
					end
					else begin
						clk_count <= clk_count + 1;
					end
				end
			end
		end
		else begin
			write_ready	<= 0;
			clk_count	<= 0;
		end
	end

	always @(clk) begin
		if (ena_r == 1) begin // conv read
			case(read_type)
				0:
					begin
						// ======== Begin: conv read out ========
						dout <= {
								};
						// ======== End: conv read out ========
					end
				1:
					begin
						// ======== Begin: pool read out ========
						dout <= {
								};
						// ======== End: pool read out ========
					end
				2:
					begin
						// ======== Begin: fc read out ========
						dout <= {
								};
						// ======== End: fc read out ========
					end
			endcase
		end
	end
endmodule