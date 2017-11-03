`timescale 1ns / 1ps

`include "CNN_Parameter.vh"

module AvgPoolUnitFloat16(
	input clk,
	input rst, // 0: reset; 1: none;
	input [`DATA_WIDTH - 1:0] avg_input_data,

	input [`CLK_NUM_WIDTH - 1:0] data_num,

	output reg result_ready, // 1: ready; 0: not ready;
	output reg [`DATA_WIDTH - 1:0] avg_pool_result
    );

 	reg [`DATA_WIDTH - 1:0] clk_count;

 	// addition
 	reg [`DATA_WIDTH - 1:0] add_data;
 	wire [`DATA_WIDTH - 1:0] add_re_tdata;

 	reg add_a_tvalid;
 	reg add_b_tvalid;

 	wire add_re_tvalid;

    floating_point_add add(
        .s_axis_a_tvalid(add_a_tvalid),
        .s_axis_a_tdata(add_data),

        .s_axis_b_tvalid(add_b_tvalid),
        .s_axis_b_tdata(avg_input_data),

        .m_axis_result_tvalid(add_re_tvalid),
        .m_axis_result_tdata(add_re_tdata)
        );

    // addition 
    // data number
    reg [`DATA_WIDTH - 1:0] add_data_num;
    reg [`DATA_WIDTH - 1:0] add_one; 

    reg add_a_num_tvalid;
    reg add_b_num_tvalid;

    wire add_re_num_tvalid;
    wire [`DATA_WIDTH - 1:0] add_re_num_tdata;

    floating_point_add add_num(
        .s_axis_a_tvalid(add_a_num_tvalid),
        .s_axis_a_tdata(add_data_num),

        .s_axis_b_tvalid(add_b_num_tvalid),
        .s_axis_b_tdata(add_one),

        .m_axis_result_tvalid(add_re_num_tvalid),
        .m_axis_result_tdata(add_re_num_tdata)
        );

    // division
    reg [`DATA_WIDTH - 1:0] div_a;
    reg [`DATA_WIDTH - 1:0] div_b;

    reg div_a_tvalid;
    reg div_b_tvalid;

    wire div_re_tvalid;
    wire [`DATA_WIDTH - 1:0] div_re_tdata;

    floating_point_divide divide(
    	.s_axis_a_tvalid(div_a_tvalid),
    	.s_axis_a_tdata(div_a),

    	.s_axis_b_tvalid(div_b_tvalid),
    	.s_axis_b_tdata(div_b),

    	.m_axis_result_tvalid(div_re_tvalid),
    	.m_axis_result_tdata(div_re_tdata)
    );

    always @(posedge clk or negedge rst) begin
		if (!rst) begin
			// reset
			clk_count		<= 0;
			result_ready	<= 0;

			add_a_tvalid	<= 0;
			add_b_tvalid	<= 0;

			add_data		<= 0;

			add_data_num 	<= 16'h0000;
			add_one			<= 16'h3c00;

			add_a_num_tvalid<= 0;
			add_b_num_tvalid<= 0;

			div_a_tvalid	<= 0;
			div_b_tvalid	<= 0;

		end
		else begin
			if (clk_count == (data_num + 2)) begin
				clk_count		<= 0;

				add_data_num 	<= 16'h0000;
				add_one			<= 16'h3c00;

				div_a_tvalid	<= 0;
				div_b_tvalid	<= 0;

				result_ready	<= 1;
				avg_pool_result	<= div_re_tdata;
			end
			else begin
				result_ready	<= 0;

				add_a_tvalid	<= 1;
				add_b_tvalid	<= 1;

				if (clk_count == 0) begin
					add_data	<= 0;
				end
				else begin
					add_data	<= add_re_tdata;
				end

				if (clk_count == (data_num - 1)) begin
					div_b			<= add_re_num_tdata;

					add_data_num 	<= 16'h0000;
					add_one			<= 16'h3c00;
				end

				if (clk_count == (data_num + 1)) begin
					div_a			<= add_data;

					div_a_tvalid	<= 1;
					div_b_tvalid	<= 1;

					add_a_tvalid	<= 0;
					add_b_tvalid	<= 0;

					add_data		<= 0;
				end

				add_data_num	<= add_re_num_tdata;

				clk_count		<= clk_count + 1;

				if (clk_count < data_num) begin
					add_a_num_tvalid<= 1;
					add_b_num_tvalid<= 1;
				end
				else begin
					add_a_num_tvalid<= 0;
					add_b_num_tvalid<= 0;
				end
			end
		end
	end
endmodule