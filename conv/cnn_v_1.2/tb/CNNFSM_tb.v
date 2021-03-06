`timescale 1ns / 1ps


`define clk_period 10

`include "CNN_Parameter.vh"



module CNNFSM_tb();

	reg clk;
    reg rst;
    reg transmission_start;
     
    wire stop;
    wire [7:0] led;

	CNNFSM fsm(
	     //input clk_p,
	     //input clk_n,
	    .clk(clk),
	    .rst(rst),
	    .transmission_start(transmission_start),

        .stop(stop),
        .led(led)
	    );

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0

    	#(`clk_period/2)
    	// reset
    	rst <= 0;
    	transmission_start <= 0;

    	#`clk_period
    	rst <= 1;
    	transmission_start <= 0;
	    
	    #`clk_period
	    transmission_start <= 1;
	    
	    #(`clk_period*1000)
	    rst <= 0;
                transmission_start <= 0;
        
                #`clk_period
                rst <= 1;
                transmission_start <= 0;
                
                #(`clk_period*20)
                transmission_start <= 1;
	    
    end

endmodule
