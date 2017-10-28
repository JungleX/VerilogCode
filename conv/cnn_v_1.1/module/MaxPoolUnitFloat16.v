`timescale 1ns / 1ps

`define DATA_WIDTH		16 // 16 bits float
`define CLK_NUM_WIDTH	8
`define COM_RET_WIDTH	8

// need data_num + 2 clks to get result
// wait for 2 clks after submit the last number
module MaxPoolUnitFloat16(
	input clk,
	input rst, // 0: reset; 1: none;

	input [`DATA_WIDTH - 1:0] cmp_data,

	input [`CLK_NUM_WIDTH - 1:0] data_num,

	output reg result_ready, // 1: ready; 0: not ready;
	output reg [`DATA_WIDTH - 1:0] max_pool_result
);
	reg [`CLK_NUM_WIDTH - 1:0] clk_count;

	reg [`DATA_WIDTH - 1:0] max_data;
	reg [`DATA_WIDTH - 1:0] cmp_b;

	reg com_a_tvalid;
	reg com_b_tvalid;

	wire com_re_tvalid;
	wire [`COM_RET_WIDTH - 1:0] com_re_tdata;

	// compare
    floating_point_compare compare_unit(
    	.s_axis_a_tvalid(com_a_tvalid),
    	.s_axis_a_tdata(max_data),

    	.s_axis_b_tvalid(com_b_tvalid),
    	.s_axis_b_tdata(cmp_b),

    	.m_axis_result_tvalid(com_re_tvalid),
    	.m_axis_result_tdata(com_re_tdata)
    );

    always @(posedge clk or negedge rst) begin
		if (!rst) begin
			// reset
			clk_count		<= 0;
			result_ready	<= 0;

			com_a_tvalid	<= 0;
			com_b_tvalid	<= 0;

			max_data		<= 0;
		end
		else begin
			if (clk_count == (data_num + 1)) begin
				clk_count		<= 0;

				result_ready	<= 1;
				if (com_re_tdata[0:0] == 0) begin
					max_pool_result	<= cmp_b;
				end
				else begin
					max_pool_result	<= max_data;
				end

				com_a_tvalid	<= 0;
				com_b_tvalid	<= 0;

				max_data		<= 0;
			end
			else begin
				result_ready	<= 0;
				com_a_tvalid	<= 1;
				com_b_tvalid	<= 1;

				clk_count <= clk_count + 1;
			end

			if (clk_count == 0) begin
				max_data	<= cmp_data;
				cmp_b		<= cmp_data;
			end
			else begin
				if (com_re_tdata[0:0] == 0) begin
					max_data <= cmp_b;
				end

				cmp_b		<= cmp_data;
			end

		end
	end

endmodule
