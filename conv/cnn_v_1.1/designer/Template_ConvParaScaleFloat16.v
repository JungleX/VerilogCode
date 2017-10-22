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
`define PARA_X			SET_PARA_X	// MAC group number
`define PARA_Y			SET_PARA_Y	// MAC number of each MAC group
`define KERNEL_SIZE_MAX	11
`define KERNEL_SIZE_WIDTH	6
`define CLK_NUM_WIDTH	8
 
module ConvParaScaleFloat16(
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

	reg [`DATA_WIDTH - 1:0] mult_a[`PARA_X*`PARA_Y - 1:0];

	generate
		genvar i;
		for (i = 0; i < (`PARA_X*`PARA_Y); i = i + 1)
		begin:identifier_mau
			MultAddUnitFloat16 mau(
				.clk(clk),
				.rst(mau_rst), // 0: reset; 1: none;
				//.rst(rst),

				.mult_a(mult_a[i]),
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
	
	// ======== Begin: register move wire ========
	// ======== End: register move wire ========

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

				// ======== Begin: register operation ========
				case(kernel_size)
                endcase
                
				// ======== End: register operation ========

				clk_count <= clk_count + 1;
			end
		
		end
	end

endmodule
