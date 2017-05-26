`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/26 15:43:09
// Design Name: 
// Module Name: floating_point_multiply_tb
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

`define clk_period 10

module floating_point_multiply_tb();
	reg clk;

	reg[15:0] mul_a_data;
    reg mul_a_valid;
    
    reg[15:0] mul_b_data;
    reg mul_b_valid;
    
    wire[15 :0] mul_re_data;
    wire mul_re_valid;

	floating_point_multiply fpm(
		.s_axis_a_tvalid(mul_a_valid),
    	.s_axis_a_tdata(mul_a_data),

    	.s_axis_b_tvalid(mul_b_valid),
    	.s_axis_b_tdata(mul_b_data),

    	.m_axis_result_tvalid(mul_re_valid),
    	.m_axis_result_tdata(mul_re_data)
		);

    initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
		#0
	    mul_a_valid = 1;
	    mul_a_data = 16'b0000000000000000; // 0
	    mul_b_valid = 1;
	    mul_b_data = 16'b1100101001000000; //-12.5

	    #`clk_period
	    mul_a_valid = 1;
	    mul_a_data = 16'b1100101001000000; //-12.5
	    mul_b_valid = 1;
	    mul_b_data = 16'b0000000000000000; // 0

	    #`clk_period
	    mul_a_valid = 1;
	    mul_a_data = 16'b0100101001000000; // 12.5
	    mul_b_valid = 1;
	    mul_b_data = 16'b0000000000000000; // 0
	    
	    #`clk_period
	    mul_a_valid = 1;
	    mul_a_data = 16'b0100100100010000; // 10.125
	    mul_b_valid = 1;
	    mul_b_data = 16'b0100101001000000; // 12.5
	    
	    #`clk_period
	    mul_a_valid = 1;
	    mul_a_data = 16'b1100101001000000; //-12.5
	    mul_b_valid = 1;
	    mul_b_data = 16'b0011110000000000; // 1

	    #`clk_period
	    mul_a_valid = 1;
	    mul_a_data = 16'b1100101001000000; //-12.5
	    mul_b_valid = 1;
	    mul_b_data = 16'b1011110000000000; // -1
    end
endmodule
