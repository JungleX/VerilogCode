`timescale 1ns / 1ps

`define clk_period 10

`include "CNN_Parameter.vh"

 module ConvParaScaleFloat_tb();

	reg clk;
	reg rst;

    reg op_type;
	reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] input_data;
	reg [`DATA_WIDTH - 1:0] weight;

	reg [`KERNEL_SIZE_WIDTH - 1:0] kernel_size;
	reg [1:0] activation;

	wire result_ready;
	wire [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] result_buffer;

	ConvParaScaleFloat16 conv(
		.clk(clk),
		.rst(rst), // 0: reset; 1: none;

        .op_type(op_type),
		.input_data(input_data),
		.weight(weight),

		.kernel_size(kernel_size),
		.activation(activation),

		.result_ready(result_ready), // 1: rady; 0: not ready;
		.result_buffer(result_buffer)
    );
    
	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0
    	rst <= 1;
        
    	#(`clk_period/2)
    	// reset
    	rst <= 0;            
	    // PARA_X = 3, PARA_Y = 3, kernel size = 5 =============================================
    	// 0
		// result 59 80 56 67 74 66 58 63 70
		// result reverse(5460 53e0 5340 5420 54a0 5430 5300 5500 5360)
    	#`clk_period
        op_type <= 0;
              
        activation <= 0;
		
    	rst <= 1;
    	kernel_size <= 5;
    	input_data[`DATA_WIDTH*`PARA_X*`PARA_Y - 1:0] <= {16'h0000, 16'h4000, 16'h4200, 16'h0000, 16'h3c00, 16'h4000, 16'h0000, 16'h0000, 16'h0000};
      	
    	// 1
    	#`clk_period
    	weight <= 16'h3c00;
        input_data[`DATA_WIDTH*`PARA_X - 1:0] <= {16'h4400, 16'h4200, 16'h0000};
        

    	// 2
    	#`clk_period
    	weight <= 16'h4000;
        input_data[`DATA_WIDTH*`PARA_X - 1:0] <= {16'h4000, 16'h3c00, 16'h0000}; 
        

    	// 3
    	#`clk_period
    	weight <= 16'h3c00;
    	input_data[`DATA_WIDTH*`PARA_Y - 1:0] <= {16'h3c00, 16'h4000, 16'h0000}; 
    	

    	// 4
    	#`clk_period
    	weight <= 16'h0000;
    	input_data[`DATA_WIDTH*`PARA_Y - 1:0] <= {16'h0000, 16'h0000, 16'h0000}; 
    	

    	// 5
    	#`clk_period
    	weight <= 16'h4000;
    	input_data[`DATA_WIDTH*`PARA_Y - 1:0] <= {16'h0000, 16'h4400,16'h3c00};
    	

    	// 6
    	#`clk_period
    	weight <= 16'h4200;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h4000; 
    	

    	// 7
    	#`clk_period
    	weight <= 16'h3c00;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h4200; 
    	

    	// 8
    	#`clk_period
    	weight <= 16'h0000;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h3c00; 
    	

    	// 9
    	#`clk_period
    	weight <= 16'h4200;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h0000; 
    	

    	// 10
    	#`clk_period 
    	weight <= 16'h0000;
    	input_data[`DATA_WIDTH*`PARA_Y - 1:0] <= { 16'h0000, 16'h4200, 16'h4000};
    	

    	// 11
    	#`clk_period
    	weight <= 16'h3c00;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h3c00; 
    	

    	// 12
    	#`clk_period
    	weight <= 16'h3c00;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h4400; 
    	

    	// 13
    	#`clk_period
    	weight <= 16'h4400;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h4000; 
    	

    	// 14
    	#`clk_period
    	weight <= 16'h4000;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h0000; 
    	

    	// 15
    	#`clk_period 
    	weight <= 16'h3c00;
    	input_data[`DATA_WIDTH*`PARA_Y - 1:0] <= {16'h0000, 16'h3c00, 16'h3c00};  
    	

    	// 16
    	#`clk_period
    	weight <= 16'h0000;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h4000; 
    	

    	// 17
    	#`clk_period
    	weight <= 16'h4000;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h3c00; 
    	

    	// 18
    	#`clk_period
    	weight <= 16'h4400;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h4000; 
    	

    	// 19
    	#`clk_period
    	weight <= 16'h3c00;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h0000; 
    	

    	// 20
    	#`clk_period 
    	weight <= 16'h4200;
    	input_data[`DATA_WIDTH*`PARA_Y - 1:0] <= {16'h0000, 16'h4000, 16'h3c00}; 
    	

    	// 21
    	#`clk_period
    	weight <= 16'h4000;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h3c00; 
    	

    	// 22
    	#`clk_period
    	weight <= 16'h3c00;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h4000; 
    	

    	// 23
    	#`clk_period
    	weight <= 16'h3c00;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h3c00; 
    	

    	// 24
    	#`clk_period
    	weight <= 16'h0000;
    	input_data[`DATA_WIDTH - 1:0] <= 16'h0000; 
    	
           
        #`clk_period
        weight <= 16'h4000;
        // PARA_X = 3, PARA_Y = 3, kernel size = 5 =============================================
        // wait for result
        while(result_ready !=1) begin
            #`clk_period
            rst <= 1;
        end
        rst <= 0; 