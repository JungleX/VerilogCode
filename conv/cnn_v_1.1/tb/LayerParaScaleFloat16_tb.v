`timescale 1ns / 1ps

`define clk_period 10

`include "CNN_Parameter.vh"

module LayerParaScaleFloat16_tb();

	reg clk;
	reg rst;

	reg [1:0] layer_type;
    reg [1:0] pre_layer_type;

    reg [`LAYER_NUM_WIDTH - 1:0] layer_num;

	reg [`FM_SIZE_WIDTH - 1:0] fm_size;
	reg [`KERNEL_SIZE_WIDTH - 1:0] fm_depth;

    reg [`FM_SIZE_WIDTH - 1:0] fm_size_out;
    reg [`PADDING_NUM_WIDTH - 1:0] padding_out;
    reg [`KERNEL_NUM_WIDTH - 1:0] kernel_num;

    reg [`KERNEL_SIZE_WIDTH - 1:0] kernel_size;

	reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] init_fm_data;
	reg [`WRITE_ADDR_WIDTH - 1:0] write_fm_data_addr;

	reg init_fm_data_done;

	reg [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_data;
	reg [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] write_weight_data_addr;
	reg weight_data_done; // weight data transmission, 0: not ready; 1: ready

    reg pool_type;
    reg [`POOL_SIZE_WIDTH - 1:0] pool_win_size; 

	wire update_weight_ram; // 0: not update; 1: update
	wire [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] update_weight_ram_addr;

	wire init_fm_ram_ready;
	wire init_weight_ram_ready;
	wire layer_ready;

	LayerParaScaleFloat16 cnn(
		.clk(clk),
		.rst(rst),

		.layer_type(layer_type), // 0: prepare init feature map data; 1:conv; 2:pool; 3:fc;

        .layer_num(layer_num),

		.fm_size(fm_size),
		.fm_depth(fm_depth),

        .fm_size_out(fm_size_out),
        .padding_out(padding_out),
        .kernel_num(kernel_num),

        .kernel_size(kernel_size),

		.init_fm_data(init_fm_data),
		.write_fm_data_addr(write_fm_data_addr),
		.init_fm_data_done(init_fm_data_done), // 0: not ready; 1: ready

		.weight_data(weight_data),
		.write_weight_data_addr(write_weight_data_addr),
		.weight_data_done(weight_data_done), // weight data transmission, 0: not ready; 1: ready

        .pool_type(pool_type), // 0: max pool; 1: avg pool
        .pool_win_size(pool_win_size), 

		.update_weight_ram(update_weight_ram), // 0: not update; 1: update
		.update_weight_ram_addr(update_weight_ram_addr),

		.init_fm_ram_ready(init_fm_ram_ready), // 0: not ready; 1: ready
		.init_weight_ram_ready(init_weight_ram_ready), // 0: not ready; 1: ready
		.layer_ready(layer_ready)
    );

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    integer i;

    reg [`KERNEL_SIZE_WIDTH:0] update_weight_count;

    initial begin
    	#0

    	#(`clk_period/2)
    	// reset
    	rst <= 0;
