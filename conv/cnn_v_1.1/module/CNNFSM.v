`timescale 1ns / 1ps

`include "CNN_Parameter.vh"

module CNNFSM(
    //input clk_p,
    //input clk_n,
    input rst,
    input clk,
    input transmission_start,
    
    output reg stop,
    output reg [7:0] led 
    );

	//wire clk;

    /*IBUFDS #(
        .DIFF_TERM("FALSE"),
        .IBUF_LOW_PWR("TRUE"),
        .IOSTANDARD("DEFAULT")
         )IBUFDS_inst(
        .O(clk),
        .I(clk_p),
        .IB(clk_n)
    );
*/
	reg lp_rst;

	reg [3:0] layer_type; // 0: prepare init feature map and weight data; 1:conv; 2:pool; 3:fc; 9: finish, done
	reg [3:0] pre_layer_type;

	reg [`LAYER_NUM_WIDTH - 1:0] layer_num;

	// data init and data update
	wire [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] init_fm_data;
	wire [`WRITE_ADDR_WIDTH - 1:0] write_fm_data_addr;
	wire init_fm_data_done; // feature map data transmission, 0: not ready; 1: ready

	wire [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_data;
	wire [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] write_weight_data_addr;
	wire weight_data_done; // weight data transmission, 0: not ready; 1: ready

	// common configuration
	reg [`FM_SIZE_WIDTH - 1:0] fm_size;
	reg [`KERNEL_SIZE_WIDTH - 1:0] fm_depth;
	reg [`FM_SIZE_WIDTH - 1:0] fm_total_size;

	reg [`FM_SIZE_WIDTH - 1:0] fm_size_out; // include padding
	reg [`PADDING_NUM_WIDTH - 1:0] padding_out;

	// conv
	reg [`KERNEL_NUM_WIDTH - 1:0] kernel_num; // fm_depth_out
	reg [`KERNEL_SIZE_WIDTH - 1:0] kernel_size;

	// pool
	reg pool_type; // 0: max pool; 1: avg pool
	reg [`POOL_SIZE_WIDTH - 1:0] pool_win_size; 

	// activation
	reg [1:0] activation; // 0: none; 1: ReLU. current just none or ReLU

	wire update_weight_ram; // 0: not update; 1: update
	wire [`WEIGHT_WRITE_ADDR_WIDTH - 1:0] update_weight_ram_addr;

	wire init_fm_ram_ready; // 0: not ready; 1: ready
	wire init_weight_ram_ready; // 0: not ready; 1: ready
	wire layer_ready;

	// ======== Begin: layer ========
	LayerParaScaleFloat16 LP(
		.clk(clk),
		.rst(lp_rst),

		.layer_type(layer_type), // 0: prepare init feature map and weight data; 1:conv; 2:pool; 3:fc; 9: finish, done
		.pre_layer_type(pre_layer_type),

		.layer_num(layer_num),

		// data init and data update
		.init_fm_data(init_fm_data),
		.write_fm_data_addr(write_fm_data_addr),
		.init_fm_data_done(init_fm_data_done), // feature map data transmission, 0: not ready; 1: ready

		.weight_data(weight_data),
		.write_weight_data_addr(write_weight_data_addr),
		.weight_data_done(weight_data_done), // weight data transmission, 0: not ready; 1: ready

		// common configuration
		.fm_size(fm_size),
		.fm_depth(fm_depth),
		.fm_total_size(fm_total_size),

		.fm_size_out(fm_size_out), // include padding
		.padding_out(padding_out),

		// conv
		.kernel_num(kernel_num), // fm_depth_out
		.kernel_size(kernel_size),

		// pool
		.pool_type(pool_type), // 0: max pool; 1: avg pool
		.pool_win_size(pool_win_size), 

		// activation
		.activation(activation), // 0: none; 1: ReLU. current just none or ReLU

		.update_weight_ram(update_weight_ram), // 0: not update; 1: update
		.update_weight_ram_addr(update_weight_ram_addr),

		.init_fm_ram_ready(init_fm_ram_ready), // 0: not ready; 1: ready
		.init_weight_ram_ready(init_weight_ram_ready), // 0: not ready; 1: ready
		.layer_ready(layer_ready)
    );
	// ======== End: layer ========

	reg dt_rst;

	reg [`WRITE_ADDR_WIDTH - 1:0] write_fm_num;

	reg [`KERNEL_NUM_WIDTH - 1:0] kernel_num_count;
    reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] write_weight_num;
    reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] next_write_weight_num;
	// ======== Begin: data ========
	DataTransFloat16 DT(
    	.clk(clk),
    	.rst(dt_rst),
    
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
	// ======== End: data ========

	reg workstate;
	reg [23:0] clk_cnt;
	//reg [26:0] output_cnt;
	reg [8:0] output_cnt;

	always @(transmission_start or rst or stop) 
    	workstate <= transmission_start & (rst) & (~stop);

    reg layer_delay;
	always @(posedge clk) 
    	layer_delay <= layer_ready;

    reg init_done;
    
    always @(posedge clk)
        if (layer_type == 9) stop <= 1;
        
    always @(posedge clk)
        if (workstate && !stop) clk_cnt <= clk_cnt + 1;
        
    always @(posedge clk)
        if (stop) output_cnt <= output_cnt + 1;
        
    always @(posedge clk)
        //case (output_cnt[26:25])
        case (output_cnt[8:7])
        2'b00:led <= 8'b0;
        2'b01:led <= clk_cnt[23:16];
        2'b10:led <= clk_cnt[15:8];
        2'b11:led <= clk_cnt[7:0];
        endcase

	always @(posedge clk or negedge rst) begin
		if (!rst) begin
			lp_rst <= 0;
			dt_rst <= 0;

			stop		<= 0;

			layer_type	<= 0;
			layer_num	<= 0;

			init_done			<= 0;
			write_fm_num		<= 0;
			write_weight_num	<= 0;
			next_write_weight_num <= 0;
			kernel_num_count	<= 0;
			
			clk_cnt <= 0;
			output_cnt <= 0;
		end
		else begin
			if (workstate) begin
				if (init_done == 0) begin 
					layer_type		<= 0; 
			        layer_num		<= 0;

			        lp_rst			<= 1;
			        
			        dt_rst			<= 1;
			        write_fm_num	<= 18; // fm size: 8, slice: 2; [8/3] = 3, 3*3=9, 9*2=18
			        write_weight_num<= 4; // save 2 kernel; slice: 2; write a slice each time; 2*2=4
				end

				if ((layer_ready) && (~layer_delay)) begin // pre layer is ready, go to new layer
					init_done	<= 1;

					layer_num <= layer_num + 1;
			        case (layer_num + 1)
			            1: 
			            	begin 
			            		layer_type	<= 1; // conv
			        			activation	<= 1;

			        			fm_size		<= 8;
						        fm_depth	<= 2;
						        fm_size_out <= 8;
						        padding_out <= 1;

						        kernel_num  <= 6;
						        kernel_size <= 3;

						        kernel_num_count <= 2; // 6 - 4 = 2, 2 kernel wait to update
						        write_weight_num <= 2; // update 1 kernel; slice: 2; write a slice each time; 2;
						        next_write_weight_num <= 11; // fc fm size: 4; slice: 2; 4*4*2*PARA_Y/(KERNEL_SIZE_MAX*KERNEL_SIZE_MAX); [4*4*2*3/(3*3)]=11
			            	end
			            2:
			            	begin 
			            		layer_type		<= 2; // pool
			        			pool_type		<= 0;

						        pool_win_size	<= `POOL_SIZE;

						        fm_size 		<= 8;
						        fm_size_out 	<= 4;
						        padding_out 	<= 0; 
			            	end
			            3:
			            	begin
			            		layer_type		<= 3; // fc
						        pre_layer_type	<= 2;

						        fm_size			<= 4;
						        fm_depth		<= 2;
						        fm_total_size	<= 32;

						        kernel_num		<= 12; // out put fm size, 1*1*kernel_num
						        kernel_size		<= 32; // the total size of fm
						        
						        fm_size_out 	<= 12;

						        kernel_num_count <= 6; // 12 - PARA_Y*PARA_KERNEL; 12 - 3*2 = 6; 2 kernel wait to update
						        write_weight_num <= 11; // fc fm size: 4; slice: 2; 4*4*2*PARA_Y/(KERNEL_SIZE_MAX*KERNEL_SIZE_MAX); [4*4*2*3/(3*3)]=11
						        next_write_weight_num <= 0; // next layer is done
			            	end
			            4:
			            	begin
			            		layer_type	<= 9; // done
			            	end
			        endcase
				end
			end
		end
	end
endmodule
