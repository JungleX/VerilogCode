`timescale 1ns / 1ps

`include "CNN_Parameter.vh"

module DataTransFloat16(
    input clk,
    input rst,
    
    input [3:0] layer_type,
    input [`LAYER_NUM_WIDTH - 1:0] layer_num,

    input [`WRITE_ADDR_WIDTH - 1:0] write_fm_num,

    input [`KERNEL_NUM_WIDTH - 1:0] kernel_num_count,
    input [`WEIGHT_READ_ADDR_WIDTH - 1:0] write_weight_num,
    input [`WEIGHT_READ_ADDR_WIDTH - 1:0] next_write_weight_num,
    
    input update_weight_ram, // 0: not update; 1: update
    input [`WEIGHT_WRITE_ADDR_WIDTH - 1:0] update_weight_ram_addr,
    
    input init_fm_ram_ready, // 0: not ready; 1: ready
    input init_weight_ram_ready, // 0: not ready; 1: ready
    
    output reg [`PARA_X*`POOL_SIZE*`PARA_Y*`DATA_WIDTH - 1:0] init_fm_data,
    output reg [`WRITE_ADDR_WIDTH - 1:0] write_fm_data_addr,
    output reg init_fm_data_done,
    
    output reg [`PARA_Y*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_data,
    output reg [`WEIGHT_WRITE_ADDR_WIDTH - 1:0] write_weight_data_addr,
    output reg weight_data_done // weight data transmission, 0: not ready; 1: ready
    );

	reg [`PARA_X*`POOL_SIZE*`PARA_Y*`DATA_WIDTH - 1:0] fm_set_one;
	reg [`PARA_Y*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_set_one;

	reg [`WRITE_ADDR_WIDTH - 1:0]  write_fm_num_left;

	reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] weight_left;
	reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] write_weight_num_left;
	reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] next_write_weight_num_left;
	reg next_write_weight_swap;

	reg [`LAYER_NUM_WIDTH - 1:0] cur_layer_num;

	reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] init_weight_half;
	reg init_weight_swap;

    reg rst_delay;
	always @(posedge clk) 
    	rst_delay <= rst;

    reg update_weight_ram_delay;
	always @(posedge clk) 
    	update_weight_ram_delay <= update_weight_ram;	

    // debug reg
    reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] test;

	always @(posedge clk or negedge rst) begin
		if (!rst) begin
			weight_left				<= 0;
			write_fm_num_left		<= 0;
			write_weight_num_left	<= 0;
			next_write_weight_num_left <= 0;
			next_write_weight_swap	<= 0;

			init_weight_half	<= 0;
			init_weight_swap	<= 0;

			init_fm_data_done	<= 0;
			weight_data_done	<= 0;

			fm_set_one <= {`PARA_X*`POOL_SIZE*`PARA_Y{16'h3c00}};
    		weight_set_one <= {`PARA_KERNEL*`PARA_Y{16'h3c00}};	
		end
		else begin
			if (layer_type == 0) begin // init layer
				cur_layer_num <= layer_num;

				if ((rst) && (~rst_delay)) begin // new to init layer
					init_fm_data_done 		<= 0;
					write_fm_num_left		<= write_fm_num - 1;

					init_fm_data			<= fm_set_one; // just for current test, todo later
					write_fm_data_addr		<= 0;

					weight_data_done 		<= 0;
					write_weight_num_left	<= write_weight_num - 1;
					init_weight_half		<= write_weight_num/2;

					weight_data				<= weight_set_one; // just for current test, todo later
					write_weight_data_addr	<= 0;
				end
				else begin // init layer
					// init fm ram
					if (write_fm_num_left == 0) begin
						init_fm_data_done <= 1;
					end
					else begin
						init_fm_data_done 	<= 0;
						write_fm_num_left	<= write_fm_num_left - 1;

						init_fm_data		<= fm_set_one; // just for current test, todo later
						write_fm_data_addr	<= write_fm_data_addr + 1;
					end
					
					// init weight ram
					if (write_weight_num_left == 0) begin
						weight_data_done <= 1;
					end
					else begin
						weight_data_done 		<= 0;
						write_weight_num_left	<= write_weight_num_left - 1;

						if ((write_weight_num_left - 1) == init_weight_half) begin
							init_weight_swap <= 1;
						end

						weight_data				<= weight_set_one; // just for current test, todo later
						if ((init_weight_swap == 1) && (write_weight_num_left == init_weight_half)) begin
							write_weight_data_addr	<= `WEIGHT_RAM_HALF;
						end
						else begin
							write_weight_data_addr	<= write_weight_data_addr + 1;
						end
					end
				end
			end
			else begin
				// just update weight
				if (cur_layer_num != layer_num) begin // new layer is coming
					cur_layer_num <= layer_num;

					if (next_write_weight_num_left == 0) begin
						next_write_weight_swap 	<= 0;
						weight_left				<= kernel_num_count;
					end
				end

				if (update_weight_ram == 1) begin
					if (~update_weight_ram_delay) begin // new update weight request
						weight_data_done		= 0; // =
						write_weight_data_addr	<= update_weight_ram_addr;

						write_weight_num_left	= write_weight_num; // =
						next_write_weight_num_left = next_write_weight_num; // =
					end
					else begin
						if (weight_data_done == 0) begin
							write_weight_data_addr	<= write_weight_data_addr + 1;
						end
					end

					if (weight_data_done != 1) begin
						if (weight_left != 0) begin
							if (write_weight_num_left == 0) begin
								weight_data_done		<= 1;

								if (weight_left - `PARA_KERNEL > 0) begin
									weight_left	<= weight_left - `PARA_KERNEL;
								end
								else begin
									weight_left <= 0;
								end
							end
							else begin
								write_weight_num_left	<= write_weight_num_left - 1;

								weight_data				<= weight_set_one; // just for current test, todo later
							end
						end
						else begin // update next layer weight
							if (next_write_weight_num_left == 0) begin
								weight_data_done		<= 1;

								if (next_write_weight_swap == 0) begin // the first time to write next layer weight
									
								end
								else begin // the second time to write next layer weight
									weight_left				<= kernel_num_count;
								end

								next_write_weight_swap <= ~next_write_weight_swap;
							end
							else begin
								next_write_weight_num_left	<= next_write_weight_num_left - 1;

								weight_data					<= weight_set_one; // just for current test, todo later
							end
						end
					end
				end
			end
		end
	end
endmodule
