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
	// === Begin: kernel size = 3 ===
	// clk type 0
	// clk 0
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_ks3_0[`PARA_X - 1:0];
	generate
		genvar k_ks3_0;
		for (k_ks3_0 = 0; k_ks3_0 < `PARA_X; k_ks3_0 = k_ks3_0 + 1)
		begin:identifier_ks3_0
			assign register_ks3_0[k_ks3_0][`DATA_WIDTH*`PARA_Y - 1:0] = input_data[`DATA_WIDTH*(k_ks3_0+1)*(`PARA_Y) - 1:`DATA_WIDTH*k_ks3_0*(`PARA_Y)];
		end
	endgenerate

	// clk type 1
	// all register group, move and update
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_ks3_1[`PARA_X - 1:0];
	generate
		genvar k_ks3_1_1;
		genvar k_ks3_1_2;
		for (k_ks3_1_1 = 0; k_ks3_1_1 < `PARA_X; k_ks3_1_1 = k_ks3_1_1 + 1)
		begin:identifier_ks3_1_0
			for (k_ks3_1_2 = `PARA_Y+(3-1); k_ks3_1_2 > 1; k_ks3_1_2 = k_ks3_1_2 - 1)
			begin:identifier_ks3_1_1
				assign register_ks3_1[k_ks3_1_1][`DATA_WIDTH*k_ks3_1_2 - 1:`DATA_WIDTH*(k_ks3_1_2-1)] = register[k_ks3_1_1][`DATA_WIDTH*(k_ks3_1_2-1) - 1:`DATA_WIDTH*(k_ks3_1_2-2)];
			end

			assign register_ks3_1[k_ks3_1_1][`DATA_WIDTH - 1:0] = input_data[`DATA_WIDTH*(k_ks3_1_1+1) - 1:`DATA_WIDTH*k_ks3_1_1];
		end
	endgenerate

	// clk type 2
	// move between register group, update PARA_Y register in last register group
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_ks3_2[`PARA_X - 1:0];
	generate
		genvar k_ks3_2;
		for (k_ks3_2 = 0; k_ks3_2 < (`PARA_X - 1); k_ks3_2 = k_ks3_2 + 1)
		begin:identifier_ks3_2
			assign register_ks3_2[k_ks3_2][`DATA_WIDTH*`PARA_Y - 1:0] = register[k_ks3_2+1][`DATA_WIDTH*(`PARA_Y + (3-1)) - 1:`DATA_WIDTH*(3-1)];
			assign register_ks3_2[k_ks3_2][`DATA_WIDTH*(`PARA_Y + (3-1)) - 1:`DATA_WIDTH*`PARA_Y] = register[k_ks3_2+1][`DATA_WIDTH*(3-1) - 1:0];
		end
		assign register_ks3_2[`PARA_X - 1][`DATA_WIDTH*`PARA_Y - 1:0] = input_data[`DATA_WIDTH*`PARA_Y - 1:0];
	endgenerate

	// clk tpye 3
	// move between register group, update one register in last register group
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_ks3_3[`PARA_X - 1:0];
	generate
		genvar k_ks3_3_1;
		genvar k_ks3_3_2;
		genvar k_ks3_3_3;

		for (k_ks3_3_1 = 0; k_ks3_3_1 < (`PARA_X-1); k_ks3_3_1 = k_ks3_3_1 + 1)
		begin:identifier_ks3_3_1
			for (k_ks3_3_2 = `PARA_Y+(3-1); k_ks3_3_2 > 1; k_ks3_3_2 = k_ks3_3_2 - 1)
			begin:identifier_ks3_3_2
				assign register_ks3_3[k_ks3_3_1][`DATA_WIDTH*k_ks3_3_2 - 1:`DATA_WIDTH*(k_ks3_3_2-1)] = register[k_ks3_3_1][`DATA_WIDTH*(k_ks3_3_2-1) - 1:`DATA_WIDTH*(k_ks3_3_2-2)];
			end

			assign register_ks3_3[k_ks3_3_1][`DATA_WIDTH - 1:0] = register[k_ks3_3_1][`DATA_WIDTH*(`PARA_Y+(3-1)) - 1:`DATA_WIDTH*(`PARA_Y+(3-2))];
		end

		for (k_ks3_3_3 = `PARA_Y+(3-1); k_ks3_3_3 > 1; k_ks3_3_3 = k_ks3_3_3 - 1)
		begin:identifier_ks3_3_3
			assign register_ks3_3[`PARA_X - 1][`DATA_WIDTH*k_ks3_3_3 - 1:`DATA_WIDTH*(k_ks3_3_3-1)] = register[`PARA_X - 1][`DATA_WIDTH*(k_ks3_3_3-1) - 1:`DATA_WIDTH*(k_ks3_3_3-2)];
		end

		assign register_ks3_3[`PARA_X - 1][`DATA_WIDTH - 1:0] = input_data[`DATA_WIDTH - 1:0];
	endgenerate

	// === End: kernel size = 3 ===
	// === Begin: kernel size = 5 ===
	// clk type 0
	// clk 0
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_ks5_0[`PARA_X - 1:0];
	generate
		genvar k_ks5_0;
		for (k_ks5_0 = 0; k_ks5_0 < `PARA_X; k_ks5_0 = k_ks5_0 + 1)
		begin:identifier_ks5_0
			assign register_ks5_0[k_ks5_0][`DATA_WIDTH*`PARA_Y - 1:0] = input_data[`DATA_WIDTH*(k_ks5_0+1)*(`PARA_Y) - 1:`DATA_WIDTH*k_ks5_0*(`PARA_Y)];
		end
	endgenerate

	// clk type 1
	// all register group, move and update
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_ks5_1[`PARA_X - 1:0];
	generate
		genvar k_ks5_1_1;
		genvar k_ks5_1_2;
		for (k_ks5_1_1 = 0; k_ks5_1_1 < `PARA_X; k_ks5_1_1 = k_ks5_1_1 + 1)
		begin:identifier_ks5_1_0
			for (k_ks5_1_2 = `PARA_Y+(5-1); k_ks5_1_2 > 1; k_ks5_1_2 = k_ks5_1_2 - 1)
			begin:identifier_ks5_1_1
				assign register_ks5_1[k_ks5_1_1][`DATA_WIDTH*k_ks5_1_2 - 1:`DATA_WIDTH*(k_ks5_1_2-1)] = register[k_ks5_1_1][`DATA_WIDTH*(k_ks5_1_2-1) - 1:`DATA_WIDTH*(k_ks5_1_2-2)];
			end

			assign register_ks5_1[k_ks5_1_1][`DATA_WIDTH - 1:0] = input_data[`DATA_WIDTH*(k_ks5_1_1+1) - 1:`DATA_WIDTH*k_ks5_1_1];
		end
	endgenerate

	// clk type 2
	// move between register group, update PARA_Y register in last register group
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_ks5_2[`PARA_X - 1:0];
	generate
		genvar k_ks5_2;
		for (k_ks5_2 = 0; k_ks5_2 < (`PARA_X - 1); k_ks5_2 = k_ks5_2 + 1)
		begin:identifier_ks5_2
			assign register_ks5_2[k_ks5_2][`DATA_WIDTH*`PARA_Y - 1:0] = register[k_ks5_2+1][`DATA_WIDTH*(`PARA_Y + (5-1)) - 1:`DATA_WIDTH*(5-1)];
			assign register_ks5_2[k_ks5_2][`DATA_WIDTH*(`PARA_Y + (5-1)) - 1:`DATA_WIDTH*`PARA_Y] = register[k_ks5_2+1][`DATA_WIDTH*(5-1) - 1:0];
		end
		assign register_ks5_2[`PARA_X - 1][`DATA_WIDTH*`PARA_Y - 1:0] = input_data[`DATA_WIDTH*`PARA_Y - 1:0];
	endgenerate

	// clk tpye 3
	// move between register group, update one register in last register group
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_ks5_3[`PARA_X - 1:0];
	generate
		genvar k_ks5_3_1;
		genvar k_ks5_3_2;
		genvar k_ks5_3_3;

		for (k_ks5_3_1 = 0; k_ks5_3_1 < (`PARA_X-1); k_ks5_3_1 = k_ks5_3_1 + 1)
		begin:identifier_ks5_3_1
			for (k_ks5_3_2 = `PARA_Y+(5-1); k_ks5_3_2 > 1; k_ks5_3_2 = k_ks5_3_2 - 1)
			begin:identifier_ks5_3_2
				assign register_ks5_3[k_ks5_3_1][`DATA_WIDTH*k_ks5_3_2 - 1:`DATA_WIDTH*(k_ks5_3_2-1)] = register[k_ks5_3_1][`DATA_WIDTH*(k_ks5_3_2-1) - 1:`DATA_WIDTH*(k_ks5_3_2-2)];
			end

			assign register_ks5_3[k_ks5_3_1][`DATA_WIDTH - 1:0] = register[k_ks5_3_1][`DATA_WIDTH*(`PARA_Y+(5-1)) - 1:`DATA_WIDTH*(`PARA_Y+(5-2))];
		end

		for (k_ks5_3_3 = `PARA_Y+(5-1); k_ks5_3_3 > 1; k_ks5_3_3 = k_ks5_3_3 - 1)
		begin:identifier_ks5_3_3
			assign register_ks5_3[`PARA_X - 1][`DATA_WIDTH*k_ks5_3_3 - 1:`DATA_WIDTH*(k_ks5_3_3-1)] = register[`PARA_X - 1][`DATA_WIDTH*(k_ks5_3_3-1) - 1:`DATA_WIDTH*(k_ks5_3_3-2)];
		end

		assign register_ks5_3[`PARA_X - 1][`DATA_WIDTH - 1:0] = input_data[`DATA_WIDTH - 1:0];
	endgenerate

	// === End: kernel size = 5 ===
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

					result_buffer	<= result_temp;

					mau_rst			<= 0;
				end
			end
			else begin
				result_ready		<= 0;
				
				mau_rst				<= 1;

				clk_num = kernel_size * kernel_size - 1;

				// ======== Begin: register operation ========
				if (clk_count == 0) begin // clk type 0
					for (l1=0; l1<`PARA_X; l1=l1+1)
					begin
						case(kernel_size)
							// ======== Begin: kernel size case, clk type 0 ========
							3:
								begin
									register[l1] <= register_ks3_0[l1];
								end
							5:
								begin
									register[l1] <= register_ks5_0[l1];
								end
							// ======== End: kernel size case, clk type 0 ======== 
						endcase
					end
				end
				else if (clk_count%kernel_size == 0) begin // clk type 2
					for (l1=0; l1<`PARA_X; l1=l1+1)
					begin
                        case(kernel_size)
							// ======== Begin: kernel size case, clk type 2 ========
							3:
								begin
									register[l1] <= register_ks3_2[l1];
								end
							5:
								begin
									register[l1] <= register_ks5_2[l1];
								end
							// ======== End: kernel size case, clk type 2 ======== 
						endcase
					end
				end
				else if(clk_count > 0 && clk_count < kernel_size) begin // clk type 1
					for (l1=0; l1<`PARA_X; l1=l1+1)
					begin
                        case(kernel_size)
							// ======== Begin: kernel size case, clk type 1 ========
							3:
								begin
									register[l1] <= register_ks3_1[l1];
								end
							5:
								begin
									register[l1] <= register_ks5_1[l1];
								end
							// ======== End: kernel size case, clk type 1 ======== 
						endcase
					end
				end
				else begin // clk type 3
					for (l1=0; l1<`PARA_X; l1=l1+1)
					begin
                        case(kernel_size)
							// ======== Begin: kernel size case, clk type 3 ========
							3:
								begin
									register[l1] <= register_ks3_3[l1];
								end
							5:
								begin
									register[l1] <= register_ks5_3[l1];
								end
							// ======== End: kernel size case, clk type 3 ======== 
						endcase
					end
				end
				
				// ======== End: register operation ========

				clk_count <= clk_count + 1;
			end
		
		end
	end

endmodule