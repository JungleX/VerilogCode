`timescale 1ns / 1ps

`include "CNN_Parameter.vh"

module LayerParaScaleFloat16(
	input clk,
	input rst,

	input [3:0] layer_type, // 0: prepare init feature map and weight data; 1:conv; 2:pool; 3:fc; 9: finish, done
	input [3:0] pre_layer_type,

	input [`LAYER_NUM_WIDTH - 1:0] layer_num,

	// data init and data update
	input [`PARA_X*`POOL_SIZE*`PARA_Y*`DATA_WIDTH - 1:0] init_fm_data,
	input [`FM_ADDRA_WIDTH - 1:0] write_fm_data_addr,
	input init_fm_data_done, // feature map data transmission, 0: not ready; 1: ready

	input [`PARA_Y*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_data,
	input [`WEIGHT_ADDRA_WIDTH - 1:0] write_weight_data_addr,
	input weight_data_done, // weight data transmission, 0: not ready; 1: ready

	// common configuration
	input [`FM_SIZE_WIDTH - 1:0] fm_size,
	input [`KERNEL_NUM_WIDTH - 1:0] fm_depth,
	input [`FM_SIZE_WIDTH - 1:0] fm_total_size,

	input [`FM_SIZE_WIDTH - 1:0] fm_size_out, // include padding
	input [`PADDING_NUM_WIDTH - 1:0] padding_out,

	// conv
	input [`KERNEL_NUM_WIDTH - 1:0] kernel_num, // fm_depth_out
	input [`KERNEL_SIZE_WIDTH - 1:0] kernel_size,

	// pool
	input pool_type, // 0: max pool; 1: avg pool
	input [`POOL_SIZE_WIDTH - 1:0] pool_win_size, 

	// activation
	input [1:0] activation, // 0: none; 1: ReLU. current just none or ReLU

	output reg update_weight_ram, // 0: not update; 1: update
	output reg [`WEIGHT_ADDRA_WIDTH - 1:0] update_weight_ram_addr,

	output reg init_fm_ram_ready, // 0: not ready; 1: ready
	output reg init_weight_ram_ready, // 0: not ready; 1: ready
	output reg layer_ready,

	output reg [`DATA_WIDTH - 1:0] test_data // for debug
    );

	// ======== Begin: pool unit ========
	reg pu_rst;

	reg [`PARA_Y*`DATA_WIDTH - 1:0] pool_input_data;
	reg [`CLK_NUM_WIDTH - 1:0] data_num;

	wire [`PARA_Y - 1:0] pu_out_ready;
	wire [`PARA_Y*`DATA_WIDTH - 1:0] pu_result;

	// === Begin: max pool ===
	generate
		genvar pool_i;
		for (pool_i = 0; pool_i < `PARA_Y; pool_i = pool_i + 1)
		begin:identifier_pu
			MaxPoolUnitFloat16 mpu(
				.clk(clk),
				.rst(pu_rst), 

				.cmp_data(pool_input_data[`DATA_WIDTH*(pool_i+1) - 1:`DATA_WIDTH*pool_i]),

				.data_num(data_num), // set the clk number, after clk_count clks, the output is ready

				.result_ready(pu_out_ready[pool_i:pool_i]), 
				.max_pool_result(pu_result[`DATA_WIDTH*(pool_i+1) - 1:`DATA_WIDTH*pool_i])
			);
		end
	endgenerate
	// === End: max pool ===
	// ======== End: pool unit ========

	// ======== Begin: conv unit ========
	reg conv_rst;

	reg conv_op_type;
	reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] conv_input_data[`PARA_KERNEL - 1:0];
	reg [`DATA_WIDTH - 1:0] conv_weight[`PARA_KERNEL - 1:0];

	wire [`PARA_KERNEL - 1:0] conv_out_ready;
	wire [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] conv_out_buffer[`PARA_KERNEL - 1:0];

	generate
		genvar conv_i;
		for (conv_i = 0; conv_i < `PARA_KERNEL; conv_i = conv_i + 1)
		begin:identifier_conv
			ConvParaScaleFloat16 conv(
				.clk(clk),
				.rst(conv_rst), 

				.op_type(conv_op_type),
				.input_data(conv_input_data[conv_i]),
				.weight(conv_weight[conv_i]),

				.kernel_size(kernel_size),

				.activation(activation),

				.result_ready(conv_out_ready[conv_i:conv_i]), 
				.result_buffer(conv_out_buffer[conv_i])
		    );
		end
	endgenerate
    // ======== End: conv unit ========

    // ======== Begin: feature map ram ========
    reg fm_rst; 

    reg fm_ena_add_write[`PARA_X - 1:0]; // 0: not add; 1: add
    
    reg [`WRITE_ADDR_WIDTH - 1:0] fm_zero_start_addr[`PARA_X - 1:0];

    reg fm_ena_w[`PARA_X - 1:0];
    reg [`WRITE_ADDR_WIDTH - 1:0] fm_addr_write[`PARA_X - 1:0];
	reg [`PARA_Y*`DATA_WIDTH - 1:0] fm_din[`PARA_X - 1:0];

	reg fm_ena_para_w[`PARA_X - 1:0]; 
    reg [`WRITE_ADDR_WIDTH - 1:0] fm_addr_para_write[`PARA_X - 1:0];
    reg [`FM_SIZE_WIDTH - 1:0] fm_out_size[`PARA_X - 1:0];
    reg [`PARA_Y*`PARA_KERNEL*`DATA_WIDTH - 1:0] fm_para_din[`PARA_X - 1:0];

    reg fm_ena_r[`PARA_X - 1:0];
    reg [1:0] fm_read_type;
	reg [`READ_ADDR_WIDTH - 1:0] fm_addr_read[`PARA_X - 1:0];
	reg [`READ_ADDR_WIDTH - 1:0] fm_sub_addr_read[`PARA_X - 1:0];

	wire [`PARA_X - 1:0] fm_write_ready;
	wire [`PARA_Y*`DATA_WIDTH - 1:0] fm_dout[`PARA_X - 1:0];

    // =================================================================
    reg [`FM_ADDRA_WIDTH - 1:0] fmr_addra[`PARA_X - 1:0];
    reg [`POOL_SIZE*`PARA_Y*`DATA_WIDTH - 1:0] fmr_dina[`PARA_X - 1:0]; 
    reg fmr_ena[`PARA_X - 1:0];
    reg fmr_wea[`PARA_X - 1:0];
    
    reg [`FM_ADDRB_WIDTH - 1:0] fmr_addrb[`PARA_X - 1:0];
    wire [`POOL_SIZE*`PARA_Y*`DATA_WIDTH - 1:0] fmr_doutb[`PARA_X - 1:0];
    reg fmr_enb[`PARA_X - 1:0];
    
    generate
        genvar fm_ram_i;
        for (fm_ram_i = 0; fm_ram_i < `PARA_X; fm_ram_i = fm_ram_i + 1)
        begin
            feature_map_ram fmr(
                .addra(fmr_addra[fm_ram_i]),
                .clka(clk),
                .dina(fmr_dina[fm_ram_i]),
                .ena(fmr_ena[fm_ram_i]),
                .wea(fmr_wea[fm_ram_i]),
    
                .addrb(fmr_addrb[fm_ram_i]),
                .clkb(clk),
                .doutb(fmr_doutb[fm_ram_i]),
                .enb(fmr_enb[fm_ram_i])
                );
        end
    endgenerate
    // ======== End: feature map ram ========

    // ======== Begin: weight ram ========
    reg weight_ena_w[`PARA_KERNEL - 1:0];
    reg weight_ena_r[`PARA_KERNEL - 1:0];
    reg weight_ena_fc_r[`PARA_KERNEL - 1:0];

    reg [`WEIGHT_WRITE_ADDR_WIDTH - 1:0] weight_addr_write[`PARA_KERNEL - 1:0];
	reg [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH - 1:0] weight_din[`PARA_KERNEL - 1:0]; // write a slice weight(ks*ks, eg:3*3=9) each time

	reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] weight_addr_read[`PARA_KERNEL - 1:0];

	wire [`PARA_Y*`DATA_WIDTH - 1:0] weight_dout[`PARA_KERNEL - 1:0]; 

 	// =================================================================
    reg wr_ena;
    reg wr_wea;

    reg [`WEIGHT_ADDRB_WIDTH - 1:0] wr_addrb;
    wire [`PARA_Y*`DATA_WIDTH - 1:0] wr_doutb[`PARA_KERNEL - 1:0];
    reg wr_enb;

    generate
        genvar weight_ram_i;
        for (weight_ram_i = 0; weight_ram_i < `PARA_KERNEL; weight_ram_i = weight_ram_i + 1)
        begin:identifier_weight_ram
            weight_ram wr(
				.addra(write_weight_data_addr),
				.clka(clk),
				.dina(weight_data[`PARA_Y*`DATA_WIDTH*(weight_ram_i+1) - 1:`PARA_Y*`DATA_WIDTH*weight_ram_i]),
				.ena(wr_ena),
				.wea(wr_wea),
				
				.addrb(wr_addrb),
				.clkb(clk),
				.doutb(wr_doutb[weight_ram_i]),
				.enb(wr_enb)
		    );
        end
    endgenerate
    // ======== End: weight ram ========

    reg [`CLK_NUM_WIDTH - 1:0] buffer_write_count;
    reg buffer_to_fm_ram;
    // ======== Begin: conv buffer ========
    // PARA_KERNEL, double
    // todo
    //reg [`DATA_WIDTH - 1:0] buffer_0_0 [`FM_SIZE_MAX*`FM_SIZE_MAX - 1:0]; 
    //reg [`DATA_WIDTH - 1:0] buffer_0_1 [`FM_SIZE_MAX*`FM_SIZE_MAX - 1:0];  
    // ======== End: conv buffer ========

    reg [`CLK_NUM_WIDTH - 1:0] clk_count;

    reg [`RAM_NUM_WIDTH - 1:0] cur_fm_ram;
    reg [`RAM_NUM_WIDTH - 1:0] cur_out_fm_ram;

    reg [`FM_SIZE_WIDTH - 1:0] cur_x;
    reg [`FM_SIZE_WIDTH - 1:0] cur_y;
    reg [`KERNEL_NUM_WIDTH - 1:0] cur_slice;

    // update kernel
    reg cur_kernel_swap; // 0 or 1; one is using, the other is updating
    reg [`KERNEL_NUM_WIDTH - 1:0] cur_kernel_slice;
    reg [`KERNEL_NUM_WIDTH - 1:0] kernel_num_count;

    reg update_weight_wait_count;

    // write fm result to ram
    reg cur_fm_swap;
    reg zero_write_count;
    reg [`FM_SIZE_WIDTH - 1:0] cur_out_index[`PARA_Y - 1:0];
    reg [`KERNEL_NUM_WIDTH - 1:0] cur_out_slice;
    reg [`RAM_NUM_WIDTH - 1:0] cur_write_start_ram;
    reg [`RAM_NUM_WIDTH - 1:0] cur_write_end_ram;
    reg [`CLK_NUM_WIDTH - 1:0] write_ready_clk_count;

    reg [`LAYER_NUM_WIDTH - 1:0] cur_layer_num;
    reg go_to_next_layer;

    // read wait clk count
    reg [`CLK_NUM_WIDTH - 1:0] read_clk_count;

	always @(posedge clk or negedge rst) begin
		if (!rst) begin
			// reset conv and pool modules
			conv_rst	<= 0;
			conv_op_type<= 0;
			pu_rst		<= 0;
			fm_rst		<= 0;

			// reset init signal
			init_fm_ram_ready		<= 0;
			init_weight_ram_ready	<= 0;

			// ======== Begin: reset fm ram ========
			// PARA_X
			fmr_ena[0]	<= 0;
			fmr_wea[0]	<= 0;
			fmr_enb[0]	<= 0;

			fmr_ena[1]	<= 0;
			fmr_wea[1]	<= 0;
			fmr_enb[1]	<= 0;

			fmr_ena[2]	<= 0;
			fmr_wea[2]	<= 0;
			fmr_enb[2]	<= 0;

			fmr_ena[3]	<= 0;
			fmr_wea[3]	<= 0;
			fmr_enb[3]	<= 0;

			fmr_ena[4]	<= 0;
			fmr_wea[4]	<= 0;
			fmr_enb[4]	<= 0;

			fmr_ena[5]	<= 0;
			fmr_wea[5]	<= 0;
			fmr_enb[5]	<= 0;

			fmr_ena[6]	<= 0;
			fmr_wea[6]	<= 0;
			fmr_enb[6]	<= 0;

			fmr_ena[7]	<= 0;
			fmr_wea[7]	<= 0;
			fmr_enb[7]	<= 0;

			fmr_ena[8]	<= 0;
			fmr_wea[8]	<= 0;
			fmr_enb[8]	<= 0;

			fmr_ena[9]	<= 0;
			fmr_wea[9]	<= 0;
			fmr_enb[9]	<= 0;

			fmr_ena[10]	<= 0;
			fmr_wea[10]	<= 0;
			fmr_enb[10]	<= 0;

			fmr_ena[11]	<= 0;
			fmr_wea[11]	<= 0;
			fmr_enb[11]	<= 0;

			fmr_ena[12]	<= 0;
			fmr_wea[12]	<= 0;
			fmr_enb[12]	<= 0;

			fmr_ena[13]	<= 0;
			fmr_wea[13]	<= 0;
			fmr_enb[13]	<= 0;
			// ======== End: reset fm ram ========

			// ======== Begin: reset weight ram ========
			// only one
			wr_ena	<= 0;
			wr_wea	<= 0;
			wr_enb	<= 0;
			// ======== End: reset weight ram ========

			// reset layer status signal
			cur_layer_num		<= 0;
			layer_ready			<= 0; 	
			go_to_next_layer	<= 0;	

			// reset clock counter	
			clk_count			<= 0;
			read_clk_count	<= 0;

			// reset current input fm ram and output fm ram
			cur_fm_ram			<= 0;
			cur_out_fm_ram		<= 0;

			// reset current read location of fm
			cur_x		<= 0;
			cur_y		<= 0;
			cur_slice	<= 0;

			// reset the output location of fm ram
			cur_out_slice		<= 0;
			cur_write_start_ram	<= 0;
			cur_write_end_ram	<= 0;

			// reset current read fm and kernel/weight swap 
			cur_fm_swap			<= 0;
			cur_kernel_swap		<= 0;
			
			// reset current read location of kernel/weight
			cur_kernel_slice	<= 0;

			// reset kernel counter
			kernel_num_count	<= 0;

			// reset update kernel/weight signal
			update_weight_ram		<= 0; 

			// reset the wait counter of update kernel/weight signal
			update_weight_wait_count <= 0;

			// reset the wait counter of write fm ram
			write_ready_clk_count	<= 0;

			// reset zero prepare status
			zero_write_count	<= 0;

			// reset write buffer count
			buffer_write_count <= 0;
			buffer_to_fm_ram <= 0;
		end
		else begin
			fm_rst <= 1;
			
			if (layer_type == 0) begin
				if (layer_ready == 0) begin
					// init feature map ram
					if (init_fm_data_done == 1) begin
						init_fm_ram_ready <= 1;
					end
					else begin
						// ======== Begin: write fm ram ========
						// PARA_X
						fmr_ena[0]		<= 1;
						fmr_wea[0]		<= 1;
						fmr_addra[0]	<= write_fm_data_addr;
						fmr_dina[0]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*1 - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*0];

						fmr_ena[1]		<= 1;
						fmr_wea[1]		<= 1;
						fmr_addra[1]	<= write_fm_data_addr;
						fmr_dina[1]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*2 - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*1];

						fmr_ena[2]		<= 1;
						fmr_wea[2]		<= 1;
						fmr_addra[2]	<= write_fm_data_addr;
						fmr_dina[2]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*3 - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*2];

						fmr_ena[3]		<= 1;
						fmr_wea[3]		<= 1;
						fmr_addra[3]	<= write_fm_data_addr;
						fmr_dina[3]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*4 - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*3];

						fmr_ena[4]		<= 1;
						fmr_wea[4]		<= 1;
						fmr_addra[4]	<= write_fm_data_addr;
						fmr_dina[4]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*5 - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*4];

						fmr_ena[5]		<= 1;
						fmr_wea[5]		<= 1;
						fmr_addra[5]	<= write_fm_data_addr;
						fmr_dina[5]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*6 - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*5];

						fmr_ena[6]		<= 1;
						fmr_wea[6]		<= 1;
						fmr_addra[6]	<= write_fm_data_addr;
						fmr_dina[6]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*7 - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*6];

						fmr_ena[7]		<= 1;
						fmr_wea[7]		<= 1;
						fmr_addra[7]	<= write_fm_data_addr;
						fmr_dina[7]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*8 - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*7];

						fmr_ena[8]		<= 1;
						fmr_wea[8]		<= 1;
						fmr_addra[8]	<= write_fm_data_addr;
						fmr_dina[8]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*9 - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*8];

						fmr_ena[9]		<= 1;
						fmr_wea[9]		<= 1;
						fmr_addra[9]	<= write_fm_data_addr;
						fmr_dina[9]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*10 - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*9];

						fmr_ena[10]		<= 1;
						fmr_wea[10]		<= 1;
						fmr_addra[10]	<= write_fm_data_addr;
						fmr_dina[10]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*11 - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*10];

						fmr_ena[11]		<= 1;
						fmr_wea[11]		<= 1;
						fmr_addra[11]	<= write_fm_data_addr;
						fmr_dina[11]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*12 - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*11];

						fmr_ena[12]		<= 1;
						fmr_wea[12]		<= 1;
						fmr_addra[12]	<= write_fm_data_addr;
						fmr_dina[12]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*13 - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*12];

						fmr_ena[13]		<= 1;
						fmr_wea[13]		<= 1;
						fmr_addra[13]	<= write_fm_data_addr;
						fmr_dina[13]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*14 - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*13];
						// ======== End: write fm ram ========

						init_fm_ram_ready	<= 0;
					end

					// init weight ram
					if (weight_data_done == 1) begin
						init_weight_ram_ready <= 1;
					end
					else begin
						// write weight data to weight ram directly
						wr_ena	<= 1;
						wr_wea	<= 1;

						init_weight_ram_ready <= 0;
					end

					// init done
					if (init_fm_ram_ready == 1 && init_weight_ram_ready == 1) begin
						layer_ready <= 1;
					end
				end
			end
			else if (init_fm_ram_ready == 1 && init_weight_ram_ready == 1) begin

				if (cur_layer_num != layer_num) begin // new layer is coming
					layer_ready			<= 0;
					go_to_next_layer	<= 0;
					cur_layer_num		<= layer_num;
				end

				// update kernel
				if (update_weight_ram == 1) begin
					if (update_weight_wait_count == 0) begin
						update_weight_wait_count <= 1;
					end
					else if(update_weight_wait_count == 1) begin
						if (weight_data_done == 0) begin
							// write weight data to weight ram directly
							wr_ena	<= 1;
							wr_wea	<= 1;
						end
						else if(weight_data_done == 1) begin
							// disable write weight data port
							wr_ena	<= 0;
							wr_wea	<= 0;

							update_weight_ram <= 0;
						end
					end
				end

				if (layer_ready == 0) begin // current layer is not ready, continue to run
					case(layer_type)
						1:// conv
							begin
								conv_op_type	<= 0; // set conv unit type

								// prepare output ram
								if (zero_write_count == 0) begin // prepare zero padding
									// ======== Begin: set conv buffer zero write ========
									// PARA_KERNEL
									// todo
									// buffer_x_y
									// ======== End: set conv buffer zero write ========

									// ======== Begin: set fm ram zero write ========
									// PARA_X
									// todo
									/*cur_out_index[0]	<= ((padding_out-0+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out;
									cur_out_index[1]	<= ((padding_out-1+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out;
									cur_out_index[2]	<= ((padding_out-2+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out;*/
									// ======== End: set fm ram zero write ========

									cur_write_start_ram	<= padding_out-(padding_out/`PARA_X)*`PARA_X;
									cur_write_end_ram	<= fm_size_out-(fm_size_out/`PARA_X)*`PARA_X;
									zero_write_count	<= 1;
								end

								// conv operation
								// set read address
								if (read_clk_count == 0) begin
									if (go_to_next_layer == 0) begin
										// start to read, wait 1 clk to get read data
										// ======== Begin: set fm ram read ========
										// PARA_X
										fmr_enb[0]		<= 1;
										//fmr_addrb[0]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[0]	<= 0;// test

										fmr_enb[1]		<= 1;
										//fmr_addrb[1]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[1]	<= 0;// test

										fmr_enb[2]		<= 1;
										//fmr_addrb[2]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[2]	<= 0;// test

										fmr_enb[3]		<= 1;
										//fmr_addrb[3]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[3]	<= 0;// test

										fmr_enb[4]		<= 1;
										//fmr_addrb[4]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[4]	<= 0;// test

										fmr_enb[5]		<= 1;
										//fmr_addrb[5]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[5]	<= 0;// test

										fmr_enb[6]		<= 1;
										//fmr_addrb[6]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[6]	<= 0;// test

										fmr_enb[7]		<= 1;
										//fmr_addrb[7]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[7]	<= 0;// test

										fmr_enb[8]		<= 1;
										//fmr_addrb[8]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[8]	<= 0;// test

										fmr_enb[9]		<= 1;
										//fmr_addrb[9]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[9]	<= 0;// test

										fmr_enb[10]		<= 1;
										//fmr_addrb[10]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[10]	<= 0;// test

										fmr_enb[11]		<= 1;
										//fmr_addrb[11]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[11]	<= 0;// test

										fmr_enb[12]		<= 1;
										//fmr_addrb[12]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[12]	<= 0;// test

										fmr_enb[13]		<= 1;
										//fmr_addrb[13]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[13]	<= 0;// test
										// ======== End: set fm ram read ========

										// set weight read
										wr_enb		<= 1;
										wr_addrb	<= cur_kernel_swap*`WEIGHT_RAM_HALF + cur_kernel_slice*kernel_size*kernel_size/`PARA_Y;

										read_clk_count	<= read_clk_count + 1;
									end
								end
								else if (read_clk_count <= (kernel_size*kernel_size + 1)) begin
									// start to get read data
									if(read_clk_count == 2) begin
										
										clk_count <= 0;
									end	
								
									// set feature map address
									if (read_clk_count == 1) begin
										// ======== Begin: set fm ram read ========
										// PARA_X
										fmr_addrb[0] = fmr_addrb[0] + 1; 
										fmr_addrb[1] = fmr_addrb[1] + 1; 
										fmr_addrb[2] = fmr_addrb[2] + 1; 
										fmr_addrb[3] = fmr_addrb[3] + 1; 
										fmr_addrb[4] = fmr_addrb[4] + 1; 
										fmr_addrb[5] = fmr_addrb[5] + 1; 
										fmr_addrb[6] = fmr_addrb[6] + 1; 
										fmr_addrb[7] = fmr_addrb[7] + 1; 
										fmr_addrb[8] = fmr_addrb[8] + 1; 
										fmr_addrb[9] = fmr_addrb[9] + 1; 
										fmr_addrb[10] = fmr_addrb[10] + 1; 
										fmr_addrb[11] = fmr_addrb[11] + 1; 
										fmr_addrb[12] = fmr_addrb[12] + 1; 
										fmr_addrb[13] = fmr_addrb[13] + 1; 
										// ======== End: set fm ram read ========
									end
									else if (read_clk_count > 1 && read_clk_count <= kernel_size) begin
										// ======== Begin: move fm ram read data ========
										// PARA_X
										// todo 
										// each ram, fm_sub_addr_read = fm_sub_addr_read + 1
										// ======== End: move fm ram read data ========

										if (read_clk_count == kernel_size) begin
											fmr_addrb[0] <= fmr_addrb[0] + (fm_size+`PARA_Y-1)/`PARA_Y - ((kernel_size-1)+`PARA_Y-1)/`PARA_Y;
											
											//fm_sub_addr_read[0]	<= 0; // not move read data, use directly
											cur_fm_ram			<= 0;
										end

									end
									else if ((read_clk_count-(read_clk_count/kernel_size)*kernel_size) == 1 && read_clk_count <= (kernel_size*kernel_size)) begin
										fmr_addrb[cur_fm_ram]		<= fmr_addrb[cur_fm_ram] + 1;
										//fm_sub_addr_read[0]	<= 0; // not move read data, use directly
									end
									else if (read_clk_count <= (kernel_size*kernel_size)) begin
										if ((read_clk_count-(read_clk_count/kernel_size)*kernel_size) == 0) begin
											cur_fm_ram	<= (cur_fm_ram+1) - ((cur_fm_ram+1)/`PARA_X)*`PARA_X;

											// ======== Begin: set fm ram read address ========
											// PARA_X
											// todo, reset move signal
											//fm_sub_addr_read[0]	<= 0;
											//fm_sub_addr_read[1]	<= 0;
											//fm_sub_addr_read[2]	<= 0;
											// ======== End: set fm ram read address ========

											fmr_addrb[(cur_fm_ram+1) - ((cur_fm_ram+1)/`PARA_X)*`PARA_X] <= fmr_addrb[(cur_fm_ram+1) - ((cur_fm_ram+1)/`PARA_X)*`PARA_X] + (fm_size+`PARA_Y-1)/`PARA_Y - ((kernel_size-1)+`PARA_Y-1)/`PARA_Y;
										end
										else begin
											fmr_addrb[cur_fm_ram]	<= fmr_addrb[cur_fm_ram] + 1;
										end
									end

									// set weight address
									// weight data
									if (read_clk_count == 1) begin
									end
									else begin
										// each time read `PARA_Y
										if ((read_clk_count-(read_clk_count/`PARA_Y)*`PARA_Y) == 1) begin
											wr_enb	<= wr_enb + 1;
										end
									end

									read_clk_count <= read_clk_count + 1;
								end

								// read data
								if (clk_count == 0) begin
									if (go_to_next_layer == 0) begin
										conv_rst	<= 0;

										cur_fm_ram	<= 0;

										clk_count	<= clk_count + 1;
									end
								end
								else begin
									conv_rst	<= 1;

									// weight data
									if (clk_count == 1) begin
									end
									else if (clk_count <= (kernel_size*kernel_size + 1)) begin
										// ======== Begin: set weight ram read ========
										// PARA_KERNEL
										conv_weight[0]		<= wr_doutb[0][`DATA_WIDTH - 1:0]; 
										conv_weight[1]		<= wr_doutb[1][`DATA_WIDTH - 1:0]; 
										conv_weight[2]		<= wr_doutb[2][`DATA_WIDTH - 1:0]; 
										// ======== End: set weight ram read ========
									end

									// feature map data
									if (clk_count == 1) begin
										// ======== Begin: set fm ram read data ========
										// PARA_KERNEL -> PARA_X -> PARA_Y
										conv_input_data[0][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fmr_doutb[0][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= fmr_doutb[0][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= fmr_doutb[0][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] <= fmr_doutb[0][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] <= fmr_doutb[0][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5] <= fmr_doutb[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6] <= fmr_doutb[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7] <= fmr_doutb[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8] <= fmr_doutb[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9] <= fmr_doutb[0][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[0][`DATA_WIDTH*11 - 1:`DATA_WIDTH*10] <= fmr_doutb[1][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*12 - 1:`DATA_WIDTH*11] <= fmr_doutb[1][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*13 - 1:`DATA_WIDTH*12] <= fmr_doutb[1][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*14 - 1:`DATA_WIDTH*13] <= fmr_doutb[1][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*15 - 1:`DATA_WIDTH*14] <= fmr_doutb[1][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*16 - 1:`DATA_WIDTH*15] <= fmr_doutb[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*17 - 1:`DATA_WIDTH*16] <= fmr_doutb[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*18 - 1:`DATA_WIDTH*17] <= fmr_doutb[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*19 - 1:`DATA_WIDTH*18] <= fmr_doutb[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*20 - 1:`DATA_WIDTH*19] <= fmr_doutb[1][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[0][`DATA_WIDTH*21 - 1:`DATA_WIDTH*20] <= fmr_doutb[2][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*22 - 1:`DATA_WIDTH*21] <= fmr_doutb[2][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*23 - 1:`DATA_WIDTH*22] <= fmr_doutb[2][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*24 - 1:`DATA_WIDTH*23] <= fmr_doutb[2][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*25 - 1:`DATA_WIDTH*24] <= fmr_doutb[2][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*26 - 1:`DATA_WIDTH*25] <= fmr_doutb[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*27 - 1:`DATA_WIDTH*26] <= fmr_doutb[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*28 - 1:`DATA_WIDTH*27] <= fmr_doutb[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*29 - 1:`DATA_WIDTH*28] <= fmr_doutb[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*30 - 1:`DATA_WIDTH*29] <= fmr_doutb[2][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[0][`DATA_WIDTH*31 - 1:`DATA_WIDTH*30] <= fmr_doutb[3][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*32 - 1:`DATA_WIDTH*31] <= fmr_doutb[3][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*33 - 1:`DATA_WIDTH*32] <= fmr_doutb[3][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*34 - 1:`DATA_WIDTH*33] <= fmr_doutb[3][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*35 - 1:`DATA_WIDTH*34] <= fmr_doutb[3][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*36 - 1:`DATA_WIDTH*35] <= fmr_doutb[3][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*37 - 1:`DATA_WIDTH*36] <= fmr_doutb[3][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*38 - 1:`DATA_WIDTH*37] <= fmr_doutb[3][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*39 - 1:`DATA_WIDTH*38] <= fmr_doutb[3][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*40 - 1:`DATA_WIDTH*39] <= fmr_doutb[3][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[0][`DATA_WIDTH*41 - 1:`DATA_WIDTH*40] <= fmr_doutb[4][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*42 - 1:`DATA_WIDTH*41] <= fmr_doutb[4][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*43 - 1:`DATA_WIDTH*42] <= fmr_doutb[4][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*44 - 1:`DATA_WIDTH*43] <= fmr_doutb[4][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*45 - 1:`DATA_WIDTH*44] <= fmr_doutb[4][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*46 - 1:`DATA_WIDTH*45] <= fmr_doutb[4][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*47 - 1:`DATA_WIDTH*46] <= fmr_doutb[4][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*48 - 1:`DATA_WIDTH*47] <= fmr_doutb[4][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*49 - 1:`DATA_WIDTH*48] <= fmr_doutb[4][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*50 - 1:`DATA_WIDTH*49] <= fmr_doutb[4][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[0][`DATA_WIDTH*51 - 1:`DATA_WIDTH*50] <= fmr_doutb[5][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*52 - 1:`DATA_WIDTH*51] <= fmr_doutb[5][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*53 - 1:`DATA_WIDTH*52] <= fmr_doutb[5][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*54 - 1:`DATA_WIDTH*53] <= fmr_doutb[5][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*55 - 1:`DATA_WIDTH*54] <= fmr_doutb[5][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*56 - 1:`DATA_WIDTH*55] <= fmr_doutb[5][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*57 - 1:`DATA_WIDTH*56] <= fmr_doutb[5][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*58 - 1:`DATA_WIDTH*57] <= fmr_doutb[5][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*59 - 1:`DATA_WIDTH*58] <= fmr_doutb[5][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*60 - 1:`DATA_WIDTH*59] <= fmr_doutb[5][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[0][`DATA_WIDTH*61 - 1:`DATA_WIDTH*60] <= fmr_doutb[6][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*62 - 1:`DATA_WIDTH*61] <= fmr_doutb[6][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*63 - 1:`DATA_WIDTH*62] <= fmr_doutb[6][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*64 - 1:`DATA_WIDTH*63] <= fmr_doutb[6][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*65 - 1:`DATA_WIDTH*64] <= fmr_doutb[6][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*66 - 1:`DATA_WIDTH*65] <= fmr_doutb[6][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*67 - 1:`DATA_WIDTH*66] <= fmr_doutb[6][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*68 - 1:`DATA_WIDTH*67] <= fmr_doutb[6][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*69 - 1:`DATA_WIDTH*68] <= fmr_doutb[6][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*70 - 1:`DATA_WIDTH*69] <= fmr_doutb[6][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[0][`DATA_WIDTH*71 - 1:`DATA_WIDTH*70] <= fmr_doutb[7][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*72 - 1:`DATA_WIDTH*71] <= fmr_doutb[7][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*73 - 1:`DATA_WIDTH*72] <= fmr_doutb[7][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*74 - 1:`DATA_WIDTH*73] <= fmr_doutb[7][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*75 - 1:`DATA_WIDTH*74] <= fmr_doutb[7][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*76 - 1:`DATA_WIDTH*75] <= fmr_doutb[7][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*77 - 1:`DATA_WIDTH*76] <= fmr_doutb[7][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*78 - 1:`DATA_WIDTH*77] <= fmr_doutb[7][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*79 - 1:`DATA_WIDTH*78] <= fmr_doutb[7][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*80 - 1:`DATA_WIDTH*79] <= fmr_doutb[7][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[0][`DATA_WIDTH*81 - 1:`DATA_WIDTH*80] <= fmr_doutb[8][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*82 - 1:`DATA_WIDTH*81] <= fmr_doutb[8][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*83 - 1:`DATA_WIDTH*82] <= fmr_doutb[8][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*84 - 1:`DATA_WIDTH*83] <= fmr_doutb[8][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*85 - 1:`DATA_WIDTH*84] <= fmr_doutb[8][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*86 - 1:`DATA_WIDTH*85] <= fmr_doutb[8][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*87 - 1:`DATA_WIDTH*86] <= fmr_doutb[8][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*88 - 1:`DATA_WIDTH*87] <= fmr_doutb[8][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*89 - 1:`DATA_WIDTH*88] <= fmr_doutb[8][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*90 - 1:`DATA_WIDTH*89] <= fmr_doutb[8][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[0][`DATA_WIDTH*91 - 1:`DATA_WIDTH*90] <= fmr_doutb[9][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*92 - 1:`DATA_WIDTH*91] <= fmr_doutb[9][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*93 - 1:`DATA_WIDTH*92] <= fmr_doutb[9][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*94 - 1:`DATA_WIDTH*93] <= fmr_doutb[9][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*95 - 1:`DATA_WIDTH*94] <= fmr_doutb[9][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*96 - 1:`DATA_WIDTH*95] <= fmr_doutb[9][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*97 - 1:`DATA_WIDTH*96] <= fmr_doutb[9][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*98 - 1:`DATA_WIDTH*97] <= fmr_doutb[9][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*99 - 1:`DATA_WIDTH*98] <= fmr_doutb[9][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*100 - 1:`DATA_WIDTH*99] <= fmr_doutb[9][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[0][`DATA_WIDTH*101 - 1:`DATA_WIDTH*100] <= fmr_doutb[10][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*102 - 1:`DATA_WIDTH*101] <= fmr_doutb[10][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*103 - 1:`DATA_WIDTH*102] <= fmr_doutb[10][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*104 - 1:`DATA_WIDTH*103] <= fmr_doutb[10][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*105 - 1:`DATA_WIDTH*104] <= fmr_doutb[10][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*106 - 1:`DATA_WIDTH*105] <= fmr_doutb[10][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*107 - 1:`DATA_WIDTH*106] <= fmr_doutb[10][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*108 - 1:`DATA_WIDTH*107] <= fmr_doutb[10][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*109 - 1:`DATA_WIDTH*108] <= fmr_doutb[10][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*110 - 1:`DATA_WIDTH*109] <= fmr_doutb[10][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[0][`DATA_WIDTH*111 - 1:`DATA_WIDTH*110] <= fmr_doutb[11][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*112 - 1:`DATA_WIDTH*111] <= fmr_doutb[11][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*113 - 1:`DATA_WIDTH*112] <= fmr_doutb[11][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*114 - 1:`DATA_WIDTH*113] <= fmr_doutb[11][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*115 - 1:`DATA_WIDTH*114] <= fmr_doutb[11][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*116 - 1:`DATA_WIDTH*115] <= fmr_doutb[11][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*117 - 1:`DATA_WIDTH*116] <= fmr_doutb[11][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*118 - 1:`DATA_WIDTH*117] <= fmr_doutb[11][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*119 - 1:`DATA_WIDTH*118] <= fmr_doutb[11][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*120 - 1:`DATA_WIDTH*119] <= fmr_doutb[11][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[0][`DATA_WIDTH*121 - 1:`DATA_WIDTH*120] <= fmr_doutb[12][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*122 - 1:`DATA_WIDTH*121] <= fmr_doutb[12][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*123 - 1:`DATA_WIDTH*122] <= fmr_doutb[12][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*124 - 1:`DATA_WIDTH*123] <= fmr_doutb[12][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*125 - 1:`DATA_WIDTH*124] <= fmr_doutb[12][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*126 - 1:`DATA_WIDTH*125] <= fmr_doutb[12][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*127 - 1:`DATA_WIDTH*126] <= fmr_doutb[12][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*128 - 1:`DATA_WIDTH*127] <= fmr_doutb[12][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*129 - 1:`DATA_WIDTH*128] <= fmr_doutb[12][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*130 - 1:`DATA_WIDTH*129] <= fmr_doutb[12][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[0][`DATA_WIDTH*131 - 1:`DATA_WIDTH*130] <= fmr_doutb[13][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*132 - 1:`DATA_WIDTH*131] <= fmr_doutb[13][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*133 - 1:`DATA_WIDTH*132] <= fmr_doutb[13][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*134 - 1:`DATA_WIDTH*133] <= fmr_doutb[13][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*135 - 1:`DATA_WIDTH*134] <= fmr_doutb[13][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*136 - 1:`DATA_WIDTH*135] <= fmr_doutb[13][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*137 - 1:`DATA_WIDTH*136] <= fmr_doutb[13][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*138 - 1:`DATA_WIDTH*137] <= fmr_doutb[13][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*139 - 1:`DATA_WIDTH*138] <= fmr_doutb[13][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*140 - 1:`DATA_WIDTH*139] <= fmr_doutb[13][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fmr_doutb[0][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= fmr_doutb[0][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= fmr_doutb[0][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] <= fmr_doutb[0][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] <= fmr_doutb[0][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5] <= fmr_doutb[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6] <= fmr_doutb[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7] <= fmr_doutb[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8] <= fmr_doutb[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9] <= fmr_doutb[0][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*11 - 1:`DATA_WIDTH*10] <= fmr_doutb[1][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*12 - 1:`DATA_WIDTH*11] <= fmr_doutb[1][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*13 - 1:`DATA_WIDTH*12] <= fmr_doutb[1][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*14 - 1:`DATA_WIDTH*13] <= fmr_doutb[1][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*15 - 1:`DATA_WIDTH*14] <= fmr_doutb[1][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*16 - 1:`DATA_WIDTH*15] <= fmr_doutb[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*17 - 1:`DATA_WIDTH*16] <= fmr_doutb[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*18 - 1:`DATA_WIDTH*17] <= fmr_doutb[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*19 - 1:`DATA_WIDTH*18] <= fmr_doutb[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*20 - 1:`DATA_WIDTH*19] <= fmr_doutb[1][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*21 - 1:`DATA_WIDTH*20] <= fmr_doutb[2][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*22 - 1:`DATA_WIDTH*21] <= fmr_doutb[2][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*23 - 1:`DATA_WIDTH*22] <= fmr_doutb[2][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*24 - 1:`DATA_WIDTH*23] <= fmr_doutb[2][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*25 - 1:`DATA_WIDTH*24] <= fmr_doutb[2][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*26 - 1:`DATA_WIDTH*25] <= fmr_doutb[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*27 - 1:`DATA_WIDTH*26] <= fmr_doutb[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*28 - 1:`DATA_WIDTH*27] <= fmr_doutb[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*29 - 1:`DATA_WIDTH*28] <= fmr_doutb[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*30 - 1:`DATA_WIDTH*29] <= fmr_doutb[2][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*31 - 1:`DATA_WIDTH*30] <= fmr_doutb[3][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*32 - 1:`DATA_WIDTH*31] <= fmr_doutb[3][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*33 - 1:`DATA_WIDTH*32] <= fmr_doutb[3][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*34 - 1:`DATA_WIDTH*33] <= fmr_doutb[3][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*35 - 1:`DATA_WIDTH*34] <= fmr_doutb[3][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*36 - 1:`DATA_WIDTH*35] <= fmr_doutb[3][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*37 - 1:`DATA_WIDTH*36] <= fmr_doutb[3][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*38 - 1:`DATA_WIDTH*37] <= fmr_doutb[3][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*39 - 1:`DATA_WIDTH*38] <= fmr_doutb[3][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*40 - 1:`DATA_WIDTH*39] <= fmr_doutb[3][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*41 - 1:`DATA_WIDTH*40] <= fmr_doutb[4][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*42 - 1:`DATA_WIDTH*41] <= fmr_doutb[4][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*43 - 1:`DATA_WIDTH*42] <= fmr_doutb[4][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*44 - 1:`DATA_WIDTH*43] <= fmr_doutb[4][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*45 - 1:`DATA_WIDTH*44] <= fmr_doutb[4][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*46 - 1:`DATA_WIDTH*45] <= fmr_doutb[4][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*47 - 1:`DATA_WIDTH*46] <= fmr_doutb[4][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*48 - 1:`DATA_WIDTH*47] <= fmr_doutb[4][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*49 - 1:`DATA_WIDTH*48] <= fmr_doutb[4][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*50 - 1:`DATA_WIDTH*49] <= fmr_doutb[4][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*51 - 1:`DATA_WIDTH*50] <= fmr_doutb[5][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*52 - 1:`DATA_WIDTH*51] <= fmr_doutb[5][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*53 - 1:`DATA_WIDTH*52] <= fmr_doutb[5][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*54 - 1:`DATA_WIDTH*53] <= fmr_doutb[5][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*55 - 1:`DATA_WIDTH*54] <= fmr_doutb[5][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*56 - 1:`DATA_WIDTH*55] <= fmr_doutb[5][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*57 - 1:`DATA_WIDTH*56] <= fmr_doutb[5][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*58 - 1:`DATA_WIDTH*57] <= fmr_doutb[5][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*59 - 1:`DATA_WIDTH*58] <= fmr_doutb[5][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*60 - 1:`DATA_WIDTH*59] <= fmr_doutb[5][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*61 - 1:`DATA_WIDTH*60] <= fmr_doutb[6][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*62 - 1:`DATA_WIDTH*61] <= fmr_doutb[6][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*63 - 1:`DATA_WIDTH*62] <= fmr_doutb[6][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*64 - 1:`DATA_WIDTH*63] <= fmr_doutb[6][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*65 - 1:`DATA_WIDTH*64] <= fmr_doutb[6][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*66 - 1:`DATA_WIDTH*65] <= fmr_doutb[6][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*67 - 1:`DATA_WIDTH*66] <= fmr_doutb[6][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*68 - 1:`DATA_WIDTH*67] <= fmr_doutb[6][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*69 - 1:`DATA_WIDTH*68] <= fmr_doutb[6][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*70 - 1:`DATA_WIDTH*69] <= fmr_doutb[6][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*71 - 1:`DATA_WIDTH*70] <= fmr_doutb[7][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*72 - 1:`DATA_WIDTH*71] <= fmr_doutb[7][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*73 - 1:`DATA_WIDTH*72] <= fmr_doutb[7][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*74 - 1:`DATA_WIDTH*73] <= fmr_doutb[7][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*75 - 1:`DATA_WIDTH*74] <= fmr_doutb[7][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*76 - 1:`DATA_WIDTH*75] <= fmr_doutb[7][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*77 - 1:`DATA_WIDTH*76] <= fmr_doutb[7][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*78 - 1:`DATA_WIDTH*77] <= fmr_doutb[7][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*79 - 1:`DATA_WIDTH*78] <= fmr_doutb[7][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*80 - 1:`DATA_WIDTH*79] <= fmr_doutb[7][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*81 - 1:`DATA_WIDTH*80] <= fmr_doutb[8][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*82 - 1:`DATA_WIDTH*81] <= fmr_doutb[8][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*83 - 1:`DATA_WIDTH*82] <= fmr_doutb[8][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*84 - 1:`DATA_WIDTH*83] <= fmr_doutb[8][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*85 - 1:`DATA_WIDTH*84] <= fmr_doutb[8][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*86 - 1:`DATA_WIDTH*85] <= fmr_doutb[8][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*87 - 1:`DATA_WIDTH*86] <= fmr_doutb[8][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*88 - 1:`DATA_WIDTH*87] <= fmr_doutb[8][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*89 - 1:`DATA_WIDTH*88] <= fmr_doutb[8][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*90 - 1:`DATA_WIDTH*89] <= fmr_doutb[8][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*91 - 1:`DATA_WIDTH*90] <= fmr_doutb[9][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*92 - 1:`DATA_WIDTH*91] <= fmr_doutb[9][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*93 - 1:`DATA_WIDTH*92] <= fmr_doutb[9][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*94 - 1:`DATA_WIDTH*93] <= fmr_doutb[9][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*95 - 1:`DATA_WIDTH*94] <= fmr_doutb[9][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*96 - 1:`DATA_WIDTH*95] <= fmr_doutb[9][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*97 - 1:`DATA_WIDTH*96] <= fmr_doutb[9][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*98 - 1:`DATA_WIDTH*97] <= fmr_doutb[9][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*99 - 1:`DATA_WIDTH*98] <= fmr_doutb[9][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*100 - 1:`DATA_WIDTH*99] <= fmr_doutb[9][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*101 - 1:`DATA_WIDTH*100] <= fmr_doutb[10][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*102 - 1:`DATA_WIDTH*101] <= fmr_doutb[10][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*103 - 1:`DATA_WIDTH*102] <= fmr_doutb[10][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*104 - 1:`DATA_WIDTH*103] <= fmr_doutb[10][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*105 - 1:`DATA_WIDTH*104] <= fmr_doutb[10][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*106 - 1:`DATA_WIDTH*105] <= fmr_doutb[10][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*107 - 1:`DATA_WIDTH*106] <= fmr_doutb[10][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*108 - 1:`DATA_WIDTH*107] <= fmr_doutb[10][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*109 - 1:`DATA_WIDTH*108] <= fmr_doutb[10][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*110 - 1:`DATA_WIDTH*109] <= fmr_doutb[10][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*111 - 1:`DATA_WIDTH*110] <= fmr_doutb[11][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*112 - 1:`DATA_WIDTH*111] <= fmr_doutb[11][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*113 - 1:`DATA_WIDTH*112] <= fmr_doutb[11][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*114 - 1:`DATA_WIDTH*113] <= fmr_doutb[11][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*115 - 1:`DATA_WIDTH*114] <= fmr_doutb[11][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*116 - 1:`DATA_WIDTH*115] <= fmr_doutb[11][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*117 - 1:`DATA_WIDTH*116] <= fmr_doutb[11][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*118 - 1:`DATA_WIDTH*117] <= fmr_doutb[11][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*119 - 1:`DATA_WIDTH*118] <= fmr_doutb[11][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*120 - 1:`DATA_WIDTH*119] <= fmr_doutb[11][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*121 - 1:`DATA_WIDTH*120] <= fmr_doutb[12][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*122 - 1:`DATA_WIDTH*121] <= fmr_doutb[12][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*123 - 1:`DATA_WIDTH*122] <= fmr_doutb[12][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*124 - 1:`DATA_WIDTH*123] <= fmr_doutb[12][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*125 - 1:`DATA_WIDTH*124] <= fmr_doutb[12][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*126 - 1:`DATA_WIDTH*125] <= fmr_doutb[12][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*127 - 1:`DATA_WIDTH*126] <= fmr_doutb[12][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*128 - 1:`DATA_WIDTH*127] <= fmr_doutb[12][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*129 - 1:`DATA_WIDTH*128] <= fmr_doutb[12][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*130 - 1:`DATA_WIDTH*129] <= fmr_doutb[12][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*131 - 1:`DATA_WIDTH*130] <= fmr_doutb[13][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*132 - 1:`DATA_WIDTH*131] <= fmr_doutb[13][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*133 - 1:`DATA_WIDTH*132] <= fmr_doutb[13][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*134 - 1:`DATA_WIDTH*133] <= fmr_doutb[13][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*135 - 1:`DATA_WIDTH*134] <= fmr_doutb[13][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*136 - 1:`DATA_WIDTH*135] <= fmr_doutb[13][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*137 - 1:`DATA_WIDTH*136] <= fmr_doutb[13][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*138 - 1:`DATA_WIDTH*137] <= fmr_doutb[13][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*139 - 1:`DATA_WIDTH*138] <= fmr_doutb[13][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*140 - 1:`DATA_WIDTH*139] <= fmr_doutb[13][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fmr_doutb[0][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= fmr_doutb[0][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= fmr_doutb[0][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] <= fmr_doutb[0][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] <= fmr_doutb[0][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5] <= fmr_doutb[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6] <= fmr_doutb[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7] <= fmr_doutb[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8] <= fmr_doutb[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9] <= fmr_doutb[0][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*11 - 1:`DATA_WIDTH*10] <= fmr_doutb[1][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*12 - 1:`DATA_WIDTH*11] <= fmr_doutb[1][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*13 - 1:`DATA_WIDTH*12] <= fmr_doutb[1][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*14 - 1:`DATA_WIDTH*13] <= fmr_doutb[1][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*15 - 1:`DATA_WIDTH*14] <= fmr_doutb[1][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*16 - 1:`DATA_WIDTH*15] <= fmr_doutb[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*17 - 1:`DATA_WIDTH*16] <= fmr_doutb[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*18 - 1:`DATA_WIDTH*17] <= fmr_doutb[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*19 - 1:`DATA_WIDTH*18] <= fmr_doutb[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*20 - 1:`DATA_WIDTH*19] <= fmr_doutb[1][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*21 - 1:`DATA_WIDTH*20] <= fmr_doutb[2][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*22 - 1:`DATA_WIDTH*21] <= fmr_doutb[2][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*23 - 1:`DATA_WIDTH*22] <= fmr_doutb[2][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*24 - 1:`DATA_WIDTH*23] <= fmr_doutb[2][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*25 - 1:`DATA_WIDTH*24] <= fmr_doutb[2][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*26 - 1:`DATA_WIDTH*25] <= fmr_doutb[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*27 - 1:`DATA_WIDTH*26] <= fmr_doutb[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*28 - 1:`DATA_WIDTH*27] <= fmr_doutb[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*29 - 1:`DATA_WIDTH*28] <= fmr_doutb[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*30 - 1:`DATA_WIDTH*29] <= fmr_doutb[2][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*31 - 1:`DATA_WIDTH*30] <= fmr_doutb[3][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*32 - 1:`DATA_WIDTH*31] <= fmr_doutb[3][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*33 - 1:`DATA_WIDTH*32] <= fmr_doutb[3][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*34 - 1:`DATA_WIDTH*33] <= fmr_doutb[3][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*35 - 1:`DATA_WIDTH*34] <= fmr_doutb[3][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*36 - 1:`DATA_WIDTH*35] <= fmr_doutb[3][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*37 - 1:`DATA_WIDTH*36] <= fmr_doutb[3][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*38 - 1:`DATA_WIDTH*37] <= fmr_doutb[3][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*39 - 1:`DATA_WIDTH*38] <= fmr_doutb[3][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*40 - 1:`DATA_WIDTH*39] <= fmr_doutb[3][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*41 - 1:`DATA_WIDTH*40] <= fmr_doutb[4][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*42 - 1:`DATA_WIDTH*41] <= fmr_doutb[4][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*43 - 1:`DATA_WIDTH*42] <= fmr_doutb[4][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*44 - 1:`DATA_WIDTH*43] <= fmr_doutb[4][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*45 - 1:`DATA_WIDTH*44] <= fmr_doutb[4][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*46 - 1:`DATA_WIDTH*45] <= fmr_doutb[4][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*47 - 1:`DATA_WIDTH*46] <= fmr_doutb[4][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*48 - 1:`DATA_WIDTH*47] <= fmr_doutb[4][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*49 - 1:`DATA_WIDTH*48] <= fmr_doutb[4][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*50 - 1:`DATA_WIDTH*49] <= fmr_doutb[4][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*51 - 1:`DATA_WIDTH*50] <= fmr_doutb[5][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*52 - 1:`DATA_WIDTH*51] <= fmr_doutb[5][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*53 - 1:`DATA_WIDTH*52] <= fmr_doutb[5][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*54 - 1:`DATA_WIDTH*53] <= fmr_doutb[5][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*55 - 1:`DATA_WIDTH*54] <= fmr_doutb[5][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*56 - 1:`DATA_WIDTH*55] <= fmr_doutb[5][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*57 - 1:`DATA_WIDTH*56] <= fmr_doutb[5][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*58 - 1:`DATA_WIDTH*57] <= fmr_doutb[5][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*59 - 1:`DATA_WIDTH*58] <= fmr_doutb[5][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*60 - 1:`DATA_WIDTH*59] <= fmr_doutb[5][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*61 - 1:`DATA_WIDTH*60] <= fmr_doutb[6][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*62 - 1:`DATA_WIDTH*61] <= fmr_doutb[6][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*63 - 1:`DATA_WIDTH*62] <= fmr_doutb[6][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*64 - 1:`DATA_WIDTH*63] <= fmr_doutb[6][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*65 - 1:`DATA_WIDTH*64] <= fmr_doutb[6][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*66 - 1:`DATA_WIDTH*65] <= fmr_doutb[6][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*67 - 1:`DATA_WIDTH*66] <= fmr_doutb[6][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*68 - 1:`DATA_WIDTH*67] <= fmr_doutb[6][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*69 - 1:`DATA_WIDTH*68] <= fmr_doutb[6][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*70 - 1:`DATA_WIDTH*69] <= fmr_doutb[6][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*71 - 1:`DATA_WIDTH*70] <= fmr_doutb[7][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*72 - 1:`DATA_WIDTH*71] <= fmr_doutb[7][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*73 - 1:`DATA_WIDTH*72] <= fmr_doutb[7][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*74 - 1:`DATA_WIDTH*73] <= fmr_doutb[7][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*75 - 1:`DATA_WIDTH*74] <= fmr_doutb[7][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*76 - 1:`DATA_WIDTH*75] <= fmr_doutb[7][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*77 - 1:`DATA_WIDTH*76] <= fmr_doutb[7][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*78 - 1:`DATA_WIDTH*77] <= fmr_doutb[7][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*79 - 1:`DATA_WIDTH*78] <= fmr_doutb[7][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*80 - 1:`DATA_WIDTH*79] <= fmr_doutb[7][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*81 - 1:`DATA_WIDTH*80] <= fmr_doutb[8][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*82 - 1:`DATA_WIDTH*81] <= fmr_doutb[8][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*83 - 1:`DATA_WIDTH*82] <= fmr_doutb[8][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*84 - 1:`DATA_WIDTH*83] <= fmr_doutb[8][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*85 - 1:`DATA_WIDTH*84] <= fmr_doutb[8][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*86 - 1:`DATA_WIDTH*85] <= fmr_doutb[8][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*87 - 1:`DATA_WIDTH*86] <= fmr_doutb[8][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*88 - 1:`DATA_WIDTH*87] <= fmr_doutb[8][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*89 - 1:`DATA_WIDTH*88] <= fmr_doutb[8][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*90 - 1:`DATA_WIDTH*89] <= fmr_doutb[8][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*91 - 1:`DATA_WIDTH*90] <= fmr_doutb[9][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*92 - 1:`DATA_WIDTH*91] <= fmr_doutb[9][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*93 - 1:`DATA_WIDTH*92] <= fmr_doutb[9][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*94 - 1:`DATA_WIDTH*93] <= fmr_doutb[9][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*95 - 1:`DATA_WIDTH*94] <= fmr_doutb[9][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*96 - 1:`DATA_WIDTH*95] <= fmr_doutb[9][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*97 - 1:`DATA_WIDTH*96] <= fmr_doutb[9][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*98 - 1:`DATA_WIDTH*97] <= fmr_doutb[9][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*99 - 1:`DATA_WIDTH*98] <= fmr_doutb[9][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*100 - 1:`DATA_WIDTH*99] <= fmr_doutb[9][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*101 - 1:`DATA_WIDTH*100] <= fmr_doutb[10][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*102 - 1:`DATA_WIDTH*101] <= fmr_doutb[10][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*103 - 1:`DATA_WIDTH*102] <= fmr_doutb[10][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*104 - 1:`DATA_WIDTH*103] <= fmr_doutb[10][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*105 - 1:`DATA_WIDTH*104] <= fmr_doutb[10][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*106 - 1:`DATA_WIDTH*105] <= fmr_doutb[10][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*107 - 1:`DATA_WIDTH*106] <= fmr_doutb[10][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*108 - 1:`DATA_WIDTH*107] <= fmr_doutb[10][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*109 - 1:`DATA_WIDTH*108] <= fmr_doutb[10][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*110 - 1:`DATA_WIDTH*109] <= fmr_doutb[10][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*111 - 1:`DATA_WIDTH*110] <= fmr_doutb[11][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*112 - 1:`DATA_WIDTH*111] <= fmr_doutb[11][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*113 - 1:`DATA_WIDTH*112] <= fmr_doutb[11][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*114 - 1:`DATA_WIDTH*113] <= fmr_doutb[11][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*115 - 1:`DATA_WIDTH*114] <= fmr_doutb[11][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*116 - 1:`DATA_WIDTH*115] <= fmr_doutb[11][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*117 - 1:`DATA_WIDTH*116] <= fmr_doutb[11][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*118 - 1:`DATA_WIDTH*117] <= fmr_doutb[11][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*119 - 1:`DATA_WIDTH*118] <= fmr_doutb[11][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*120 - 1:`DATA_WIDTH*119] <= fmr_doutb[11][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*121 - 1:`DATA_WIDTH*120] <= fmr_doutb[12][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*122 - 1:`DATA_WIDTH*121] <= fmr_doutb[12][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*123 - 1:`DATA_WIDTH*122] <= fmr_doutb[12][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*124 - 1:`DATA_WIDTH*123] <= fmr_doutb[12][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*125 - 1:`DATA_WIDTH*124] <= fmr_doutb[12][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*126 - 1:`DATA_WIDTH*125] <= fmr_doutb[12][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*127 - 1:`DATA_WIDTH*126] <= fmr_doutb[12][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*128 - 1:`DATA_WIDTH*127] <= fmr_doutb[12][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*129 - 1:`DATA_WIDTH*128] <= fmr_doutb[12][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*130 - 1:`DATA_WIDTH*129] <= fmr_doutb[12][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*131 - 1:`DATA_WIDTH*130] <= fmr_doutb[13][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*132 - 1:`DATA_WIDTH*131] <= fmr_doutb[13][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*133 - 1:`DATA_WIDTH*132] <= fmr_doutb[13][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*134 - 1:`DATA_WIDTH*133] <= fmr_doutb[13][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*135 - 1:`DATA_WIDTH*134] <= fmr_doutb[13][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*136 - 1:`DATA_WIDTH*135] <= fmr_doutb[13][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*137 - 1:`DATA_WIDTH*136] <= fmr_doutb[13][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*138 - 1:`DATA_WIDTH*137] <= fmr_doutb[13][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*139 - 1:`DATA_WIDTH*138] <= fmr_doutb[13][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*140 - 1:`DATA_WIDTH*139] <= fmr_doutb[13][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										// ======== End: set fm ram read data ========

										clk_count <= clk_count + 1;
									end
									else if (clk_count > 1 && clk_count <= kernel_size) begin
										// ======== Begin: set fm ram read data ========
										// PARA_KERNEL -> PARA_X
										conv_input_data[0][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fmr_doutb[0][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= fmr_doutb[1][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= fmr_doutb[2][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] <= fmr_doutb[3][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] <= fmr_doutb[4][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[0][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5] <= fmr_doutb[5][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[0][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6] <= fmr_doutb[6][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[0][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7] <= fmr_doutb[7][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[0][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8] <= fmr_doutb[8][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[0][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9] <= fmr_doutb[9][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[0][`DATA_WIDTH*11 - 1:`DATA_WIDTH*10] <= fmr_doutb[10][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[0][`DATA_WIDTH*12 - 1:`DATA_WIDTH*11] <= fmr_doutb[11][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[0][`DATA_WIDTH*13 - 1:`DATA_WIDTH*12] <= fmr_doutb[12][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[0][`DATA_WIDTH*14 - 1:`DATA_WIDTH*13] <= fmr_doutb[13][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fmr_doutb[0][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= fmr_doutb[1][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= fmr_doutb[2][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] <= fmr_doutb[3][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] <= fmr_doutb[4][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[1][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5] <= fmr_doutb[5][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[1][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6] <= fmr_doutb[6][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[1][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7] <= fmr_doutb[7][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[1][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8] <= fmr_doutb[8][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[1][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9] <= fmr_doutb[9][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[1][`DATA_WIDTH*11 - 1:`DATA_WIDTH*10] <= fmr_doutb[10][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[1][`DATA_WIDTH*12 - 1:`DATA_WIDTH*11] <= fmr_doutb[11][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[1][`DATA_WIDTH*13 - 1:`DATA_WIDTH*12] <= fmr_doutb[12][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[1][`DATA_WIDTH*14 - 1:`DATA_WIDTH*13] <= fmr_doutb[13][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fmr_doutb[0][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= fmr_doutb[1][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= fmr_doutb[2][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] <= fmr_doutb[3][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] <= fmr_doutb[4][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[2][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5] <= fmr_doutb[5][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[2][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6] <= fmr_doutb[6][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[2][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7] <= fmr_doutb[7][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[2][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8] <= fmr_doutb[8][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[2][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9] <= fmr_doutb[9][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[2][`DATA_WIDTH*11 - 1:`DATA_WIDTH*10] <= fmr_doutb[10][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[2][`DATA_WIDTH*12 - 1:`DATA_WIDTH*11] <= fmr_doutb[11][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[2][`DATA_WIDTH*13 - 1:`DATA_WIDTH*12] <= fmr_doutb[12][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[2][`DATA_WIDTH*14 - 1:`DATA_WIDTH*13] <= fmr_doutb[13][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										// ======== End: set fm ram read data ========

										clk_count	<= clk_count + 1;
									end
									else if ((clk_count-(clk_count/kernel_size)*kernel_size) == 1 && clk_count <= (kernel_size*kernel_size)) begin
										// ======== Begin: set fm ram read data ========
										// PARA_KERNEL -> PARA_Y
										conv_input_data[0][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[0][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[0][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[0][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[0][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[0][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[1][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[1][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[1][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[1][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[1][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[1][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 

										conv_input_data[2][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]; 
										conv_input_data[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8]; 
										conv_input_data[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7]; 
										conv_input_data[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6]; 
										conv_input_data[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5]; 
										conv_input_data[2][`DATA_WIDTH*6 - 1:`DATA_WIDTH*5] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4]; 
										conv_input_data[2][`DATA_WIDTH*7 - 1:`DATA_WIDTH*6] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3]; 
										conv_input_data[2][`DATA_WIDTH*8 - 1:`DATA_WIDTH*7] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2]; 
										conv_input_data[2][`DATA_WIDTH*9 - 1:`DATA_WIDTH*8] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1]; 
										conv_input_data[2][`DATA_WIDTH*10 - 1:`DATA_WIDTH*9] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										// ======== End: set fm ram read data ========

										clk_count	<= clk_count + 1;
									end
									else if (clk_count <= (kernel_size*kernel_size)) begin
										// ======== Begin: set fm ram read data ========
										// PARA_KERNEL
										conv_input_data[0][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[1][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										conv_input_data[2][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0]; 
										// ======== End: set fm ram read data ========

										clk_count	<= clk_count + 1;
									end
									else begin
										if (&conv_out_ready == 1) begin
											clk_count <= 0;

											if (zero_write_count == 1) begin // write conv result
													// write to conv buffer
													// todo

													// ======== Begin: set fm ram write ========
													// PARA_X
													// todo save to buffer
													/*fm_ena_add_write[0] <= 1;
													fm_ena_w[0] 		<= 0;
													fm_ena_para_w[0] 	<= 1;
													fm_addr_para_write[0] <= fm_zero_start_addr[0] 
																			+ cur_out_slice*((fm_size_out+`PARA_X-1)/`PARA_X)*(((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y) 
																			+ cur_out_index[0]; 
													fm_out_size[0] <= fm_size_out; 

													fm_para_din[(cur_write_start_ram+0)-((cur_write_start_ram+0)/`PARA_X)*`PARA_X] <= {
																		conv_out_buffer[1][`PARA_Y*1*`DATA_WIDTH - 1:`PARA_Y*0*`DATA_WIDTH],
																		conv_out_buffer[0][`PARA_Y*1*`DATA_WIDTH - 1:`PARA_Y*0*`DATA_WIDTH]
																	}; 

													fm_ena_add_write[1] <= 1;
													fm_ena_w[1] 		<= 0;
													fm_ena_para_w[1] 	<= 1;
													fm_addr_para_write[1] <= fm_zero_start_addr[1] 
																			+ cur_out_slice*((fm_size_out+`PARA_X-1)/`PARA_X)*(((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y) 
																			+ cur_out_index[1]; 
													fm_out_size[1] <= fm_size_out; 

													fm_para_din[(cur_write_start_ram+1)-((cur_write_start_ram+1)/`PARA_X)*`PARA_X] <= {
																		conv_out_buffer[1][`PARA_Y*2*`DATA_WIDTH - 1:`PARA_Y*1*`DATA_WIDTH],
																		conv_out_buffer[0][`PARA_Y*2*`DATA_WIDTH - 1:`PARA_Y*1*`DATA_WIDTH]
																	}; 

													fm_ena_add_write[2] <= 1;
													fm_ena_w[2] 		<= 0;
													fm_ena_para_w[2] 	<= 1;
													fm_addr_para_write[2] <= fm_zero_start_addr[2] 
																			+ cur_out_slice*((fm_size_out+`PARA_X-1)/`PARA_X)*(((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y) 
																			+ cur_out_index[2]; 
													fm_out_size[2] <= fm_size_out; 

													fm_para_din[(cur_write_start_ram+2)-((cur_write_start_ram+2)/`PARA_X)*`PARA_X] <= {
																		conv_out_buffer[1][`PARA_Y*3*`DATA_WIDTH - 1:`PARA_Y*2*`DATA_WIDTH],
																		conv_out_buffer[0][`PARA_Y*3*`DATA_WIDTH - 1:`PARA_Y*2*`DATA_WIDTH]
																	}; */
													// ======== End: set fm ram write ========
												
											end
											
											if ((cur_y + kernel_size + `PARA_Y - 1) < fm_size) begin
												cur_y <= cur_y + `PARA_Y; // next para window y

												// ======== Begin: set fm ram write ========
												// PARA_X
												cur_out_index[0] <= cur_out_index[0] + `PARA_Y; 
												cur_out_index[1] <= cur_out_index[1] + `PARA_Y; 
												cur_out_index[2] <= cur_out_index[2] + `PARA_Y; 
												cur_out_index[3] <= cur_out_index[3] + `PARA_Y; 
												cur_out_index[4] <= cur_out_index[4] + `PARA_Y; 
												cur_out_index[5] <= cur_out_index[5] + `PARA_Y; 
												cur_out_index[6] <= cur_out_index[6] + `PARA_Y; 
												cur_out_index[7] <= cur_out_index[7] + `PARA_Y; 
												cur_out_index[8] <= cur_out_index[8] + `PARA_Y; 
												cur_out_index[9] <= cur_out_index[9] + `PARA_Y; 
												cur_out_index[10] <= cur_out_index[10] + `PARA_Y; 
												cur_out_index[11] <= cur_out_index[11] + `PARA_Y; 
												cur_out_index[12] <= cur_out_index[12] + `PARA_Y; 
												cur_out_index[13] <= cur_out_index[13] + `PARA_Y; 
												// ======== End: set fm ram write ========
											end
											else begin
												cur_y <= 0;

												if ((cur_x + kernel_size + `PARA_X - 1) <fm_size ) begin
													cur_x <= cur_x + `PARA_X; // next para window x

													// ======== Begin: set fm ram write ========
													// PARA_X
													cur_out_index[0] <= (((cur_out_index[0] + `PARA_Y + padding_out)+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
													cur_out_index[1] <= (((cur_out_index[1] + `PARA_Y + padding_out)+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
													cur_out_index[2] <= (((cur_out_index[2] + `PARA_Y + padding_out)+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
													cur_out_index[3] <= (((cur_out_index[3] + `PARA_Y + padding_out)+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
													cur_out_index[4] <= (((cur_out_index[4] + `PARA_Y + padding_out)+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
													cur_out_index[5] <= (((cur_out_index[5] + `PARA_Y + padding_out)+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
													cur_out_index[6] <= (((cur_out_index[6] + `PARA_Y + padding_out)+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
													cur_out_index[7] <= (((cur_out_index[7] + `PARA_Y + padding_out)+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
													cur_out_index[8] <= (((cur_out_index[8] + `PARA_Y + padding_out)+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
													cur_out_index[9] <= (((cur_out_index[9] + `PARA_Y + padding_out)+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
													cur_out_index[10] <= (((cur_out_index[10] + `PARA_Y + padding_out)+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
													cur_out_index[11] <= (((cur_out_index[11] + `PARA_Y + padding_out)+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
													cur_out_index[12] <= (((cur_out_index[12] + `PARA_Y + padding_out)+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
													cur_out_index[13] <= (((cur_out_index[13] + `PARA_Y + padding_out)+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
													// ======== End: set fm ram write ========
												end
												else begin 
													if (cur_slice == (fm_depth - 1)) begin // next para kernel or conv end
														cur_slice	<= 0; 
														cur_x		<= 0;
														cur_y		<= 0;

														if ((kernel_num_count + `PARA_KERNEL) >= kernel_num) begin // conv layer end, next layer
															cur_kernel_swap		<= ~cur_kernel_swap; 
															cur_kernel_slice	<= 0;

															// update kernel
															update_weight_ram		<= 1;
															update_weight_ram_addr	<= cur_kernel_swap*`WEIGHT_RAM_HALF;
															update_weight_wait_count<= 0;

															go_to_next_layer <= 1;

															// ======== Begin: set conv buffer write to feature map ram ========
															// todo, just set signal, catch signal outside and do writing, swap buffer
															buffer_to_fm_ram <= 1;
															// ======== End: set conv buffer write to feature map ram ========
															write_ready_clk_count <= 1;
														end
														else begin
															kernel_num_count	<= kernel_num_count + `PARA_KERNEL; // next para kernel
															cur_kernel_swap		<= ~cur_kernel_swap; 
															cur_kernel_slice	<= 0;

															// update kernel
															update_weight_ram		<= 1;
															update_weight_ram_addr	<= cur_kernel_swap*`WEIGHT_RAM_HALF;
															update_weight_wait_count<= 0;

															// ======== Begin: set fm ram write ========
															// PARA_X
															cur_out_index[0]	<= ((padding_out-0+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
															cur_out_index[1]	<= ((padding_out-1+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
															cur_out_index[2]	<= ((padding_out-2+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
															cur_out_index[3]	<= ((padding_out-3+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
															cur_out_index[4]	<= ((padding_out-4+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
															cur_out_index[5]	<= ((padding_out-5+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
															cur_out_index[6]	<= ((padding_out-6+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
															cur_out_index[7]	<= ((padding_out-7+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
															cur_out_index[8]	<= ((padding_out-8+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
															cur_out_index[9]	<= ((padding_out-9+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
															cur_out_index[10]	<= ((padding_out-10+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
															cur_out_index[11]	<= ((padding_out-11+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
															cur_out_index[12]	<= ((padding_out-12+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
															cur_out_index[13]	<= ((padding_out-13+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
															// ======== End: set fm ram write ========

															// ======== Begin: set conv buffer write to feature map ram ========
															// todo, just set signal, catch signal outside and do writing, swap buffer
															buffer_to_fm_ram <= 1;
															// ======== End: set conv buffer write to feature map ram ========
															write_ready_clk_count <= 1;

															cur_out_slice 		<= cur_out_slice + `PARA_KERNEL;
														end
													end
													else begin
														cur_slice	<= cur_slice + 1; // next feature map slice
														cur_x		<= 0;
														cur_y		<= 0;

														// ======== Begin: set fm ram write ========
														// PARA_X
														cur_out_index[0]	<= ((padding_out-0+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
														cur_out_index[1]	<= ((padding_out-1+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
														cur_out_index[2]	<= ((padding_out-2+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
														cur_out_index[3]	<= ((padding_out-3+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
														cur_out_index[4]	<= ((padding_out-4+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
														cur_out_index[5]	<= ((padding_out-5+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
														cur_out_index[6]	<= ((padding_out-6+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
														cur_out_index[7]	<= ((padding_out-7+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
														cur_out_index[8]	<= ((padding_out-8+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
														cur_out_index[9]	<= ((padding_out-9+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
														cur_out_index[10]	<= ((padding_out-10+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
														cur_out_index[11]	<= ((padding_out-11+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
														cur_out_index[12]	<= ((padding_out-12+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
														cur_out_index[13]	<= ((padding_out-13+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 
														// ======== End: set fm ram write ========

														cur_kernel_slice	<= cur_kernel_slice + 1; // next kernel slice
													end
												end
											end
										end
										else begin
											clk_count <= clk_count + 1;
										end
									end
								end

								// write conv buffer to fm ram
								// todo 
								if (buffer_to_fm_ram == 1) begin
									if (buffer_write_count <= (fm_size_out*fm_size_out*`PARA_KERNEL/(`PARA_X*`PARA_Y))) begin
										buffer_write_count <= buffer_write_count + 1;
									end
									else begin
										buffer_to_fm_ram <= 0;
										buffer_write_count <= 0;
									end
								end

								// todo, wait for the last slices writing
								if(write_ready_clk_count == 1) begin
									write_ready_clk_count <= 2;
								end
								else if(write_ready_clk_count == 2) begin
									if(buffer_to_fm_ram == 0) begin
									//if (&fm_write_ready == 1) begin
										// ======== Begin: disable fm ram write ========
										// PARA_X
										fmr_ena[0]	<= 0;
										fmr_wea[0]	<= 0;

										fmr_ena[1]	<= 0;
										fmr_wea[1]	<= 0;

										fmr_ena[2]	<= 0;
										fmr_wea[2]	<= 0;

										fmr_ena[3]	<= 0;
										fmr_wea[3]	<= 0;

										fmr_ena[4]	<= 0;
										fmr_wea[4]	<= 0;

										fmr_ena[5]	<= 0;
										fmr_wea[5]	<= 0;

										fmr_ena[6]	<= 0;
										fmr_wea[6]	<= 0;

										fmr_ena[7]	<= 0;
										fmr_wea[7]	<= 0;

										fmr_ena[8]	<= 0;
										fmr_wea[8]	<= 0;

										fmr_ena[9]	<= 0;
										fmr_wea[9]	<= 0;

										fmr_ena[10]	<= 0;
										fmr_wea[10]	<= 0;

										fmr_ena[11]	<= 0;
										fmr_wea[11]	<= 0;

										fmr_ena[12]	<= 0;
										fmr_wea[12]	<= 0;

										fmr_ena[13]	<= 0;
										fmr_wea[13]	<= 0;
										// ======== End: disable fm ram write ========

										write_ready_clk_count <= 0;

										// conv layer end, next layer 
										if (go_to_next_layer == 1) begin
											conv_rst	<= 0;

											kernel_num_count	<= 0;
											cur_fm_swap			<= ~cur_fm_swap;

											cur_x		<= 0;
											cur_y		<= 0;
											cur_slice	<= 0;
											cur_fm_ram	<= 0;

											// ======== Begin: reset fm ram write ========
											// PARA_X
											cur_out_index[0]	<= 0; 
											cur_out_index[1]	<= 0; 
											cur_out_index[2]	<= 0; 
											cur_out_index[3]	<= 0; 
											cur_out_index[4]	<= 0; 
											cur_out_index[5]	<= 0; 
											cur_out_index[6]	<= 0; 
											cur_out_index[7]	<= 0; 
											cur_out_index[8]	<= 0; 
											cur_out_index[9]	<= 0; 
											cur_out_index[10]	<= 0; 
											cur_out_index[11]	<= 0; 
											cur_out_index[12]	<= 0; 
											cur_out_index[13]	<= 0; 
											// ======== End: reset fm ram write ========

											cur_out_slice		<= 0;
											zero_write_count	<= 0;

											clk_count	<= 0;
											layer_ready	<= 1;
										end
									end
								end
							end
						2:// pool
							begin
								// todo:
								// 1、set read address and read data after 1 clk
								// 2、select PARA_Y data from dout to pool unit
								// 3、write result to fmr

								data_num <= pool_win_size*pool_win_size;

								fm_read_type	<= 1;
								// ======== Begin: set fm ram read ========
								// PARA_X
								fmr_enb[0]	<= 1; 
								fmr_enb[1]	<= 1; 
								fmr_enb[2]	<= 1; 
								fmr_enb[3]	<= 1; 
								fmr_enb[4]	<= 1; 
								fmr_enb[5]	<= 1; 
								fmr_enb[6]	<= 1; 
								fmr_enb[7]	<= 1; 
								fmr_enb[8]	<= 1; 
								fmr_enb[9]	<= 1; 
								fmr_enb[10]	<= 1; 
								fmr_enb[11]	<= 1; 
								fmr_enb[12]	<= 1; 
								fmr_enb[13]	<= 1; 
								// ======== End: set fm ram read ========

								// disable weight ram read 
								wr_enb	<= 0;

								// prepare output ram
								if (zero_write_count == 0) begin // prepare zero padding
									// ======== Begin: set conv buffer zero write ========
									// PARA_KERNEL
									// todo
									// buffer_x_y
									// ======== End: set conv buffer zero write ========

									cur_write_start_ram	<= padding_out-(padding_out/`PARA_X)*`PARA_X;
									cur_write_end_ram	<= fm_size_out-(fm_size_out/`PARA_X)*`PARA_X;
									zero_write_count	<= 1;
								end

								// read fm data
								if (clk_count > 0 && clk_count <= pool_win_size*pool_win_size) begin
									pool_input_data <= fmr_doutb[cur_fm_ram];
								end

								// set pool read address
								if (clk_count == 0) begin // set init pool read address
									if (go_to_next_layer == 0) begin
										//fmr_addrb[cur_fm_ram]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[cur_fm_ram] <= 0; // test

										pu_rst <= 0;

										clk_count <= clk_count + 1;
									end
								end
								else begin
									pu_rst <= 1;

									if((clk_count-(clk_count/pool_win_size)*pool_win_size) == 0 && clk_count < pool_win_size*pool_win_size) begin
										// next pool line, go to next fm ram
										cur_fm_ram	<= (cur_fm_ram+1) - ((cur_fm_ram+1)/`PARA_X)*`PARA_X;
										cur_x		<= cur_x + 1;

										fmr_addrb[(cur_fm_ram+1) - ((cur_fm_ram+1)/`PARA_X)*`PARA_X] <= cur_fm_swap*`FM_RAM_HALF + (cur_x+1)/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);

										clk_count <= clk_count + 1;
									end
									else if(clk_count <= pool_win_size*pool_win_size) begin
										fmr_addrb[cur_fm_ram] <= fmr_addrb[cur_fm_ram] + 1;

										clk_count <= clk_count + 1;
									end
									else begin
										// pool result ready
										if (&pu_out_ready == 1) begin
											clk_count<= 0;

											// write to fm ram
											if (zero_write_count == 1) begin
												// ======== Begin: set fm ram write ========
												// PARA_X
												fmr_ena[0]	<= 1;
												fmr_wea[0]	<= 1;

												fmr_ena[1]	<= 1;
												fmr_wea[1]	<= 1;

												fmr_ena[2]	<= 1;
												fmr_wea[2]	<= 1;

												fmr_ena[3]	<= 1;
												fmr_wea[3]	<= 1;

												fmr_ena[4]	<= 1;
												fmr_wea[4]	<= 1;

												fmr_ena[5]	<= 1;
												fmr_wea[5]	<= 1;

												fmr_ena[6]	<= 1;
												fmr_wea[6]	<= 1;

												fmr_ena[7]	<= 1;
												fmr_wea[7]	<= 1;

												fmr_ena[8]	<= 1;
												fmr_wea[8]	<= 1;

												fmr_ena[9]	<= 1;
												fmr_wea[9]	<= 1;

												fmr_ena[10]	<= 1;
												fmr_wea[10]	<= 1;

												fmr_ena[11]	<= 1;
												fmr_wea[11]	<= 1;

												fmr_ena[12]	<= 1;
												fmr_wea[12]	<= 1;

												fmr_ena[13]	<= 1;
												fmr_wea[13]	<= 1;
												// ======== End: set fm ram write ========

												fmr_addrb[cur_out_fm_ram] <= fm_zero_start_addr[cur_out_fm_ram] 
																				+ cur_out_slice*((fm_size_out+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)
																				+ cur_out_index[cur_out_fm_ram];

												if (cur_y < fm_size && cur_y + pool_win_size*`PARA_Y >= fm_size) begin
													
													case((fm_size-cur_y)/pool_win_size)
														// ======== Begin: set fm ram write ========
														// `PARA_Y-1
														1:
															begin
																fmr_dina[cur_out_fm_ram] <= {0, pu_result[`DATA_WIDTH*1-1:0]};
															end
														2:
															begin
																fmr_dina[cur_out_fm_ram] <= {0, pu_result[`DATA_WIDTH*2-1:0]};
															end
														3:
															begin
																fmr_dina[cur_out_fm_ram] <= {0, pu_result[`DATA_WIDTH*3-1:0]};
															end
														4:
															begin
																fmr_dina[cur_out_fm_ram] <= {0, pu_result[`DATA_WIDTH*4-1:0]};
															end
														5:
															begin
																fmr_dina[cur_out_fm_ram] <= {0, pu_result[`DATA_WIDTH*5-1:0]};
															end
														6:
															begin
																fmr_dina[cur_out_fm_ram] <= {0, pu_result[`DATA_WIDTH*6-1:0]};
															end
														7:
															begin
																fmr_dina[cur_out_fm_ram] <= {0, pu_result[`DATA_WIDTH*7-1:0]};
															end
														8:
															begin
																fmr_dina[cur_out_fm_ram] <= {0, pu_result[`DATA_WIDTH*8-1:0]};
															end
														9:
															begin
																fmr_dina[cur_out_fm_ram] <= {0, pu_result[`DATA_WIDTH*9-1:0]};
															end
														// ======== End: set fm ram write ========
													endcase
												end
												else begin
													fmr_dina[cur_out_fm_ram] <= pu_result;
												end
											end

											// update pool read address
											if ((cur_y + pool_win_size + `PARA_Y - 1) < fm_size) begin // next para window y
												// read
												cur_x <= cur_x-(pool_win_size-1);
												cur_y <= cur_y + (pool_win_size*`PARA_Y);
												cur_fm_ram <= (cur_x-(pool_win_size-1))-((cur_x-(pool_win_size-1))/`PARA_X)*`PARA_X;

												// write
												cur_out_index[cur_out_fm_ram] <= cur_out_index[cur_out_fm_ram] + 1;
											end
											else begin
												cur_y <= 0;

												if ((cur_x + pool_win_size - 1) < fm_size) begin // next para window line(x)
													// read
													cur_x <= cur_x + 1;
													cur_fm_ram <= (cur_x+1)-((cur_x+1)/`PARA_X)*`PARA_X;

													// write
													cur_out_fm_ram <= (cur_out_fm_ram+1)-((cur_out_fm_ram+1)/`PARA_X)*`PARA_X;
													cur_out_index[cur_out_fm_ram] <= cur_out_index[cur_out_fm_ram] + 1;
												end
												else begin
													if (cur_slice >= (fm_depth - 1)) begin // pool end, next layer
														cur_slice 		<= 0;
														cur_x 			<= 0;
														cur_y 			<= 0;
														cur_fm_ram		<= 0;
														cur_out_fm_ram	<= 0;

														go_to_next_layer <= 1;
													end
													else begin // next slice
														// read
														cur_slice 	<= cur_slice + 1;
														cur_x 		<= 0;
														cur_y 		<= 0;
														cur_fm_ram	<= 0;

														// write
														cur_out_slice 		<= cur_out_slice + 1;

														// no padding
														// ======== Begin: set fm ram write ========
														// PARA_X
														cur_out_index[0] 	<= ((padding_out-0+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y); 
														cur_out_index[1] 	<= ((padding_out-1+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y); 
														cur_out_index[2] 	<= ((padding_out-2+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y); 
														cur_out_index[3] 	<= ((padding_out-3+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y); 
														cur_out_index[4] 	<= ((padding_out-4+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y); 
														cur_out_index[5] 	<= ((padding_out-5+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y); 
														cur_out_index[6] 	<= ((padding_out-6+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y); 
														cur_out_index[7] 	<= ((padding_out-7+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y); 
														cur_out_index[8] 	<= ((padding_out-8+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y); 
														cur_out_index[9] 	<= ((padding_out-9+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y); 
														cur_out_index[10] 	<= ((padding_out-10+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y); 
														cur_out_index[11] 	<= ((padding_out-11+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y); 
														cur_out_index[12] 	<= ((padding_out-12+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y); 
														cur_out_index[13] 	<= ((padding_out-13+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y); 
														// ======== End: set fm ram write ========
													end
												end 
											end
										end
										else begin
											clk_count <= clk_count + 1;
										end
									end
								end

								if (go_to_next_layer == 1) begin
									pu_rst	<= 0;

									cur_fm_swap			<= ~cur_fm_swap;

									cur_x		<= 0;
									cur_y		<= 0;
									cur_slice	<= 0;
									cur_fm_ram	<= 0;

									// ======== Begin: disable fm ram write ========
									// PARA_X
									fmr_ena[0]	<= 0;
									fmr_wea[0]	<= 0;

									cur_out_index[0]	<= 0;

									fmr_ena[1]	<= 0;
									fmr_wea[1]	<= 0;

									cur_out_index[1]	<= 0;

									fmr_ena[2]	<= 0;
									fmr_wea[2]	<= 0;

									cur_out_index[2]	<= 0;

									fmr_ena[3]	<= 0;
									fmr_wea[3]	<= 0;

									cur_out_index[3]	<= 0;

									fmr_ena[4]	<= 0;
									fmr_wea[4]	<= 0;

									cur_out_index[4]	<= 0;

									fmr_ena[5]	<= 0;
									fmr_wea[5]	<= 0;

									cur_out_index[5]	<= 0;

									fmr_ena[6]	<= 0;
									fmr_wea[6]	<= 0;

									cur_out_index[6]	<= 0;

									fmr_ena[7]	<= 0;
									fmr_wea[7]	<= 0;

									cur_out_index[7]	<= 0;

									fmr_ena[8]	<= 0;
									fmr_wea[8]	<= 0;

									cur_out_index[8]	<= 0;

									fmr_ena[9]	<= 0;
									fmr_wea[9]	<= 0;

									cur_out_index[9]	<= 0;

									fmr_ena[10]	<= 0;
									fmr_wea[10]	<= 0;

									cur_out_index[10]	<= 0;

									fmr_ena[11]	<= 0;
									fmr_wea[11]	<= 0;

									cur_out_index[11]	<= 0;

									fmr_ena[12]	<= 0;
									fmr_wea[12]	<= 0;

									cur_out_index[12]	<= 0;

									fmr_ena[13]	<= 0;
									fmr_wea[13]	<= 0;

									cur_out_index[13]	<= 0;
									// ======== End: disable fm ram write ========

									cur_out_slice		<= 0;
									zero_write_count	<= 0;

									clk_count	<= 0;
									layer_ready	<= 1;
								end
							end
						3:// fc
							begin
								// todo:
								// 1、set read address and read data after 1 clk
								// 2、select PARA_Y data from dout to pool unit
								// 3、write result to fmr

								conv_op_type <= 1;

								fm_read_type		<= 2;
								// ======== Begin: set fm ram read ========
								// PARA_X
								fmr_enb[0]	<= 1; 
								fmr_enb[1]	<= 1; 
								fmr_enb[2]	<= 1; 
								fmr_enb[3]	<= 1; 
								fmr_enb[4]	<= 1; 
								fmr_enb[5]	<= 1; 
								fmr_enb[6]	<= 1; 
								fmr_enb[7]	<= 1; 
								fmr_enb[8]	<= 1; 
								fmr_enb[9]	<= 1; 
								fmr_enb[10]	<= 1; 
								fmr_enb[11]	<= 1; 
								fmr_enb[12]	<= 1; 
								fmr_enb[13]	<= 1; 
								// ======== End: set fm ram read ========

								// set weight ram read
								wr_ena	<= 1;

								// prepare output ram
								if (zero_write_count == 0) begin // prepare zero padding
									// just need the first fm ram
									// set conv buffer zero write
									// 
									// todo
									// buffer_0_0

									cur_out_index[0]	<= 0;

									zero_write_count	<= 1;
								end

								// fc operation
								if (clk_count == 0) begin
									if (go_to_next_layer == 0) begin
										conv_rst <= 0;
									end
								end
								else begin
									conv_rst <= 1;
								end

								// read weight data
								if (clk_count > 0 && clk_count <= fm_total_size) begin
									// ======== Begin: set conv input ========
									// PARA_KERNEL
									conv_input_data[0] <= {0, wr_doutb[0]}; 
									conv_input_data[1] <= {0, wr_doutb[1]}; 
									conv_input_data[2] <= {0, wr_doutb[2]}; 
									// ======== End: set conv input ========
								end

								// read fm data
								if (clk_count > 1 && clk_count <= (fm_total_size+1)) begin
									// ======== Begin: set conv input ========
									// PARA_KERNEL
									conv_weight[0] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH - 1:0]; 
									conv_weight[1] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH - 1:0]; 
									conv_weight[2] <= fmr_doutb[cur_fm_ram][`DATA_WIDTH - 1:0]; 
									// ======== End: set conv input ========
								end

								// set weight read address
								if (clk_count == 0) begin
									wr_addrb	<= cur_kernel_swap*`WEIGHT_RAM_HALF;
								end
								else if (clk_count > 0 && clk_count < (fm_total_size+1)) begin
									if ((clk_count - (clk_count/`PARA_Y)*`PARA_Y) == 1) begin
										wr_addrb <= wr_addrb + 1;
									end
								end

								// set fm read address
								if (clk_count == 1) begin // set init fc read address
									if (go_to_next_layer == 0) begin
										if (pre_layer_type == 2) begin // pre layer is conv/pool layer
											//fm_addr_read[cur_fm_ram]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
											fm_addr_read[cur_fm_ram]	<= cur_fm_swap*`FM_RAM_HALF; // test
										end
										else if(pre_layer_type == 3) begin // pre layer is fc layer
											fmr_addra[0]	<= cur_fm_swap*`FM_RAM_HALF;
										end
									end
								end
								else if (clk_count > 1 && clk_count < (fm_total_size+1)) begin
									if (pre_layer_type == 2) begin // pre layer is conv/pool layer
										if ((cur_y+1) < fm_size) begin
											cur_y <= cur_y + 1;

											fmr_addra[cur_fm_ram] <= fmr_addra[cur_fm_ram] + 1;
										end
										else begin // next line, next fm ram
											if ((cur_x+1) < fm_size) begin
												cur_y <= 0;
												cur_x <= cur_x + 1;

												cur_fm_ram	<= (cur_fm_ram+1) - ((cur_fm_ram+1)/`PARA_X)*`PARA_X;
												//fmr_addra[(cur_fm_ram+1) - ((cur_fm_ram+1)/`PARA_X)*`PARA_X] <= cur_fm_swap*`FM_RAM_HALF + (cur_x+1)/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
												fm_addr_read[cur_fm_ram]	<= cur_fm_swap*`FM_RAM_HALF; // test
											end
											else begin
												cur_x <= 0;
												cur_y <= 0;
												
												if ((cur_slice + 1) < fm_depth) begin // next slice
													cur_slice <= cur_slice + 1;

													cur_fm_ram	<= 0;
													fmr_addra[0] <= cur_fm_swap*`FM_RAM_HALF + cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
												end
											end
										end
									end
									else if (pre_layer_type == 3) begin // pre layer is fc layer
										fmr_addra[0]	<= fmr_addra[0] + 1;
									end
								end

								// fc ready, write result to fm ram
								if (clk_count <= (fm_total_size+1)) begin
									clk_count <= clk_count + 1;
								end
								if (clk_count > (fm_total_size+1)) begin
										// fc result ready
										if (&conv_out_ready == 1) begin
											clk_count <= 0;

											if (pre_layer_type == 2) begin // pre layer is conv/pool layer
												cur_x <= 0;
												cur_y <= 0;
												cur_slice <= 0;

												cur_fm_ram <= 0;
											end
											else if (pre_layer_type == 3) begin // pre layer is fc layer
												// nothing
											end

											if ((kernel_num_count + `PARA_Y*`PARA_KERNEL) < kernel_num) begin // next para weight
												kernel_num_count	<= kernel_num_count + `PARA_Y*`PARA_KERNEL;
												cur_kernel_swap		<= ~cur_kernel_swap;

												// update kernel
												update_weight_ram		<= 1;
												update_weight_ram_addr	<= cur_kernel_swap*`WEIGHT_RAM_HALF; 
												update_weight_wait_count<= 0;
											end
											else begin // next layer
												cur_kernel_swap <= ~cur_kernel_swap;

												// update kernel
												update_weight_ram		<= 1;
												update_weight_ram_addr	<= cur_kernel_swap*`WEIGHT_RAM_HALF; 
												update_weight_wait_count<= 0;

												go_to_next_layer <= 1;
											end

											// write result to fm ram
											if (zero_write_count == 1) begin
												if (write_ready_clk_count == 0) begin
													write_ready_clk_count <= 1;

													// just need the first fm ram
													fmr_ena[0]	<= 1;
													fmr_wea[0]	<= 1;

													// todo, write PARA_KERNEL times
													/*fmr_dina[0] <= {
																		conv_out_buffer[1][`PARA_Y*`DATA_WIDTH - 1:0],
																		conv_out_buffer[0][`PARA_Y*`DATA_WIDTH - 1:0]
																	};*/

													cur_out_index[0] <= cur_out_index[0] + `PARA_Y*`PARA_KERNEL;
												end
											end
										end
										else begin
											clk_count <= clk_count + 1;
										end
									end

								if (write_ready_clk_count == 1) begin
									write_ready_clk_count <= 2;
								end
								else if(write_ready_clk_count == 2) begin
									//if (fm_write_ready[0:0] == 1) begin
										// just need the first fm ram
										fmr_ena[0]	<= 0;
										fmr_wea[0]	<= 0;

										write_ready_clk_count <= 0;

										if (go_to_next_layer == 1) begin
											conv_rst <= 0;

											kernel_num_count	<= 0;
											cur_fm_swap 		<= ~cur_fm_swap;

											cur_x		<= 0;
											cur_y		<= 0;
											cur_slice	<= 0;
											cur_fm_ram	<= 0;

											fmr_ena[0]	<= 0;
											fmr_wea[0]	<= 0;
									
											cur_out_index[0]	<= 0;

											zero_write_count	<= 0;

											clk_count	<= 0;
											layer_ready	<= 1;
										end
									//end
								end
							end
						9: // finish, done
							begin
								// disable conv and pool modules
								conv_rst	<= 0;
								conv_op_type<= 0;
								pu_rst		<= 0;

								// ======== Begin: disable fm ram write ========
								// PARA_X
								fmr_ena[0]	<= 0;
								fmr_wea[0]	<= 0;
								fmr_enb[0]	<= 0;

								cur_out_index[0]		<= 0;

								fmr_ena[1]	<= 0;
								fmr_wea[1]	<= 0;
								fmr_enb[1]	<= 0;

								cur_out_index[1]		<= 0;

								fmr_ena[2]	<= 0;
								fmr_wea[2]	<= 0;
								fmr_enb[2]	<= 0;

								cur_out_index[2]		<= 0;

								fmr_ena[3]	<= 0;
								fmr_wea[3]	<= 0;
								fmr_enb[3]	<= 0;

								cur_out_index[3]		<= 0;

								fmr_ena[4]	<= 0;
								fmr_wea[4]	<= 0;
								fmr_enb[4]	<= 0;

								cur_out_index[4]		<= 0;

								fmr_ena[5]	<= 0;
								fmr_wea[5]	<= 0;
								fmr_enb[5]	<= 0;

								cur_out_index[5]		<= 0;

								fmr_ena[6]	<= 0;
								fmr_wea[6]	<= 0;
								fmr_enb[6]	<= 0;

								cur_out_index[6]		<= 0;

								fmr_ena[7]	<= 0;
								fmr_wea[7]	<= 0;
								fmr_enb[7]	<= 0;

								cur_out_index[7]		<= 0;

								fmr_ena[8]	<= 0;
								fmr_wea[8]	<= 0;
								fmr_enb[8]	<= 0;

								cur_out_index[8]		<= 0;

								fmr_ena[9]	<= 0;
								fmr_wea[9]	<= 0;
								fmr_enb[9]	<= 0;

								cur_out_index[9]		<= 0;

								fmr_ena[10]	<= 0;
								fmr_wea[10]	<= 0;
								fmr_enb[10]	<= 0;

								cur_out_index[10]		<= 0;

								fmr_ena[11]	<= 0;
								fmr_wea[11]	<= 0;
								fmr_enb[11]	<= 0;

								cur_out_index[11]		<= 0;

								fmr_ena[12]	<= 0;
								fmr_wea[12]	<= 0;
								fmr_enb[12]	<= 0;

								cur_out_index[12]		<= 0;

								fmr_ena[13]	<= 0;
								fmr_wea[13]	<= 0;
								fmr_enb[13]	<= 0;

								cur_out_index[13]		<= 0;
								// ======== End: reset fm ram ========

								// reset weight ram 
								wr_ena <= 0;
								wr_wea <= 0;
								wr_enb <= 0;

								// set layer status signal
								layer_ready			<= 0; 	

								// reset clock counter	
								clk_count	<= 0; 

								// reset current input fm ram and output fm ram
								cur_fm_ram			<= 0;
								cur_out_fm_ram		<= 0;

								// reset current read location of fm
								cur_x		<= 0;
								cur_y		<= 0;
								cur_slice	<= 0;

								// reset the output location of fm ram
								cur_out_slice		<= 0;
								cur_write_start_ram	<= 0;
								cur_write_end_ram	<= 0;
			
								// reset current read location of kernel/weight
								cur_kernel_slice	<= 0;

								// reset kernel counter
								kernel_num_count	<= 0;

								// reset update kernel/weight signal
								update_weight_ram		<= 0; 

								// reset the wait counter of update kernel/weight signal
								update_weight_wait_count <= 0;

								// reset the wait counter of write fm ram
								write_ready_clk_count	<= 0;

								// reset zero prepare status
								zero_write_count	<= 0;

								// for debug
								// read for debug
								// todo
							end
					endcase
				end
			end
		end
	end
endmodule