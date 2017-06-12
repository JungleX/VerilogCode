`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/06/12 10:17:23
// Design Name: 
// Module Name: mult_add
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "alexnet_parameters.vh"

module mult_add(
	input clk,
	input multAddRst,

	input [`DATA_WIDTH - 1:0] data,
	input [`DATA_WIDTH - 1:0] weight,
	input [`DATA_WIDTH - 1:0] sum,

	output reg [`DATA_WIDTH - 1:0] multAddResult
	);

	reg mul_a_valid;
    reg mul_b_valid;
    wire mul_re_valid;

	reg [`DATA_WIDTH - 1:0] multA;
	reg [`DATA_WIDTH - 1:0] multB;
	wire [`DATA_WIDTH - 1:0] multResult;

	reg add_a_valid;
    reg add_b_valid;
    wire add_re_valid;

	reg [`DATA_WIDTH - 1:0] addA;
	reg [`DATA_WIDTH - 1:0] addB;
	wire [`DATA_WIDTH - 1:0] addResult;

	// multiply
    floating_point_multiply mult0(
        .s_axis_a_tvalid(mul_a_valid),
        .s_axis_a_tdata(multA),

        .s_axis_b_tvalid(mul_b_valid),
        .s_axis_b_tdata(multB),

        .m_axis_result_tvalid(mul_re_valid),
        .m_axis_result_tdata(multResult)
        );

    // addition
    floating_point_add add0(
        .s_axis_a_tvalid(add_a_valid),
        .s_axis_a_tdata(addA),

        .s_axis_b_tvalid(add_b_valid),
        .s_axis_b_tdata(multResult),

        .m_axis_result_tvalid(add_re_valid),
        .m_axis_result_tdata(addResult)
        );

    always @(posedge clk or posedge multAddRst) begin
    	if(!multAddRst) begin // reset
    		multAddResult <= 0;
    		mul_a_valid <= 0;
    		mul_b_valid <= 0;
    		add_a_valid <= 0;
    		add_b_valid <= 0;
    	end
    end

    always @(posedge clk) begin
    	if(multAddRst) begin
    		mul_a_valid <= 1;
    		mul_b_valid <= 1;

    		add_a_valid <= 1;
    		add_b_valid <= 1;

    		// clk 1 multiply
    		multA <= data;
    		multB <= weight;

    		// clk 2 addition
    		addA <= sum;
    		addB <= multResult;

    		// clk 3 
    		multAddResult <= addResult;

//    		if(mul_re_valid == 1) begin
//    			addB <= multResult;

//    			if (add_re_valid == 1) begin
//    				multAddResult <= addResult;
//    			end
//    		end
    		
    	end
    end

endmodule
