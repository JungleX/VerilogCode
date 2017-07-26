`timescale 1ns / 1ps

`define clk_period 10

module padding_tb();
	reg clk;

	reg inReady;

	reg [10:0] x;
	reg [10:0] y;

	reg [63:0] baseAddr;

	reg [10:0] fmX;
	reg [10:0] fmY;

	reg [3:0] paddingUp;
	reg [3:0] paddingDown;
	reg [3:0] paddingLeft;
	reg [3:0] paddingRight;

	wire [63:0] realAddr;
	wire [1:0] realAddrEn; // 0: false value; 1: false realAddr, padding location; 2: true realAddr, feature map location
	wire outReady;

	padding my_paddding(
		.inReady(inReady),

		.x(x),
		.y(y),

		.baseAddr(baseAddr),

		.fmX(fmX),
		.fmY(fmY),

		.paddingUp(paddingUp),
		.paddingDown(paddingDown),
		.paddingLeft(paddingLeft),
		.paddingRight(paddingRight),

		.realAddr(realAddr),
		.realAddrEn(realAddrEn), // 0: false value; 1: false realAddr, padding location; 2: true realAddr, feature map location
		.outReady(outReady)
    );

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;
    
    initial begin
    	#(`clk_period / 2)
    	x = 3;
    	y = 2;

    	baseAddr = 4;

    	fmX = 5;
    	fmY = 5;

    	paddingUp = 2;
    	paddingDown = 2;
    	paddingLeft = 2;
    	paddingRight = 2;

    	inReady = 1;

    	#`clk_period
    	x = 2;
    	y = 4;

    	inReady = 1;

    	#`clk_period
    	x = 4;
    	y = 5;

    	inReady = 1;
    end

endmodule
