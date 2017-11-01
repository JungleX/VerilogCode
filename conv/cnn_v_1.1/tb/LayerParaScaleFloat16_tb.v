`timescale 1ns / 1ps

`define clk_period 10

`define DATA_WIDTH		16  // 16 bits float

`define PARA_KERNEL		2 // kernel number

// conv
`define PARA_X			3	// MAC group number
`define PARA_Y			3	// MAC number of each MAC group
`define KERNEL_SIZE_WIDTH	6

// pool
`define PARA_POOL_Y		3	
`define POOL_SIZE_WIDTH	6

// feature map ram
`define READ_ADDR_WIDTH		3 
`define WRITE_ADDR_WIDTH	3
`define RAM_NUM_WIDTH		4

// weight ram
`define KERNEL_SIZE_MAX			5
`define WEIGHT_RAM_MAX			100 
`define WEIGHT_READ_ADDR_WIDTH	10  
`define WEIGHT_WRITE_ADDR_WIDTH	5 

`define WRITE_ADDR_WIDTH	3

module LayerParaScaleFloat16_tb();

	reg clk;
	reg rst;

	reg [1:0] layer_type;
	reg [`KERNEL_SIZE_WIDTH - 1:0] kernel_size;
	reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] init_fm_data;
	reg [`WRITE_ADDR_WIDTH - 1:0] write_fm_data_addr;

	reg init_fm_data_done;

	reg [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_data;
	reg [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] write_weight_data_addr;
	reg weight_data_done; // weight data transmission, 0: not ready; 1: ready

	wire update_weight_ram; // 0: not update; 1: update
	wire update_weight_ram_addr;

	wire init_fm_ram_ready;
	wire init_weight_ram_ready;
	wire layer_ready;

	LayerParaScaleFloat16 cnn(
		.clk(clk),
		.rst(rst),

		.layer_type(layer_type), // 0: prepare init feature map data; 1:conv; 2:pool; 3:fc;
		.kernel_size(kernel_size),

		.init_fm_data(init_fm_data),
		.write_fm_data_addr(write_fm_data_addr),
		.init_fm_data_done(init_fm_data_done), // 0: not ready; 1: ready

		.weight_data(weight_data),
		.write_weight_data_addr(write_weight_data_addr),
		.weight_data_done(weight_data_done), // weight data transmission, 0: not ready; 1: ready

		.update_weight_ram(update_weight_ram), // 0: not update; 1: update
		.update_weight_ram_addr(update_weight_ram_addr),

		.init_fm_ram_ready(init_fm_ram_ready), // 0: not ready; 1: ready
		.init_weight_ram_ready(init_weight_ram_ready), // 0: not ready; 1: ready
		.layer_ready(layer_ready)
    );

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0

    	#(`clk_period/2)
    	// reset
    	rst = 0;

    	#`clk_period
    	rst = 1;

    	layer_type = 0;
    	init_fm_data = {16'h4200, 16'h4000, 16'h0000,
    					16'h4000, 16'h3c00, 16'h0000,
    					16'h0000, 16'h0000, 16'h0000};
    	write_fm_data_addr = 0;
    	init_fm_data_done = 0;

    	weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*0] = {16'h3c00, 16'h4000, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h3c00};
    	weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*2 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1] = {16'h3c00, 16'h4000, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h4000};
    	write_weight_data_addr = 0;
    	weight_data_done = 0;

    	#`clk_period
    	layer_type = 0;
    	init_fm_data = {16'h0000, 16'h4000, 16'h4400,
    					16'h0000, 16'h3c00, 16'h4200,
    					16'h0000, 16'h0000, 16'h0000};
    	write_fm_data_addr = 1;
    	init_fm_data_done = 0;

    	weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*0] = {16'h0000, 16'h4200, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h3c00};
    	weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*2 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1] = {16'h0000, 16'h4200, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h4200};
    	write_weight_data_addr = 1;
    	weight_data_done = 0;

    	#`clk_period
    	layer_type = 0;
    	init_fm_data = {16'h0000, 16'h0000, 16'h0000,
    					16'h4000, 16'h4200, 16'h0000,
    					16'h4000, 16'h3c00, 16'h0000};
    	write_fm_data_addr = 2;
    	init_fm_data_done = 0;

    	weight_data_done = 1;

    	#`clk_period
    	layer_type = 0;
    	init_fm_data = {16'h0000, 16'h0000, 16'h0000,
    					16'h0000, 16'h4400, 16'h3c00,
    					16'h0000, 16'h4200, 16'h4400};
    	write_fm_data_addr = 3;
    	init_fm_data_done = 0;

    	#`clk_period
    	layer_type = 0;
    	init_fm_data_done = 1; // just send init_fm_data_done, no write fm data

    	// change to conv layer
    	#`clk_period
    	if (init_fm_ram_ready ==1 && init_weight_ram_ready == 1) begin
    		layer_type = 1;
    		kernel_size = 3;
    	end
    	
    end
endmodule
