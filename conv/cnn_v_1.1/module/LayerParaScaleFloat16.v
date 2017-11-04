`timescale 1ns / 1ps

`include "CNN_Parameter.vh"

module LayerParaScaleFloat16(
	input clk,
	input rst,

	input [1:0] layer_type, // 0: prepare init feature map and weight data; 1:conv; 2:pool; 3:fc;
	input [`FM_SIZE_WIDTH - 1:0] fm_size,
	input [`KERNEL_SIZE_WIDTH - 1:0] kernel_size,
	input [`KERNEL_SIZE_WIDTH - 1:0] fm_depth,

	input [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] init_fm_data,
	input [`WRITE_ADDR_WIDTH - 1:0] write_fm_data_addr,
	input init_fm_data_done, // feature map data transmission, 0: not ready; 1: ready

	input [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_data,
	input [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] write_weight_data_addr,
	input weight_data_done, // weight data transmission, 0: not ready; 1: ready

	input [`KERNEL_NUM_WIDTH - 1:0] kernel_num,

	output reg update_weight_ram, // 0: not update; 1: update
	output reg update_weight_ram_addr,

	output reg init_fm_ram_ready, // 0: not ready; 1: ready
	output reg init_weight_ram_ready, // 0: not ready; 1: ready
	output reg layer_ready
    );

	// ======== Begin: pool unit ========
	reg mpu_rst;

	reg [`PARA_POOL_Y*`DATA_WIDTH - 1:0] pool_input_data;
	reg [`POOL_SIZE_WIDTH - 1:0] pool_size;

	wire [`PARA_POOL_Y - 1:0] mpu_out_ready;
	wire [`PARA_POOL_Y*`DATA_WIDTH - 1:0] mpu_result;

	// === Begin: max pool ===
	generate
		genvar pool_i;
		for (pool_i = 0; pool_i < `PARA_POOL_Y; pool_i = pool_i + 1)
		begin:identifier_mpu
			MaxPoolUnitFloat16 mpu(
				.clk(clk),
				.rst(mpu_rst), // 0: reset; 1: none;

				.cmp_data(pool_input_data[`DATA_WIDTH*(pool_i+1):`DATA_WIDTH*pool_i]),

				.data_num(pool_size*pool_size), // set the clk number, after clk_count clks, the output is ready

				.result_ready(mpu_out_ready[pool_i:pool_i]), // 1: rady; 0: not ready;
				.max_pool_result(mpu_result[`DATA_WIDTH*(pool_i+1):`DATA_WIDTH*pool_i])
			);
		end
	endgenerate
	// === End: max pool ===

	// === Begin: avg pool ===
	/*generate
		genvar pool_i;
		for (pool_i = 0; pool_i < `PARA_POOL_Y; pool_i = pool_i + 1)
		begin:identifier_mpu
			AvgPoolUnitFloat16 mpu(
				.clk(clk),
				.rst(mpu_rst), // 0: reset; 1: none;
				.avg_input_data(pool_input_data[`DATA_WIDTH*(pool_i+1):`DATA_WIDTH*pool_i]),

				.data_num(pool_size*pool_size),

				.result_ready(mpu_out_ready[pool_i:pool_i]), // 1: ready; 0: not ready;
				.avg_pool_result(mpu_result[`DATA_WIDTH*(pool_i+1):`DATA_WIDTH*pool_i])
		    );
		end
	endgenerate*/
	// === End: avg pool ===

	// ======== End: pool unit ========

	// ======== Begin: conv unit ========
	reg conv_rst;

	reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] conv_input_data;
	reg [`DATA_WIDTH - 1:0] conv_weight[`PARA_KERNEL - 1:0];

	wire [`PARA_KERNEL - 1:0] conv_out_ready;
	wire [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] conv_out_buffer[`PARA_KERNEL - 1:0];

	generate
		genvar conv_i;
		for (conv_i = 0; conv_i < `PARA_KERNEL; conv_i = conv_i + 1)
		begin:identifier_conv
			ConvParaScaleFloat16 conv(
				.clk(clk),
				.rst(conv_rst), // 0: reset; 1: none;

				.input_data(conv_input_data),

				.weight(conv_weight[conv_i]),

				.kernel_size(kernel_size),

				.result_ready(conv_out_ready[conv_i:conv_i]), // 1: ready; 0: not ready;
				.result_buffer(conv_out_buffer[conv_i])
		    );
		end
	endgenerate
    // ======== End: conv unit ========

    // ======== Begin: feature map ram ========
    reg fm_ena_w[`PARA_X - 1:0];
    reg fm_ena_r[`PARA_X - 1:0];
    reg fm_ena_add_write[`PARA_X - 1:0]; // 0: not add; 1: add
	reg [`WRITE_ADDR_WIDTH - 1:0] fm_addr_write[`PARA_X - 1:0];
	reg [`PARA_Y*`DATA_WIDTH - 1:0] fm_din[`PARA_X - 1:0];

	reg [`READ_ADDR_WIDTH - 1:0] fm_addr_read[`PARA_X - 1:0];
	reg [`READ_ADDR_WIDTH - 1:0] fm_sub_addr_read[`PARA_X - 1:0];
	wire [`PARA_X - 1:0] fm_write_ready;
	wire [`PARA_Y*`DATA_WIDTH - 1:0] fm_dout[`PARA_X - 1:0];

    generate
    	genvar fm_ram_i;
    	for (fm_ram_i = 0; fm_ram_i < `PARA_X; fm_ram_i = fm_ram_i + 1)
    	begin
			FeatureMapRamFloat16 ram_fm(
				.clk(clk),

				.ena_w(fm_ena_w[fm_ram_i]), 
				.ena_add_write(fm_ena_add_write[fm_ram_i]), // 0: not add; 1: add
				.addr_write(fm_addr_write[fm_ram_i]),
				.din(fm_din[fm_ram_i]),

				.ena_r(fm_ena_r[fm_ram_i]),
				.addr_read(fm_addr_read[fm_ram_i]),
				.sub_addr_read(fm_sub_addr_read[fm_ram_i]),
				.write_ready(fm_write_ready[fm_ram_i:fm_ram_i]),
				.dout(fm_dout[fm_ram_i])
		    );
    	end
    endgenerate
    // ======== End: feature map ram ========

    // ======== Begin: weight ram ========
    reg weight_ena_w;
    reg weight_ena_r;

    reg [`WEIGHT_WRITE_ADDR_WIDTH - 1:0] weight_addr_write[`PARA_KERNEL - 1:0];
	reg [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH - 1:0] weight_din[`PARA_KERNEL - 1:0]; // write a slice weight(ks*ks, eg:3*3=9) each time

	reg [`WEIGHT_READ_ADDR_WIDTH - 1:0] weight_addr_read[`PARA_KERNEL - 1:0];

	wire [`DATA_WIDTH - 1:0] weight_dout[`PARA_KERNEL - 1:0]; // read a value each time

    generate
    	genvar weight_ram_i;
    	for (weight_ram_i = 0; weight_ram_i < `PARA_KERNEL; weight_ram_i = weight_ram_i + 1)
		begin:identifier_weight_ram
			WeightRamFloat16 weight_ram(
				.clk(clk),

				.ena_w(weight_ena_w),
				.addr_write(weight_addr_write[weight_ram_i]),
				.din(weight_din[weight_ram_i]), // write a slice weight(ks*ks, eg:3*3=9) each time

				.ena_r(weight_ena_r),
				.addr_read(weight_addr_read[weight_ram_i]),

				.dout(weight_dout[weight_ram_i]) // read a value each time
			);
		end
    endgenerate
    // ======== End: weight ram ========

    reg [`CLK_NUM_WIDTH - 1:0] clk_count;

    reg [`RAM_NUM_WIDTH - 1:0] cur_fm_ram;

    reg [`FM_SIZE_WIDTH - 1:0] cur_x;
    reg [`FM_SIZE_WIDTH - 1:0] cur_y;
    reg [`KERNEL_NUM_WIDTH - 1:0] cur_slice;

    reg cur_kernel_swap; // 0 or 1; one is using, the other is updating
    reg [`KERNEL_NUM_WIDTH - 1:0] cur_kernel_slice;
    reg [`KERNEL_NUM_WIDTH - 1:0] kernel_num_count;

	always @(posedge clk or negedge rst) begin
		if (!rst) begin
			// reset
			conv_rst	<= 0;
			mpu_rst		<= 0;
			layer_ready	<= 0;
			clk_count	<= 0;

			cur_fm_ram			<= 0;
			fm_addr_read[0]		<= 0;
			fm_sub_addr_read[0]	<= 0;
			fm_addr_read[1]		<= 0;
			fm_sub_addr_read[1]	<= 0;
			fm_addr_read[2]		<= 0;
			fm_sub_addr_read[2]	<= 0;

			weight_addr_read[0]	<= 0;
			weight_addr_read[1]	<= 0;

			cur_x		<= 0;
			cur_y		<= 0;
			cur_slice	<= 0;

			cur_kernel_swap		<= 0;
			cur_kernel_slice	<= 0;
			kernel_num_count	<= 0;

			update_weight_ram		<= 0;
			update_weight_ram_addr	<= 0; 
		end
		else begin
			if (layer_type == 0) begin 

				// init feature map ram time >> init weight ram time

				// init feature map ram
				if (init_fm_data_done == 1) begin
					clk_count <= 0;

					init_fm_ram_ready <= 1;
				end
				else begin
					fm_ena_w[0]			<= 1; // write
					fm_ena_add_write[0]	<= 0; // not add
					fm_ena_w[1]			<= 1; // write
					fm_ena_add_write[1]	<= 0; // not add
					fm_ena_w[2]			<= 1; // write
					fm_ena_add_write[2]	<= 0; // not add

					// `PARA_X = 3
					fm_addr_write[0]	<= write_fm_data_addr;
					fm_din[0]			<= init_fm_data[`PARA_Y*`DATA_WIDTH*1 - 1:`PARA_Y*`DATA_WIDTH*0];
					fm_addr_write[1]	<= write_fm_data_addr;
					fm_din[1]			<= init_fm_data[`PARA_Y*`DATA_WIDTH*2 - 1:`PARA_Y*`DATA_WIDTH*1];
					fm_addr_write[2]	<= write_fm_data_addr;
					fm_din[2]			<= init_fm_data[`PARA_Y*`DATA_WIDTH*3 - 1:`PARA_Y*`DATA_WIDTH*2];

					init_fm_ram_ready	<= 0;
				end

				// init weight ram
				if (weight_data_done == 1) begin
					init_weight_ram_ready <= 1;
				end
				else begin
					weight_ena_w <= 1; // write

					// `PARA_KERNEL = 2
					weight_addr_write[0]	<= write_weight_data_addr;
					weight_din[0]			<= weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*0]; 
					weight_addr_write[1]	<= write_weight_data_addr;
					weight_din[1]			<= weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*2 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1];

					init_weight_ram_ready <= 0;
				end
				
			end
			else if (init_fm_ram_ready == 1 && init_weight_ram_ready == 1) begin
				case(layer_type)
					1:// conv
						begin
							// update kernel
							if (update_weight_ram == 1) begin
								if (weight_data_done == 0) begin
									weight_ena_w <= 1; // write

									// `PARA_KERNEL = 2
									weight_addr_write[0]	<= write_weight_data_addr;
									weight_din[0]			<= weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*0]; 
									weight_addr_write[1]	<= write_weight_data_addr;
									weight_din[1]			<= weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*2 - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*1];
								end
							end
							else begin
								weight_ena_w <= 0;
							end

							// conv operation
							if (clk_count == 0) begin
								conv_rst	<= 0;

								// start to read, next clk get read data
								fm_ena_w[0]		<= 0; 
								fm_ena_r[0]		<= 1;
								fm_ena_w[1]		<= 0;  
								fm_ena_r[1]		<= 1; 
								fm_ena_w[2]		<= 0; 
								fm_ena_r[2]		<= 1;

								fm_addr_read[0]		<= cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X); // [fm_size/`PARA_Y]=(fm_size+`PARA_Y-1)/`PARA_Y [8/3] = 3
								fm_sub_addr_read[0]	<= 0;
								fm_addr_read[1]		<= cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
								fm_sub_addr_read[1]	<= 0;
								fm_addr_read[2]		<= cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
								fm_sub_addr_read[2]	<= 0;

								weight_ena_r	<= 1;

								weight_addr_read[0]	<= (cur_kernel_swap*fm_depth+cur_kernel_slice)*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX;
								weight_addr_read[1]	<= (cur_kernel_swap*fm_depth+cur_kernel_slice)*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX;

								cur_fm_ram	<= 0;

								clk_count	<= clk_count + 1;
							end
							else begin
								conv_rst	<= 1;

								// weight data
								if (clk_count == 1) begin
								end
								else if (clk_count <= (kernel_size*kernel_size + 1)) begin
									//`PARA_KERNEL = 2
									weight_addr_read[0]	<= weight_addr_read[0] + 1;
									conv_weight[0]	<= weight_dout[0];
									weight_addr_read[1]	<= weight_addr_read[1] + 1;
									conv_weight[1]	<= weight_dout[1]; 
								end

								// feature map data
								if (clk_count == 1) begin
									conv_input_data[`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fm_dout[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
									conv_input_data[`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= fm_dout[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1];
									conv_input_data[`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= fm_dout[0][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0];

									conv_input_data[`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] <= fm_dout[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
									conv_input_data[`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] <= fm_dout[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1];
									conv_input_data[`DATA_WIDTH*6 - 1:`DATA_WIDTH*5] <= fm_dout[1][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0];

									conv_input_data[`DATA_WIDTH*7 - 1:`DATA_WIDTH*6] <= fm_dout[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
									conv_input_data[`DATA_WIDTH*8 - 1:`DATA_WIDTH*7] <= fm_dout[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1];
									conv_input_data[`DATA_WIDTH*9 - 1:`DATA_WIDTH*8] <= fm_dout[2][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0];

									fm_addr_read[0]		<= fm_addr_read[0] + 1;
									fm_sub_addr_read[0]	<= 0;
									fm_addr_read[1]		<= fm_addr_read[1] + 1;
									fm_sub_addr_read[1]	<= 0;
									fm_addr_read[2]		<= fm_addr_read[2] + 1;
									fm_sub_addr_read[2]	<= 0;

									clk_count <= clk_count + 1;
								end
								else if (clk_count > 1 && clk_count <= kernel_size) begin
									
									conv_input_data[`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fm_dout[0][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0];
									conv_input_data[`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= fm_dout[1][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0];
									conv_input_data[`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= fm_dout[2][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0];

									fm_sub_addr_read[0]	<= fm_sub_addr_read[0] + 1;
									fm_sub_addr_read[1]	<= fm_sub_addr_read[1] + 1;
									fm_sub_addr_read[2]	<= fm_sub_addr_read[2] + 1;

									if (clk_count == kernel_size) begin
										case(fm_size)
											6:
												begin
													fm_addr_read[0]		<= fm_addr_read[0] + 1;// [FS/Y]-[(KS-1)/Y] eg: [6/3]-[(3-1)/3]=2-1=1 
												end
											8:
												begin
													fm_addr_read[0]		<= fm_addr_read[0] + 2;// [FS/Y]-[(KS-1)/Y] eg: [8/3]-[(3-1)/3]=3-1=2
												end
										endcase
										
										fm_sub_addr_read[0]	<= 0;
										cur_fm_ram			<= 0;
									end

									clk_count	<= clk_count + 1;
								end
								else if (clk_count%kernel_size == 1) begin
									// `PARA_X = 3  3 - 1 = 2
									case(cur_fm_ram)
										0:
											begin
												conv_input_data[`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fm_dout[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
												conv_input_data[`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= fm_dout[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1];
												conv_input_data[`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= fm_dout[0][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0];

												fm_addr_read[0]		<= fm_addr_read[0] + 1;
												fm_sub_addr_read[0]	<= 0;
											end
										1:
											begin
												conv_input_data[`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= fm_dout[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
												conv_input_data[`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= fm_dout[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH*1];
												conv_input_data[`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= fm_dout[1][`DATA_WIDTH*1 - 1:`DATA_WIDTH*0];

												fm_addr_read[1]		<= fm_addr_read[1] + 1;
												fm_sub_addr_read[1]	<= 0;
											end
									endcase

									clk_count	<= clk_count + 1;
								end
								else if (clk_count <= (kernel_size*kernel_size)) begin
									if (clk_count%kernel_size == 0) begin
										cur_fm_ram	<= cur_fm_ram + 1;

										fm_sub_addr_read[0]	<= 0;
										fm_sub_addr_read[1]	<= 0;
										fm_sub_addr_read[2]	<= 0;

										case(cur_fm_ram + 1)
											0:
												begin
													case(fm_size)
														6:
															begin
																fm_addr_read[0] <= fm_addr_read[0] + 1;// [FS/Y]-[(KS-1)/Y] eg: [6/3]-[(3-1)/3]=2-1=1 
															end
														8:
															begin
																fm_addr_read[0] <= fm_addr_read[0] + 2;// [FS/Y]-[(KS-1)/Y] eg: [8/3]-[(3-1)/3]=3-1=2
															end
													endcase
												end
											1:
												begin
													case(fm_size)
														6:
															begin
																fm_addr_read[1] <= fm_addr_read[1] + 1;// [FS/Y]-[(KS-1)/Y] eg: [6/3]-[(3-1)/3]=2-1=1 
															end
														8:
															begin
																fm_addr_read[1] <= fm_addr_read[1] + 2;// [FS/Y]-[(KS-1)/Y] eg: [8/3]-[(3-1)/3]=3-1=2
															end
													endcase
												end
											2:
												begin
													case(fm_size)
														6:
															begin
																fm_addr_read[2] <= fm_addr_read[2] + 1;// [FS/Y]-[(KS-1)/Y] eg: [6/3]-[(3-1)/3]=2-1=1 
															end
														8:
															begin
																fm_addr_read[2] <= fm_addr_read[2] + 2;// [FS/Y]-[(KS-1)/Y] eg: [8/3]-[(3-1)/3]=3-1=2
															end
													endcase
												end
										endcase
									end
									else begin
										fm_sub_addr_read[0]	<= fm_sub_addr_read[0] + 1;
										fm_sub_addr_read[1]	<= fm_sub_addr_read[1] + 1;
									end

									case(cur_fm_ram)
										0:
											begin
												conv_input_data[`DATA_WIDTH - 1:0] <= fm_dout[0][`DATA_WIDTH - 1:0];
											end
										1:
											begin
												conv_input_data[`DATA_WIDTH - 1:0] <= fm_dout[1][`DATA_WIDTH - 1:0];
											end
									endcase

									clk_count	<= clk_count + 1;
								end
								else begin
									if (&conv_out_ready == 1) begin
										clk_count <= 0;

										// write result to feature map ram
										// todo

										
										if ((cur_y + kernel_size + `PARA_Y - 1) < fm_size) begin
											cur_y <= cur_y + `PARA_Y; // next para window y
										end
										else begin
											cur_y <= 0;

											if ((cur_x + kernel_size + `PARA_X - 1) <fm_size ) begin
												cur_x <= cur_x + `PARA_X; // next para window x
											end
											else begin 
												if (cur_slice == (fm_depth - 1)) begin // conv end, next para kernel
													cur_slice	<= 0; 
													cur_x		<= 0;
													cur_y		<= 0;

													if (kernel_num_count == (kernel_num - 1)) begin // conv layer end, next layer
														kernel_num_count	<= 0;
													end
													else begin
														kernel_num_count	<= kernel_num_count + 1; // next para kernel
														cur_kernel_swap		<= ~cur_kernel_swap; 
														cur_kernel_slice	<= 0;

														// update kernel
														update_weight_ram		<= 1;
														update_weight_ram_addr	<= cur_kernel_swap*fm_depth;
													end
													
												end
												else begin
													cur_slice	<= cur_slice + 1; // next feature map slice
													cur_x		<= 0;
													cur_y		<= 0;

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
						end
					2:// pool
						begin
							
						end
					3:// fc
						begin
							
						end
				endcase
			end
		end
	end
endmodule