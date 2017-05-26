`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/26 21:05:22
// Design Name: 
// Module Name: floating_point_add_tb
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

module floating_point_add_tb();
	reg clk;

	reg[15:0] add_a_data;
    reg add_a_valid;
    
    reg[15:0] add_b_data;
    reg add_b_valid;
    
    wire[15 :0] add_re_data;
    wire add_re_valid;

    floating_point_add fpa(
    	.s_axis_a_tvalid(add_a_valid),
    	.s_axis_a_tdata(add_a_data),

    	.s_axis_b_tvalid(add_b_valid),
    	.s_axis_b_tdata(add_b_data),

    	.m_axis_result_tvalid(add_re_valid),
    	.m_axis_result_tdata(add_re_data)
    	);

    initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
		#0
		add_a_valid = 1;
	    add_a_data = 16'b0000000000000000; // 0
	    add_b_valid = 1;
	    add_b_data = 16'b1100101001000000; // -12.5

	    #`clk_period
	    add_a_valid = 1;
	    add_a_data = 16'b1100101001000000; // -12.5
	    add_b_valid = 1;
	    add_b_data = 16'b0000000000000000; // 0

	    #`clk_period
	    add_a_valid = 1;
	    add_a_data = 16'b0100101001000000; // 12.5
	    add_b_valid = 1;
	    add_b_data = 16'b0000000000000000; // 0
	    
	    #`clk_period
	    add_a_valid = 1;
	    add_a_data = 16'b0100100100010000; // 10.125
	    add_b_valid = 1;
	    add_b_data = 16'b0100101001000000; // 12.5
	    
	    #`clk_period
	    add_a_valid = 1;
	    add_a_data = 16'b1100101001000000; // -12.5
	    add_b_valid = 1;
	    add_b_data = 16'b0011110000000000; // 1

	    #`clk_period
	    add_a_valid = 1;
	    add_a_data = 16'b1100101001000000; // -12.5
	    add_b_valid = 1;
	    add_b_data = 16'b1011110000000000; // -1
	end
endmodule
