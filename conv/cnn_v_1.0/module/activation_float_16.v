`timescale 1ns / 1ps

module activation_float_16(
    input clk,
    
    input [3:0] type,
    input [15:0] inputData,
    
    output reg [15:0] outputData
    );

    parameter   NONE    = 4'd0,
                ReLU    = 4'd1,
                sigmoid = 4'd2,
                tanh    = 4'd3;

    reg [15:0] input_data = 0;

    reg com_a_valid;
    reg [15:0] com_a_tdata;

    reg com_b_valid;
    reg [15:0] com_b_tdata;

    wire com_re_valid;
    wire [7:0] com_re_tdata;

    floating_point_compare compare(
        .s_axis_a_tvalid(com_a_valid),
        .s_axis_a_tdata(com_a_tdata),

        .s_axis_b_tvalid(com_b_valid),
        .s_axis_b_tdata(com_b_tdata),

        .m_axis_result_tvalid(com_re_valid),
        .m_axis_result_tdata(com_re_tdata)
    );

    reg exp_a_tvalid;
    reg [15:0] exp_a_tdata;

    wire exp_re_tvalid;
    wire [15:0] exp_re_tdata;

    floating_point_exponential exp(
    	.s_axis_a_tvalid(exp_a_tvalid),
    	.s_axis_a_tdata(exp_a_tdata),

    	.m_axis_result_tvalid(exp_re_tvalid),
    	.m_axis_result_tdata(exp_re_tdata)
    );
    
    reg add_a_tvalid;
    reg [15:0] add_a_tdata;

    reg add_b_tvalid;
    reg [15:0] add_b_tdata;

    wire add_re_tvalid;
    wire [15:0] add_re_tdata;

    floating_point_add add(
        .s_axis_a_tvalid(add_a_tvalid),
        .s_axis_a_tdata(add_a_tdata),

        .s_axis_b_tvalid(add_b_tvalid),
        .s_axis_b_tdata(add_b_tdata),

        .m_axis_result_tvalid(add_re_tvalid),
        .m_axis_result_tdata(add_re_tdata)
    );

    reg sub_a_tvalid;
    reg [15:0] sub_a_tdata;

    reg sub_b_tvalid;
    reg [15:0] sub_b_tdata;

    wire sub_re_tvalid;
    wire [15:0] sub_re_tdata;

    floating_point_subtract subtract(
    	.s_axis_a_tvalid(sub_a_tvalid),
    	.s_axis_a_tdata(sub_a_tdata),

    	.s_axis_b_tvalid(sub_b_tvalid),
    	.s_axis_b_tdata(sub_b_tdata),

    	.m_axis_result_tvalid(sub_re_tvalid),
    	.m_axis_result_tdata(sub_re_tdata)
	);

    reg div_a_tvalid;
    reg [15:0] div_a_tdata;

    reg div_b_tvalid;
    reg [15:0] div_b_tdata;

    wire div_re_tvalid;
    wire [15:0] div_re_tdata;

    floating_point_divide divide(
    	.s_axis_a_tvalid(div_a_tvalid),
    	.s_axis_a_tdata(div_a_tdata),

    	.s_axis_b_tvalid(div_b_tvalid),
    	.s_axis_b_tdata(div_b_tdata),

    	.m_axis_result_tvalid(div_re_tvalid),
    	.m_axis_result_tdata(div_re_tdata)
    );

    reg [3:0] count_clk = 0;
    reg ena;

    always @(posedge clk) begin
    	
    	if (input_data != inputData) begin
    		count_clk = 0;

    		input_data = inputData;
    		ena = 1;
    	end

    	if (ena == 1) begin
    		case(type)
	    		NONE:
	    			begin
	    				outputData = input_data;
	    			end

	    		ReLU:
	    			begin
	    				// clk 1
	    				if (count_clk == 0) begin
	    					com_a_valid = 1;
	    					com_a_tdata = input_data;

	    					com_b_valid = 1;
	    					com_b_tdata = 16'h0000;

	    					count_clk = 1;
	    				end
	    				// clk 2
	    				else begin
	    					outputData =  com_re_tdata[0] == 1 ? input_data : 0;

	    					count_clk = 0;

	    					ena = 0;
	    				end
	    			end

	    		sigmoid:
	    			begin
	    				// clk 1
	    				if (count_clk == 0) begin
	    					sub_a_tvalid = 1;
	    					sub_a_tdata = 16'h0000;

	    					sub_b_tvalid = 1;
	    					sub_b_tdata = input_data;

	    					count_clk = 1;
	    				end
	    				// clk 2
	    				else if (count_clk == 1) begin
	    					exp_a_tvalid = 1;
	    					exp_a_tdata = sub_re_tdata;

	    					count_clk = 2;
	    				end
	    				// clk 3
	    				else if (count_clk == 2) begin
	    					add_a_tvalid = 1;
	    					add_a_tdata = 16'h3c00; // 1

	    					add_b_tvalid = 1;
	    					add_b_tdata = exp_re_tdata;
	    			
	    					count_clk = 3;
	    				end
	    				// clk 4
	    				else if (count_clk == 3) begin
	    					div_a_tvalid = 1;
	    					div_a_tdata = 16'h3c00; // 1

	    					div_b_tvalid = 1;
	    					div_b_tdata = add_re_tdata;

	    					count_clk = 4;
	    				end
	    				// clk 5
	    				else begin
	    					outputData = div_re_tdata;

	    					count_clk = 0;

	    					ena = 0;
	    				end
	    			end

	    		tanh:
	    			begin
	    				// clk 1
	    				if (count_clk == 0) begin
	    					add_a_tvalid = 1;
	    					add_a_tdata = input_data;

	    					add_b_tvalid = 1;
	    					add_b_tdata = input_data;

	    					count_clk = 1;
	    				end
	    				// clk 2
	    				else if (count_clk == 1) begin
	    					sub_a_tvalid = 1;
	    					sub_a_tdata = 16'h0000;

	    					sub_b_tvalid = 1;
	    					sub_b_tdata = add_re_tdata;

	    					count_clk = 2;
	    				end
	    				// clk 3
	    				else if (count_clk == 2) begin
	    					exp_a_tvalid = 1;
	    					exp_a_tdata = sub_re_tdata;

	    					count_clk = 3;
	    				end
	    				// clk 4
	    				else if (count_clk == 3) begin
	    					add_a_tvalid = 1;
	    					add_a_tdata = 16'h3c00;

	    					add_b_tvalid = 1;
	    					add_b_tdata = exp_re_tdata;

	    					sub_a_tvalid = 1;
	    					sub_a_tdata = 16'h3c00;

	    					sub_b_tvalid = 1;
	    					sub_b_tdata = exp_re_tdata;

	    					count_clk = 4;
	    				end
	    				// clk 5
	    				else if (count_clk == 4) begin
	    					div_a_tvalid = 1;
	    					div_a_tdata = sub_re_tdata;

	    					div_b_tvalid = 1;
	    					div_b_tdata = add_re_tdata;

	    					count_clk = 5;
	    				end
	    				// clk 6
	    				else if (count_clk == 5) begin
	    					outputData = div_re_tdata;

	    					count_clk = 0;

	    					ena = 0;
	    				end
	    			end
	    	endcase
    	end
    	
    end
endmodule