/*
    	// PARA_X <= 3, PARA_Y <= 3, kernel size <= 3, feature map size <= 6 ============================================
    	#`clk_period
    	rst <= 1;

    	layer_type <= 0;
    	init_fm_data <= {16'h4200, 16'h4000, 16'h0000,
    					16'h4000, 16'h3c00, 16'h0000,
    					16'h0000, 16'h0000, 16'h0000};
    	write_fm_data_addr <= 0;
    	init_fm_data_done <= 0;

    	weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*0] <= {16'h3c00, 16'h4000, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h3c00};
    	weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*2 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1] <= {16'h3c00, 16'h4000, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h4000};
    	write_weight_data_addr <= 0;
    	weight_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h0000, 16'h4000, 16'h4400,
    					16'h0000, 16'h3c00, 16'h4200,
    					16'h0000, 16'h0000, 16'h0000};
    	write_fm_data_addr <= 1;
    	init_fm_data_done <= 0;

    	weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*0] <= {16'h0000, 16'h4200, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h3c00};
    	weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*2 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1] <= {16'h0000, 16'h4200, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h4200};
    	write_weight_data_addr <= 1;
    	weight_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h0000, 16'h0000, 16'h0000,
    					16'h4000, 16'h4200, 16'h0000,
    					16'h4000, 16'h3c00, 16'h0000};
    	write_fm_data_addr <= 2;
    	init_fm_data_done <= 0;

    	weight_data_done <= 1;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h0000, 16'h0000, 16'h0000,
    					16'h0000, 16'h4400, 16'h3c00,
    					16'h0000, 16'h4200, 16'h4400};
    	write_fm_data_addr <= 3;
    	init_fm_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data_done <= 1; // just send init_fm_data_done, no write fm data

    	// change to conv layer
    	#`clk_period
    	if (init_fm_ram_ready <=<=1 && init_weight_ram_ready <=<= 1) begin
    		layer_type <= 1;
    		fm_size <= 6;
    		kernel_size <= 3;
    	end
    	// PARA_X <= 3, PARA_Y <= 3, kernel size <= 3, feature map size <= 6 ============================================
*/
    	// PARA_X <= 3, PARA_Y <= 3, kernel size <= 3, feature map size <= 8 ============================================
    	// slice 0
    	#`clk_period
    	rst <= 1;

    	layer_type <= 0;
        layer_num  <= 0;
    	init_fm_data <= {16'h4200, 16'h4000, 16'h0000,
    					16'h4000, 16'h3c00, 16'h0000,
    					16'h0000, 16'h0000, 16'h0000};
    	write_fm_data_addr <= 0;
    	init_fm_data_done <= 0;

    	weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*0] <= {16'h3c00, 16'h4000, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h3c00};
    	weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*2 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1] <= {16'h3c00, 16'h4000, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h4000};
    	write_weight_data_addr <= 0;
    	weight_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h3c00, 16'h4000, 16'h4400,
    					16'h3c00, 16'h3c00, 16'h4200,
    					16'h0000, 16'h0000, 16'h0000};
    	write_fm_data_addr <= 1;
    	init_fm_data_done <= 0;

    	weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*0] <= {16'h0000, 16'h4200, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h3c00};
    	weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*2 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1] <= {16'h0000, 16'h4200, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h4200};
    	write_weight_data_addr <= 1;
    	weight_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h0000, 16'h0000, 16'h4400,
    					16'h0000, 16'h0000, 16'h4200,
    					16'h0000, 16'h0000, 16'h0000};
    	write_fm_data_addr <= 2;
    	init_fm_data_done <= 0;

        weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*0] <= {16'h3c00, 16'h4000, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h4000};
        weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*2 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1] <= {16'h3c00, 16'h4000, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h3c00};
        write_weight_data_addr <= `DEPTH_MAX; // slice <= 0
        weight_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h3c00, 16'h4000, 16'h0000,
    					16'h4000, 16'h4200, 16'h0000,
    					16'h4000, 16'h3c00, 16'h0000};
    	write_fm_data_addr <= 3;
    	init_fm_data_done <= 0;

        weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*0] <= {16'h0000, 16'h4200, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h4200};
        weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*2 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1] <= {16'h0000, 16'h4200, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h3c00};
        write_weight_data_addr <= `DEPTH_MAX+1; // slice <= 1
        weight_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h4200, 16'h3c00, 16'h4000,
    					16'h4000, 16'h4400, 16'h3c00,
    					16'h4000, 16'h4200, 16'h4400};
    	write_fm_data_addr <= 4;
    	init_fm_data_done <= 0;

        weight_data_done <= 1;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h0000, 16'h0000, 16'h3c00,
    					16'h0000, 16'h0000, 16'h4200,
    					16'h0000, 16'h0000, 16'h4200};
    	write_fm_data_addr <= 5;
    	init_fm_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h0000, 16'h0000, 16'h0000,
    					16'h0000, 16'h0000, 16'h0000,
    					16'h4400, 16'h4200, 16'h0000};
    	write_fm_data_addr <= 6;
    	init_fm_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h0000, 16'h0000, 16'h0000,
    					16'h0000, 16'h0000, 16'h0000,
    					16'h3c00, 16'h4000, 16'h3c00};
    	write_fm_data_addr <= 7;
    	init_fm_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h0000, 16'h0000, 16'h0000,
    					16'h0000, 16'h0000, 16'h0000,
    					16'h0000, 16'h0000, 16'h4400};
    	write_fm_data_addr <= 8;
    	init_fm_data_done <= 0;

    	// slice 1
    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h4000, 16'h4000, 16'h0000,
    					16'h3c00, 16'h4200, 16'h0000,
    					16'h0000, 16'h0000, 16'h0000};
    	write_fm_data_addr <= 9;
    	init_fm_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h3c00, 16'h4200, 16'h3c00,
    					16'h0000, 16'h4400, 16'h4000,
    					16'h0000, 16'h0000, 16'h0000};
    	write_fm_data_addr <= 10;
    	init_fm_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h0000, 16'h0000, 16'h4400,
    					16'h0000, 16'h0000, 16'h3c00,
    					16'h0000, 16'h0000, 16'h0000};
    	write_fm_data_addr <= 11;
    	init_fm_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h3c00, 16'h4000, 16'h0000,
    					16'h4000, 16'h3c00, 16'h0000,
    					16'h4400, 16'h3c00, 16'h0000};
    	write_fm_data_addr <= 12;
    	init_fm_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h3c00, 16'h4200, 16'h4400,
    					16'h4200, 16'h4400, 16'h4200,
    					16'h4200, 16'h3c00, 16'h4000};
    	write_fm_data_addr <= 13;
    	init_fm_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h0000, 16'h0000, 16'h4000,
    					16'h0000, 16'h0000, 16'h4000,
    					16'h0000, 16'h0000, 16'h3c00};
    	write_fm_data_addr <= 14;
    	init_fm_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h0000, 16'h0000, 16'h0000,
    					16'h0000, 16'h0000, 16'h0000,
    					16'h4000, 16'h4200, 16'h0000};
    	write_fm_data_addr <= 15;
    	init_fm_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h0000, 16'h0000, 16'h0000,
    					16'h0000, 16'h0000, 16'h0000,
    					16'h4000, 16'h4200, 16'h4400};
    	write_fm_data_addr <= 16;
    	init_fm_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data <= {16'h0000, 16'h0000, 16'h0000,
    					16'h0000, 16'h0000, 16'h0000,
    					16'h0000, 16'h0000, 16'h3c00};
    	write_fm_data_addr <= 17;
    	init_fm_data_done <= 0;

    	#`clk_period
    	layer_type <= 0;
    	init_fm_data_done <= 1; // just send init_fm_data_done, not write fm data

        while(layer_ready == 0) begin
            #`clk_period
            layer_type <= 0;
        end

    	// change to conv layer
        layer_type <= 1;
        layer_num  <= 1;

        fm_size <= 8;
        fm_depth <= 2;
            
        fm_size_out <= 8;
        padding_out <= 1;
        kernel_num  <= 6;

        kernel_size <= 3;
    	// PARA_X <= 3, PARA_Y <= 3, kernel size <= 3, feature map size <= 8 ============================================

        // update a kernel
        update_weight_count <= 0;
        for (i=0; i<200; i=i+1) begin
            #`clk_period
            if (update_weight_ram == 1) begin
                if (update_weight_count == 0) begin
                    weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*0] <= {16'h3c00, 16'h4000, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h4000};
                    weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*2 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1] <= {16'h3c00, 16'h4000, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h3c00};
                    write_weight_data_addr <= update_weight_ram_addr;
                    update_weight_count <= 1;
                    weight_data_done <= 0;
                end
                else if (update_weight_count == 1) begin
                    weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*0] <= {16'h0000, 16'h4200, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h4200};
                    weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*2 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1] <= {16'h0000, 16'h4200, 16'h0000, 16'h3c00, 16'h4000, 16'h3c00, 16'h4200, 16'h4000, 16'h3c00};
                    update_weight_count <= 2;
                    write_weight_data_addr <= update_weight_ram_addr + 1;
                    weight_data_done <= 0;
                end
                else if(update_weight_count == 2) begin
                    weight_data_done <= 1;
                end
            end
        end

        #(`clk_period*2)
        layer_type <= 1;

        while(layer_ready !=1) begin
            #`clk_period
            layer_type <= 1;
        end

        // change to pool
        #`clk_period
        layer_type <= 2;
        layer_num  <= 2;
        pool_type  <= 0;
        pool_win_size <= `POOL_SIZE;
        fm_size <= 8;
        fm_size_out <= 4;
        padding_out <= 0;

        #(`clk_period*2)
        layer_type <= 2;

        while(layer_ready !=1) begin
            #`clk_period
            layer_type <= 2;
        end

        // change to fc
        #`clk_period
        layer_type <= 3;
        pre_layer_type <= 2;
    end
endmodule