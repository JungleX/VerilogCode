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
    
    output reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] init_fm_data,
    output reg [`WRITE_ADDR_WIDTH - 1:0] write_fm_data_addr,
    output reg init_fm_data_done,
    
    output reg [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_data,
    output reg [`WEIGHT_WRITE_ADDR_WIDTH - 1:0] write_weight_data_addr,
    output reg weight_data_done // weight data transmission, 0: not ready; 1: ready
    );

	reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] fm_set_one;
	reg [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_set_one;

	reg [`WRITE_ADDR_WIDTH - 1:0]  write_fm_num_left;

	reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] weight_left;
	reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] write_weight_num_left;
	reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] next_write_weight_num_left;

	reg [`LAYER_NUM_WIDTH - 1:0] cur_layer_num;

    reg rst_delay;
	always @(posedge clk) 
    	rst_delay <= rst;

    reg update_weight_ram_delay;
	always @(posedge clk) 
    	update_weight_ram_delay <= update_weight_ram;	

	always @(posedge clk or negedge rst) begin
		if (!rst) begin
			weight_left				<= 0;
			write_fm_num_left		<= 0;
			write_weight_num_left	<= 0;
			next_write_weight_num_left <= 0;

			init_fm_data_done	<= 0;
			weight_data_done	<= 0;

			fm_set_one <= {`PARA_X*`PARA_Y{16'h3c00}};
    		weight_set_one <= {`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL{16'h3c00}};	
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

						weight_data				<= weight_set_one; // just for current test, todo later
						write_weight_data_addr	<= write_weight_data_addr + `KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX;
					end
				end
			end
			else begin
				// just update weight
				if (cur_layer_num != layer_num) begin // new layer is coming
					cur_layer_num <= layer_num;

					weight_left				<= kernel_num_count;
				end

				if (update_weight_ram == 1) begin
					if (~update_weight_ram_delay) begin // new update weight request
						weight_data_done		<= 0;
						write_weight_data_addr	<= update_weight_ram_addr;

						write_weight_num_left	= write_weight_num; // =
						next_write_weight_num_left = next_write_weight_num; // =
					end
					else begin
						if (weight_data_done == 0) begin
							write_weight_data_addr	<= write_weight_data_addr + `KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX;
						end
					end

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
endmodule
