`timescale 1ns / 1ps

`define clk_period 10

`include "CNN_Parameter.vh"

module weight_ram_tb();
	reg clk;

	reg [`WEIGHT_ADDRA_WIDTH - 1:0] wr_addra;
    reg [`PARA_Y*`DATA_WIDTH - 1:0] wr_dina; 
    reg wr_ena;
    reg wr_wea;

    reg [`WEIGHT_ADDRB_WIDTH - 1:0] wr_addrb;
    wire [`PARA_Y*`DATA_WIDTH - 1:0] wr_doutb;
    reg wr_enb;

    weight_ram wr(
		.addra(wr_addra),
		.clka(clk),
		.dina(wr_dina),
		.ena(wr_ena),
		.wea(wr_wea),
		
		.addrb(wr_addrb),
		.clkb(clk),
		.doutb(wr_doutb),
		.enb(wr_enb)
    );

    // get dout
    reg [`PARA_Y*`DATA_WIDTH - 1:0] get_doutb;
    initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0

    	#(`clk_period/2)
    	// write
    	wr_addra	<= 0;
    	wr_dina		<= 16'h3c00;
    	wr_ena		<= 1; // port a enable
    	wr_wea		<= 1; // write enable

    	// disable port b, the read port
    	wr_enb	<= 0;

    	#`clk_period
    	// write
    	wr_addra	<= 1;
    	wr_dina		<= 16'h4200;
    	wr_ena		<= 1; // port a enable
    	wr_wea		<= 1; // write enable

    	// read
    	wr_addrb	<= 0;
    	wr_enb		<= 1; // port b enable

    	#`clk_period
    	// write
    	wr_addra	<= 2;
    	wr_dina		<= 16'h4400;
    	wr_ena		<= 1; // port a enable
    	wr_wea		<= 1; // write enable

    	// read
    	wr_addrb	<= 1;
    	wr_enb		<= 1; // port b enable

    	#`clk_period
    	// get the first read date
    	get_doutb 	<= wr_doutb;

    	// disable a port, the write port
    	wr_ena	<= 0;

    	// read
    	wr_addrb	<= 2;
    	wr_enb		<= 1; // port b enable

    	#`clk_period
    	// get the second read date
    	get_doutb 	<= wr_doutb;

    	#`clk_period
    	// get the third read date
    	get_doutb 	<= wr_doutb;

    	#`clk_period
    	// disable port b, the read port
    	wr_enb	<= 0;
    end
endmodule
