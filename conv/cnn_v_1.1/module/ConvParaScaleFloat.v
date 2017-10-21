`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/19 21:02:04
// Design Name: 
// Module Name: ConvParaScaleFloat
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define DATA_WIDTH		16  // 16 bits float
`define PARA_X			3	// MAC group number
`define PARA_Y			3	// MAC number of each MAC group
`define KERNEL_SIZE_MAX	11
`define KERNEL_SIZE_WIDTH	6
`define CLK_NUM_WIDTH	8
 
module ConvParaScaleFloat(
	input clk,
	input rst, // 0: reset; 1: none;

	input [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] input_data,

	input [`DATA_WIDTH - 1:0] weight,

	input [`KERNEL_SIZE_WIDTH - 1:0] kernel_size,

	output reg result_ready, // 1: ready; 0: not ready;
	output reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] result_buffer
    );

	reg [`CLK_NUM_WIDTH - 1:0] clk_num;
	reg [`CLK_NUM_WIDTH - 1:0] clk_count;

	reg mau_rst;

	wire [`PARA_X*`PARA_Y - 1:0] mau_out_ready;
	wire [`DATA_WIDTH - 1:0] ma_result[`PARA_X*`PARA_Y - 1:0];

	wire [`DATA_WIDTH - 1:0] mult_a_temp[`PARA_X*`PARA_Y - 1:0];

	generate
		genvar i;
		for (i = 0; i < (`PARA_X*`PARA_Y); i = i + 1)
		begin:identifier_mau
			MultAddUnitFloat16 mau(
				.clk(clk),
				.rst(mau_rst), // 0: reset; 1: none;
				//.rst(rst),

				.mult_a(mult_a_temp[i]),
				.mult_b(weight),

				.clk_num(clk_num), // set the clk number, after clk_count clks, the output is ready

				.result_ready(mau_out_ready[i:i]), // 1: ready; 0: not ready;
				.mult_add_result(ma_result[i])
		    );
		end 
	endgenerate

	// register group
	reg [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register[`PARA_X - 1:0];

    wire [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] result_temp;    

    generate
		genvar j;
		for (j = 0; j < (`PARA_X*`PARA_Y); j = j + 1)
		begin:identifier_result
		   assign result_temp[`DATA_WIDTH*(j+1) - 1:`DATA_WIDTH*j] = ma_result[j];	
		end
	endgenerate
	
	// kernel size: 3
	// clk 1-2
	// all register group, move and update
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_temp_0[`PARA_X - 1:0];
	generate
		genvar k01;
		genvar k02;
		for (k01 = 0; k01 < `PARA_X; k01 = k01 + 1)
		begin:identifier_301
			for (k02 = 0; k02 < (`PARA_Y + 1); k02 = k02 + 1)
			begin:identifier_302
				assign register_temp_0[k01][`DATA_WIDTH*(k02+1) - 1:`DATA_WIDTH*k02] = register[k01][`DATA_WIDTH*(k02+2) - 1:`DATA_WIDTH*(k02+1)];
			end

			assign register_temp_0[k01][`DATA_WIDTH*(`PARA_Y+2) - 1:`DATA_WIDTH*(`PARA_Y+1)] = input_data[`DATA_WIDTH*(k01+1) - 1:`DATA_WIDTH*k01];
		end
	endgenerate

	// kernel size: 3
	// clk 3,6
	// move between register group, update last register group
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_temp_1[`PARA_X - 1:0];
	generate
		genvar k11;
		genvar k12;
		for (k11 = 0; k11 < (`PARA_X - 1); k11 = k11 + 1)
		begin:identifier_31
			assign register_temp_1[k11][`DATA_WIDTH*(`PARA_Y+2) - 1:`DATA_WIDTH*2] = register[k11+1][`DATA_WIDTH*`PARA_Y - 1:0];
			assign register_temp_1[k11][`DATA_WIDTH*2 - 1:0] = register[k11+1][`DATA_WIDTH*(`PARA_Y+2) - 1:`DATA_WIDTH*`PARA_Y];
		end
		assign register_temp_1[`PARA_X - 1][`DATA_WIDTH*(`PARA_Y+2) - 1:`DATA_WIDTH*2] = input_data[`DATA_WIDTH*`PARA_Y - 1:0];
	endgenerate

	// kernel size: 3
	// clk 4-5, 7-8
	// all register group, move and update
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_temp_2[`PARA_X - 1:0];
	generate
		genvar k21;
		genvar k22;
		genvar k23;

		for (k21 = 0; k21 < (`PARA_X-1); k21 = k21 + 1)
		begin:identifier_321
			for (k22 = 0; k22 < (`PARA_Y + 1); k22 = k22 + 1)
			begin:identifier_3211
				assign register_temp_2[k21][`DATA_WIDTH*(k22+1) - 1:`DATA_WIDTH*k22] = register[k21][`DATA_WIDTH*(k22+2) - 1:`DATA_WIDTH*(k22+1)];
			end

			assign register_temp_2[k21][`DATA_WIDTH*(`PARA_Y+2) - 1:`DATA_WIDTH*(`PARA_Y+1)] = register[k21][`DATA_WIDTH - 1:0];
		end

		for (k23 = 0; k23 < (`PARA_Y + 1); k23 = k23 + 1)
		begin:identifier_322
			assign register_temp_2[`PARA_X - 1][`DATA_WIDTH*(k23+1) - 1:`DATA_WIDTH*k23] = register[`PARA_X - 1][`DATA_WIDTH*(k23+2) - 1:`DATA_WIDTH*(k23+1)];
		end

		assign register_temp_2[`PARA_X - 1][`DATA_WIDTH*(`PARA_Y+2) - 1:`DATA_WIDTH*(`PARA_Y+1)] = input_data[`DATA_WIDTH - 1:0];
	endgenerate

	// kernel size: 3
	// clk 0
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_temp_3[`PARA_X - 1:0];
	generate
		genvar k31;
		for (k31 = 0; k31 < `PARA_X; k31 = k31 + 1)
		begin:identifier_33
			assign register_temp_3[k31][`DATA_WIDTH*(`PARA_Y+2) - 1:`DATA_WIDTH*2] = input_data[`DATA_WIDTH*(k31+1)*(`PARA_Y) - 1:`DATA_WIDTH*k31*(`PARA_Y)];
		end
	endgenerate

	// kernel size: 3
	// input to MAC
	generate
		genvar ii1;
		genvar ii2;
		for (ii1 = 0; ii1 < `PARA_X; ii1 = ii1 + 1)
		begin:identifier_3i1
			for (ii2 = 0; ii2 < `PARA_Y; ii2 = ii2 + 1)
			begin:identifier_3i2
				assign mult_a_temp[(ii1*`PARA_Y)+ii2] = register[ii1][`DATA_WIDTH*(ii2+3) - 1:`DATA_WIDTH*(ii2+2)];
			end	
		end
	endgenerate

	integer l1;

	always @(posedge clk or negedge rst) begin
		if (!rst) begin
			// reset
			result_ready	<= 0;
			clk_num         <= 0;
			clk_count		<= 0;
			mau_rst         <= 0;
		end
		else begin
			if(clk_count == (clk_num + 1)) begin
				if (&mau_out_ready == 1) begin // MultAddUnits are ready
					clk_num = kernel_size * kernel_size - 1;

					clk_count		<= 0;
					result_ready	<= 1;

					result_buffer	<= result_temp;

					mau_rst			<= 0;
				end
			end
			else begin
				mau_rst				<= 1;

				clk_num = kernel_size * kernel_size - 1;

				if (clk_count == 0) begin
					for (l1=0; l1<`PARA_X; l1=l1+1)
					begin
                        register[l1] <= register_temp_3[l1];
					end
				end
				else if (clk_count%kernel_size == 0) begin // kernel size:3, clk: 3, 6
					for (l1=0; l1<`PARA_X; l1=l1+1)
					begin
                        register[l1] <= register_temp_1[l1];
					end
				end
				else if(clk_count > 0 && clk_count < kernel_size) begin
					for (l1=0; l1<`PARA_X; l1=l1+1)
					begin
                        register[l1] <= register_temp_0[l1];
					end
				end
				else begin
					for (l1=0; l1<`PARA_X; l1=l1+1)
					begin
                        register[l1] <= register_temp_2[l1];
					end
				end

				clk_count <= clk_count + 1;
			end
		
		end
	end

endmodule
