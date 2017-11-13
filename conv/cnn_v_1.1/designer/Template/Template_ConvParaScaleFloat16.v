`timescale 1ns / 1ps

`include "CNN_Parameter.vh"
 
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

	generate
		genvar i;
		for (i = 0; i < (`PARA_X*`PARA_Y); i = i + 1)
		begin:identifier_mau
			MultAddUnitFloat16 mau(
				.clk(clk),
				.rst(mau_rst), // 0: reset; 1: none;

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
		genvar j1;
		genvar j2;
		for (j1 = 0; j1 < `PARA_X; j1 = j1 + 1)
		begin:identifier_result_1
			for (j2 = 0; j2 < `PARA_Y; j2 = j2 + 1)
			begin:identifier_result_2
				assign result_temp[`DATA_WIDTH*(j1*`PARA_Y+j2+1) - 1:`DATA_WIDTH*(j1*`PARA_Y+j2)] = ma_result[(j1+1)*`PARA_Y-1-j2];
			end 
		end
	endgenerate
	
	// ======== Begin: register move wire ========
	// ======== End: register move wire ========

	// input to MAC
    wire [`DATA_WIDTH - 1:0] mult_a[`PARA_X*`PARA_Y - 1:0];
    generate
        genvar ii1;
        genvar ii2;
        for (ii1 = 0; ii1 < `PARA_X; ii1 = ii1 + 1)
        begin:identifier_ii1
            //for (ii2 = 0; ii2 < `PARA_Y; ii2 = ii2 + 1)
            for (ii2 = `PARA_Y; ii2 > 0 ; ii2 = ii2 - 1)
            begin:identifier_ii2
                assign mult_a[(ii1*`PARA_Y)+(`PARA_Y-ii2)] = register[ii1][`DATA_WIDTH*ii2 - 1:`DATA_WIDTH*(ii2-1)];
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

					// ======== Begin: result buffer ========
					result_buffer	<= {
									};
					// ======== End: result buffer ========

					mau_rst			<= 0;
				end
			end
			else begin
				result_ready		<= 0;
				
				mau_rst				<= 1;

				clk_num = kernel_size * kernel_size - 1;

				// ======== Begin: register operation ========
				// ======== End: register operation ========

				clk_count <= clk_count + 1;
			end
		
		end
	end

endmodule