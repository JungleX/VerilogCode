`timescale 1ns / 1ps

`define clk_period 10

module activation_float_16_tb();
	
	parameter  NONE   = 4'd0,
                ReLU    = 4'd1, // 2 clk
                sigmoid = 4'd2,
                tanh    = 4'd3;

    reg clk;

	reg [3:0] type;

	reg [15:0] inputData;
	reg inputReady;

	wire [15:0] outputData;
	wire outputReady;

	activation_float_16 activation(
	    .clk(clk),
	    
	    .type(type),
	    .inputData(inputData),
	    .inputReady(inputReady),
	    
	    .outputData(outputData),
	    .outputReady(outputReady)
    );

    initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;
    
    initial begin
    	#(`clk_period / 2)
    	type = NONE;
    	inputData = 16'h4000; // 2
    	inputReady = 1;

    	#`clk_period
    	type = NONE;
    	inputData = 16'h4700; // 7
    	inputReady = 1;


    	#`clk_period
    	type = ReLU;
    	inputData = 16'h4880; // 9
    	inputReady = 1;

    	#(`clk_period * 2)
    	type = ReLU;
    	inputData = 16'hc200; // -3 
    	inputReady = 1;
    	// no result

    	#`clk_period
    	type = ReLU;
    	inputData = 16'h4000; // 2
    	inputReady = 1;


    	#(`clk_period * 2)
    	type = sigmoid;
    	inputData = 16'h3c00; // 1
    	inputReady = 1;
    	// no result

    	#(`clk_period * 2)
    	type = sigmoid;
    	inputData = 16'h4000; // 2
    	inputReady = 1;


    	# (`clk_period * 6)
    	type = tanh;
    	inputData = 16'h3c00; // 3
    	inputReady = 1;
    	// no result

    	# (`clk_period * 3)
    	type = tanh;
    	inputData = 16'h4200; // 3
    	inputReady = 1;
    end

    reg [15:0] output_data;

    always @(posedge clk) begin
    	if (outputReady == 1) begin
    		output_data = outputData;
    	end
    end

endmodule
