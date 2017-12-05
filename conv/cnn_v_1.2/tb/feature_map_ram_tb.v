`timescale 1ns / 1ps

`define clk_period 10

`include "CNN_Parameter.vh"

module feature_map_ram_tb();
	reg clk;

    reg [`FM_ADDRA_WIDTH - 1:0] fmr_addra;
    reg [`POOL_SIZE*`PARA_Y*`DATA_WIDTH - 1:0] fmr_dina; 
    reg fmr_ena;
    reg fmr_wea;
    
    reg [`FM_ADDRB_WIDTH - 1:0] fmr_addrb;
    wire [`POOL_SIZE*`PARA_Y*`DATA_WIDTH - 1:0] fmr_doutb;
    reg fmr_enb;

    feature_map_ram fmr(
        .addra(fmr_addra),
        .clka(clk),
        .dina(fmr_dina),
        .ena(fmr_ena),
        .wea(fmr_wea),
    
        .addrb(fmr_addrb),
        .clkb(clk),
        .doutb(fmr_doutb),
        .enb(fmr_enb)
    );

    // get dout
    reg [`POOL_SIZE*`PARA_Y*`DATA_WIDTH - 1:0] get_doutb;
    initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0

    	#(`clk_period/2)
    	// write
    	fmr_addra	<= 0;
    	fmr_dina	<= 16'h4000;
    	fmr_ena		<= 1; // port a enable
    	fmr_wea		<= 1; // write enable

    	// disable port b, the read port
    	fmr_enb	<= 0;

    	#`clk_period
    	// write
    	fmr_addra	<= 1;
    	fmr_dina	<= 16'h4200;
    	fmr_ena		<= 1; // port a enable
    	fmr_wea		<= 1; // write enable

    	// read
    	fmr_addrb	<= 0;
    	fmr_enb		<= 1; // port b enable

    	#`clk_period
    	// write
    	fmr_addra	<= 2;
    	fmr_dina	<= 16'h4600;
    	fmr_ena		<= 1; // port a enable
    	fmr_wea		<= 1; // write enable

    	// read
    	fmr_addrb	<= 1;
    	fmr_enb		<= 1; // port b enable

    	#`clk_period
    	// get the first read date
    	get_doutb 	<= fmr_doutb;

    	// disable a port, the write port
    	fmr_ena	<= 0;

    	// read
    	fmr_addrb	<= 2;
    	fmr_enb		<= 1; // port b enable

    	#`clk_period
    	// get the second read date
    	get_doutb 	<= fmr_doutb;

    	#`clk_period
    	// get the third read date
    	get_doutb 	<= fmr_doutb;

    	#`clk_period
    	// disable port b, the read port
    	fmr_enb	<= 0;
    end
endmodule
