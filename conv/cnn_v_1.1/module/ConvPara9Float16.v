`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/12 15:47:18
// Design Name: 
// Module Name: ConvPara9Float16
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
`define RET_SIZE		144 // 16*9 = 144
`define CLK_NUM_WIDTH	8
`define UNIT_NUM		9
`define REG_NUM			3

module ConvPara9Float16(
	input clk,
	input rst, // 0: reset; 1: none;

	input [`DATA_WIDTH*3 - 1:0] fm_1,
	input [`DATA_WIDTH*3 - 1:0] fm_2,
	input [`DATA_WIDTH*3 - 1:0] fm_3,

	input [`DATA_WIDTH - 1:0] weight,

	input [`CLK_NUM_WIDTH - 1:0] clk_num,

	output reg result_ready, // 1: ready; 0: not ready;
	output reg [`RET_SIZE - 1:0] result_buffer
    );

	reg [`CLK_NUM_WIDTH - 1:0] clk_count;
	reg [`CLK_NUM_WIDTH - 1:0] cur_clk_num;

	reg mau_rst;

	reg [`DATA_WIDTH - 1:0] mult_a[`UNIT_NUM - 1:0];

	wire [`UNIT_NUM - 1:0] mau_out_ready;
	wire [`DATA_WIDTH - 1:0] ma_result[`UNIT_NUM - 1:0];

	generate
		genvar i;
		for (i = 0; i < 9; i = i + 1)
		begin:identifier
			MultAddUnitFloat16 mau(
				.clk(clk),
				.rst(mau_rst), // 0: reset; 1: none;

				.mult_a(mult_a[i]),
				.mult_b(weight),

				.clk_num(cur_clk_num), // set the clk number, after clk_count clks, the output is ready

				.result_ready(mau_out_ready[i:i]), // 1: ready; 0: not ready;
				.mult_add_result(ma_result[i])
		    );
		end 
	endgenerate

	// register group
	reg [`DATA_WIDTH*5 - 1:0] register[`REG_NUM - 1:0];
	reg [`DATA_WIDTH - 1:0] reg_temp;

	always @(posedge clk or negedge rst) begin
		if (!rst) begin
			// reset
			result_ready	<= 0;
			clk_count		<= 0;
			cur_clk_num		<= 0;
			mau_rst         <= 0;
		end
		else begin
			if(clk_count == (cur_clk_num + 1)) begin
				if (mau_out_ready == `UNIT_NUM'b111111111) begin // 9 MultAddUnits are ready
					cur_clk_num		= clk_num;

					clk_count		= 0;
					result_ready	= 1;

					result_buffer   =  {ma_result[2], ma_result[1], ma_result[0], 
										ma_result[5], ma_result[4], ma_result[3], 
										ma_result[8], ma_result[7], ma_result[6]};
				
					mau_rst			= 0;
				end
			end
			else begin
				mau_rst				= 1;

				cur_clk_num		= clk_num;

				case (clk_count)
					0:
						begin
							register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*2] = fm_1;
							register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*2] = fm_2;
							register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*2] = fm_3;
						end
					1:
						begin
							register[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = fm_1[`DATA_WIDTH - 1:0];

							register[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = fm_2[`DATA_WIDTH - 1:0];

							register[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = fm_3[`DATA_WIDTH - 1:0];
						end
					2:
						begin
							register[0][`DATA_WIDTH - 1:0]               = register[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH];
							register[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = fm_1[`DATA_WIDTH - 1:0];

							register[1][`DATA_WIDTH - 1:0]               = register[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH];
							register[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = fm_2[`DATA_WIDTH - 1:0];

							register[2][`DATA_WIDTH - 1:0]               = register[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH];
							register[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = fm_3[`DATA_WIDTH - 1:0];
						end
					3:
						begin
							register[0][`DATA_WIDTH*2 - 1:0] = register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*3];
							register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*2] = register[1][`DATA_WIDTH*3 - 1:0];

							register[1][`DATA_WIDTH*2 - 1:0] = register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*3];
							register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*2] = register[2][`DATA_WIDTH*3 - 1:0];

							register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*2] = fm_3; 
						end
					4:
						begin
							reg_temp = register[0][`DATA_WIDTH - 1:0];
							register[0][`DATA_WIDTH - 1:0]               = register[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH];
							register[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = reg_temp;

							reg_temp = register[1][`DATA_WIDTH - 1:0];
							register[1][`DATA_WIDTH - 1:0]               = register[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH];
							register[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = reg_temp;

							register[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = fm_3[`DATA_WIDTH - 1:0];
						end
					5:
						begin
							reg_temp = register[0][`DATA_WIDTH - 1:0];
							register[0][`DATA_WIDTH - 1:0]               = register[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH];
							register[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = reg_temp;

							reg_temp = register[1][`DATA_WIDTH - 1:0];
							register[1][`DATA_WIDTH - 1:0]               = register[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH];
							register[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = reg_temp;

							register[2][`DATA_WIDTH - 1:0]               = register[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH];
							register[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = fm_3[`DATA_WIDTH - 1:0];
						end
					6:
						begin
							register[0][`DATA_WIDTH*2 - 1:0] = register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*3];
							register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*2] = register[1][`DATA_WIDTH*3 - 1:0];

							register[1][`DATA_WIDTH*2 - 1:0] = register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*3];
							register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*2] = register[2][`DATA_WIDTH*3 - 1:0];

							register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*2] = fm_3; 
						end
					7:
						begin
							reg_temp = register[0][`DATA_WIDTH - 1:0];
							register[0][`DATA_WIDTH - 1:0]               = register[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH];
							register[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = reg_temp;

							reg_temp = register[1][`DATA_WIDTH - 1:0];
							register[1][`DATA_WIDTH - 1:0]               = register[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH];
							register[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = reg_temp;

							register[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = fm_3[`DATA_WIDTH - 1:0];
						end
					8:
						begin
							reg_temp = register[0][`DATA_WIDTH - 1:0];
							register[0][`DATA_WIDTH - 1:0]               = register[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH];
							register[0][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = reg_temp;

							reg_temp = register[1][`DATA_WIDTH - 1:0];
							register[1][`DATA_WIDTH - 1:0]               = register[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH];
							register[1][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = reg_temp;

							register[2][`DATA_WIDTH - 1:0]               = register[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH];
							register[2][`DATA_WIDTH*2 - 1:`DATA_WIDTH]   = register[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
							register[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] = register[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
							register[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] = register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
							register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] = fm_3[`DATA_WIDTH - 1:0];
						end
				endcase

				// M11 M12 M13
				mult_a[0] = register[0][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
				//mult_b[0] = weight;

				mult_a[1] = register[0][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
				//mult_b[1] = weight;

				mult_a[2] = register[0][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
				//mult_b[2] = weight;

				// M21 M22 M23
				mult_a[3] = register[1][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
				//mult_b[3] = weight;

				mult_a[4] = register[1][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
				//mult_b[4] = weight;

				mult_a[5] = register[1][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
				//mult_b[5] = weight;

				// M31 M32 M33
				mult_a[6] = register[2][`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
				//mult_b[6] = weight;

				mult_a[7] = register[2][`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
				//mult_b[7] = weight;
 
				mult_a[8] = register[2][`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
				//mult_b[8] = weight;

				clk_count = clk_count + 1;

			end
		end
	end
endmodule
