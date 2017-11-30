`timescale 1ns / 1ps

`define clk_period 10

`include "CNN_Parameter.vh"

module DataTransFloat16_tb();
    reg clk;
    reg rst;
    
    reg [3:0] layer_type;
    reg [`LAYER_NUM_WIDTH - 1:0] layer_num;

    reg [`WRITE_ADDR_WIDTH - 1:0] write_fm_num;

    reg [`KERNEL_NUM_WIDTH - 1:0] kernel_num_count;
    reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] write_weight_num;
    reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] next_write_weight_num;
    
    reg update_weight_ram; // 0: not update; 1: update
    reg [`WEIGHT_WRITE_ADDR_WIDTH - 1:0] update_weight_ram_addr;
    
    reg init_fm_ram_ready; // 0: not ready; 1: ready
    reg init_weight_ram_ready; // 0: not ready; 1: ready
    
    wire [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] init_fm_data;
    wire [`WRITE_ADDR_WIDTH - 1:0] write_fm_data_addr;
    wire init_fm_data_done;
    
    wire [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_data;
    wire [`WEIGHT_WRITE_ADDR_WIDTH - 1:0] write_weight_data_addr;
    wire weight_data_done; // weight data transmission, 0: not ready; 1: ready

	DataTransFloat16 DT(
    	.clk(clk),
    	.rst(rst),
    
    	.layer_type(layer_type),
    	.layer_num(layer_num),

    	.write_fm_num(write_fm_num),

    	.kernel_num_count(kernel_num_count),
    	.write_weight_num(write_weight_num),
    	.next_write_weight_num(next_write_weight_num),
    
    	.update_weight_ram(update_weight_ram), // 0: not update; 1: update
    	.update_weight_ram_addr(update_weight_ram_addr),
    
    	.init_fm_ram_ready(init_fm_ram_ready), // 0: not ready; 1: ready
    	.init_weight_ram_ready(init_weight_ram_ready), // 0: not ready; 1: ready
    
    	.init_fm_data(init_fm_data),
    	.write_fm_data_addr(write_fm_data_addr),
    	.init_fm_data_done(init_fm_data_done),
    
    	.weight_data(weight_data),
    	.write_weight_data_addr(write_weight_data_addr),
    	.weight_data_done(weight_data_done) // weight data transmission, 0: not ready; 1: ready
    );

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0

    	#(`clk_period/2)
    	// reset
    	rst <= 0;

    	#`clk_period
    	rst <= 1;

    	// init layer
    	layer_type		<= 0; 
		layer_num		<= 0;
		write_fm_num	<= 18; // fm size: 8, slice: 2; [8/3] = 3, 3*3=9, 9*2=18
		write_weight_num<= 4; // save 2 kernel; slice: 2; write a slice each time; 2*2=4

		update_weight_ram <= 0;

		#`clk_period
    	layer_type <= 0;

        while(weight_data_done == 0 || init_fm_data_done == 0) begin
            #`clk_period
            layer_type <= 0;
        end

        // conv layer
        #(`clk_period*3)
    	layer_type <= 1;
    	layer_num 	<= 1;

		kernel_num_count <= 2; // 6 - 4 = 2, 2 kernel wait to update
		write_weight_num <= 2; // update 1 kernel; slice: 2; write a slice each time; 2;
		next_write_weight_num <= 11; // fc fm size: 4; slice: 2; 4*4*2*PARA_Y/(KERNEL_SIZE_MAX*KERNEL_SIZE_MAX); [4*4*2*3/(3*3)]=11

		// the first update signal
		#(`clk_period*2)
    	update_weight_ram <= 1;
		update_weight_ram_addr <= 4;

		#(`clk_period*2)

        while(weight_data_done == 0) begin
            #`clk_period
            layer_type <= 1;
        end

        update_weight_ram <= 0;

        // the second update signal
        #(`clk_period*5)
    	update_weight_ram <= 1;
		update_weight_ram_addr <= 12;

		#(`clk_period*2)

        while(weight_data_done == 0) begin
            #`clk_period
            layer_type <= 1;
        end

        update_weight_ram <= 0;

        // fc layer
        #(`clk_period*3)
    	layer_type <= 3; // fc
    	layer_num <= 2;

    	kernel_num_count <= 6; // 12 - PARA_Y*PARA_KERNEL; 12 - 3*2 = 6; 2 kernel wait to update
		write_weight_num <= 11; // fc fm size: 4; slice: 2; 4*4*2*PARA_Y/(KERNEL_SIZE_MAX*KERNEL_SIZE_MAX); [4*4*2*3/(3*3)]=11
		next_write_weight_num <= 0; // next layer is done

    	#(`clk_period*2)
    	update_weight_ram <= 1;
		update_weight_ram_addr <= 6;

		#(`clk_period*2)

        while(weight_data_done == 0) begin
            #`clk_period
            layer_type <= 3;
        end

        update_weight_ram <= 0;



    end
endmodule
