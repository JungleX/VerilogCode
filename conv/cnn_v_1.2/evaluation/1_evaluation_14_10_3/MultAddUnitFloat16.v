`timescale 1ns / 1ps

`include "CNN_Parameter.vh"

module MultAddUnitFloat16(
	input clk,
	input rst, // 0: reset; 1: none;

	input [`DATA_WIDTH - 1:0] mult_a,
	input [`DATA_WIDTH - 1:0] mult_b,

	input [`CLK_NUM_WIDTH - 1:0] clk_num, // set the clk number, after clk_count clks, the output is ready

	output reg result_ready, // 1: ready; 0: not ready;
	output reg [`DATA_WIDTH - 1:0] mult_add_result
    );

	reg [`CLK_NUM_WIDTH - 1:0] clk_count;
	reg [`CLK_NUM_WIDTH - 1:0] cur_clk_num;

	reg [`DATA_WIDTH - 1:0] sum;

	reg mult_a_tvalid;
	reg mult_b_tvalid;
	wire [`DATA_WIDTH - 1:0] mult_re_tdata;
	wire mult_re_tvalid;

	reg add_a_tvalid;
	reg add_b_tvalid;
	wire [`DATA_WIDTH - 1:0] add_re_tdata;
	wire add_re_tvalid;

	// multiply
    floating_point_multiply mult(
        .s_axis_a_tvalid(mult_a_tvalid),
        .s_axis_a_tdata(mult_a),

        .s_axis_b_tvalid(mult_b_tvalid),
		.s_axis_b_tdata(mult_b),

        .m_axis_result_tvalid(mult_re_tvalid),
        .m_axis_result_tdata(mult_re_tdata)
        );

    // addition
    floating_point_add add(
        .s_axis_a_tvalid(add_a_tvalid),
        .s_axis_a_tdata(mult_re_tdata),

        .s_axis_b_tvalid(add_b_tvalid),
        .s_axis_b_tdata(sum),

        .m_axis_result_tvalid(add_re_tvalid),
        .m_axis_result_tdata(add_re_tdata)
        );

	always @(posedge clk or negedge rst) begin
		if (!rst) begin
			// reset
			clk_count		<= 0;
			cur_clk_num		<= 0;
			sum				<= 0;
			result_ready	<= 0;
			mult_add_result	<= 0;

			mult_a_tvalid	<= 0;
			mult_b_tvalid	<= 0;

			add_a_tvalid	<= 0;
			add_b_tvalid	<= 0;
		end
		else begin
			if(clk_count == (cur_clk_num-1)) begin			    
				clk_count		<= 0;
				cur_clk_num		<= clk_num;
				mult_add_result	<= add_re_tdata;
				sum				<= 0;
				result_ready	<= 1;

				mult_a_tvalid	<= 0;
				mult_b_tvalid	<= 0;

				add_a_tvalid	<= 0;
				add_b_tvalid	<= 0;
				add_b_tvalid	<= 0;
			end
			else begin
				cur_clk_num		<= clk_num;

				result_ready	<= 0;
				clk_count		<= clk_count + 1;

				// clk 0
				mult_a_tvalid	<= 1;
				mult_b_tvalid	<= 1;
				
                
				// clk 1
				add_a_tvalid	<= 1;
				add_b_tvalid	<= 1;
				// clk 2
			
				sum	<= add_re_tdata;
			end
		end
	end

endmodule