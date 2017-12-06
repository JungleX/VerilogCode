`timescale 1ns / 1ps

`include "CNN_Parameter.vh"
 
module ConvParaScaleFloat16(
	input clk,
	input rst, // 0: reset; 1: none;

	input op_type, // 0: conv; 1:fc
	input [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] input_data, // op_type=0, input_data is fm data; op_type=1, input_data is weight data
	input [`DATA_WIDTH - 1:0] weight, // op_type=0, weight is weight data; op_type=1, weight is fm data

	input [`KERNEL_SIZE_WIDTH - 1:0] kernel_size, // op_type=0, input_data is conv kernerl size; op_type=1, kernel_size is fm all data number

	// activation
	input [1:0] activation, // 0: none; 1: ReLU. current just none or ReLU

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
			case(op_type)
				0: // conv
					begin
						if(clk_count == (clk_num + 1)) begin
							if (&mau_out_ready == 1) begin // MultAddUnits are ready
								clk_num <= kernel_size * kernel_size;

								clk_count		<= 0;
								result_ready	<= 1;

								// ======== Begin: result buffer ========
								if (activation == 0) begin // none
									result_buffer	<= {
														result_temp[`DATA_WIDTH*131 - 1:`DATA_WIDTH*130],
														result_temp[`DATA_WIDTH*132 - 1:`DATA_WIDTH*131],
														result_temp[`DATA_WIDTH*133 - 1:`DATA_WIDTH*132],
														result_temp[`DATA_WIDTH*134 - 1:`DATA_WIDTH*133],
														result_temp[`DATA_WIDTH*135 - 1:`DATA_WIDTH*134],
														result_temp[`DATA_WIDTH*136 - 1:`DATA_WIDTH*135],
														result_temp[`DATA_WIDTH*137 - 1:`DATA_WIDTH*136],
														result_temp[`DATA_WIDTH*138 - 1:`DATA_WIDTH*137],
														result_temp[`DATA_WIDTH*139 - 1:`DATA_WIDTH*138],
														result_temp[`DATA_WIDTH*140 - 1:`DATA_WIDTH*139],

														result_temp[`DATA_WIDTH*121 - 1:`DATA_WIDTH*120],
														result_temp[`DATA_WIDTH*122 - 1:`DATA_WIDTH*121],
														result_temp[`DATA_WIDTH*123 - 1:`DATA_WIDTH*122],
														result_temp[`DATA_WIDTH*124 - 1:`DATA_WIDTH*123],
														result_temp[`DATA_WIDTH*125 - 1:`DATA_WIDTH*124],
														result_temp[`DATA_WIDTH*126 - 1:`DATA_WIDTH*125],
														result_temp[`DATA_WIDTH*127 - 1:`DATA_WIDTH*126],
														result_temp[`DATA_WIDTH*128 - 1:`DATA_WIDTH*127],
														result_temp[`DATA_WIDTH*129 - 1:`DATA_WIDTH*128],
														result_temp[`DATA_WIDTH*130 - 1:`DATA_WIDTH*129],

														result_temp[`DATA_WIDTH*111 - 1:`DATA_WIDTH*110],
														result_temp[`DATA_WIDTH*112 - 1:`DATA_WIDTH*111],
														result_temp[`DATA_WIDTH*113 - 1:`DATA_WIDTH*112],
														result_temp[`DATA_WIDTH*114 - 1:`DATA_WIDTH*113],
														result_temp[`DATA_WIDTH*115 - 1:`DATA_WIDTH*114],
														result_temp[`DATA_WIDTH*116 - 1:`DATA_WIDTH*115],
														result_temp[`DATA_WIDTH*117 - 1:`DATA_WIDTH*116],
														result_temp[`DATA_WIDTH*118 - 1:`DATA_WIDTH*117],
														result_temp[`DATA_WIDTH*119 - 1:`DATA_WIDTH*118],
														result_temp[`DATA_WIDTH*120 - 1:`DATA_WIDTH*119],

														result_temp[`DATA_WIDTH*101 - 1:`DATA_WIDTH*100],
														result_temp[`DATA_WIDTH*102 - 1:`DATA_WIDTH*101],
														result_temp[`DATA_WIDTH*103 - 1:`DATA_WIDTH*102],
														result_temp[`DATA_WIDTH*104 - 1:`DATA_WIDTH*103],
														result_temp[`DATA_WIDTH*105 - 1:`DATA_WIDTH*104],
														result_temp[`DATA_WIDTH*106 - 1:`DATA_WIDTH*105],
														result_temp[`DATA_WIDTH*107 - 1:`DATA_WIDTH*106],
														result_temp[`DATA_WIDTH*108 - 1:`DATA_WIDTH*107],
														result_temp[`DATA_WIDTH*109 - 1:`DATA_WIDTH*108],
														result_temp[`DATA_WIDTH*110 - 1:`DATA_WIDTH*109],

														result_temp[`DATA_WIDTH*91 - 1:`DATA_WIDTH*90],
														result_temp[`DATA_WIDTH*92 - 1:`DATA_WIDTH*91],
														result_temp[`DATA_WIDTH*93 - 1:`DATA_WIDTH*92],
														result_temp[`DATA_WIDTH*94 - 1:`DATA_WIDTH*93],
														result_temp[`DATA_WIDTH*95 - 1:`DATA_WIDTH*94],
														result_temp[`DATA_WIDTH*96 - 1:`DATA_WIDTH*95],
														result_temp[`DATA_WIDTH*97 - 1:`DATA_WIDTH*96],
														result_temp[`DATA_WIDTH*98 - 1:`DATA_WIDTH*97],
														result_temp[`DATA_WIDTH*99 - 1:`DATA_WIDTH*98],
														result_temp[`DATA_WIDTH*100 - 1:`DATA_WIDTH*99],

														result_temp[`DATA_WIDTH*81 - 1:`DATA_WIDTH*80],
														result_temp[`DATA_WIDTH*82 - 1:`DATA_WIDTH*81],
														result_temp[`DATA_WIDTH*83 - 1:`DATA_WIDTH*82],
														result_temp[`DATA_WIDTH*84 - 1:`DATA_WIDTH*83],
														result_temp[`DATA_WIDTH*85 - 1:`DATA_WIDTH*84],
														result_temp[`DATA_WIDTH*86 - 1:`DATA_WIDTH*85],
														result_temp[`DATA_WIDTH*87 - 1:`DATA_WIDTH*86],
														result_temp[`DATA_WIDTH*88 - 1:`DATA_WIDTH*87],
														result_temp[`DATA_WIDTH*89 - 1:`DATA_WIDTH*88],
														result_temp[`DATA_WIDTH*90 - 1:`DATA_WIDTH*89],

														result_temp[`DATA_WIDTH*71 - 1:`DATA_WIDTH*70],
														result_temp[`DATA_WIDTH*72 - 1:`DATA_WIDTH*71],
														result_temp[`DATA_WIDTH*73 - 1:`DATA_WIDTH*72],
														result_temp[`DATA_WIDTH*74 - 1:`DATA_WIDTH*73],
														result_temp[`DATA_WIDTH*75 - 1:`DATA_WIDTH*74],
														result_temp[`DATA_WIDTH*76 - 1:`DATA_WIDTH*75],
														result_temp[`DATA_WIDTH*77 - 1:`DATA_WIDTH*76],
														result_temp[`DATA_WIDTH*78 - 1:`DATA_WIDTH*77],
														result_temp[`DATA_WIDTH*79 - 1:`DATA_WIDTH*78],
														result_temp[`DATA_WIDTH*80 - 1:`DATA_WIDTH*79],

														result_temp[`DATA_WIDTH*61 - 1:`DATA_WIDTH*60],
														result_temp[`DATA_WIDTH*62 - 1:`DATA_WIDTH*61],
														result_temp[`DATA_WIDTH*63 - 1:`DATA_WIDTH*62],
														result_temp[`DATA_WIDTH*64 - 1:`DATA_WIDTH*63],
														result_temp[`DATA_WIDTH*65 - 1:`DATA_WIDTH*64],
														result_temp[`DATA_WIDTH*66 - 1:`DATA_WIDTH*65],
														result_temp[`DATA_WIDTH*67 - 1:`DATA_WIDTH*66],
														result_temp[`DATA_WIDTH*68 - 1:`DATA_WIDTH*67],
														result_temp[`DATA_WIDTH*69 - 1:`DATA_WIDTH*68],
														result_temp[`DATA_WIDTH*70 - 1:`DATA_WIDTH*69],

														result_temp[`DATA_WIDTH*51 - 1:`DATA_WIDTH*50],
														result_temp[`DATA_WIDTH*52 - 1:`DATA_WIDTH*51],
														result_temp[`DATA_WIDTH*53 - 1:`DATA_WIDTH*52],
														result_temp[`DATA_WIDTH*54 - 1:`DATA_WIDTH*53],
														result_temp[`DATA_WIDTH*55 - 1:`DATA_WIDTH*54],
														result_temp[`DATA_WIDTH*56 - 1:`DATA_WIDTH*55],
														result_temp[`DATA_WIDTH*57 - 1:`DATA_WIDTH*56],
														result_temp[`DATA_WIDTH*58 - 1:`DATA_WIDTH*57],
														result_temp[`DATA_WIDTH*59 - 1:`DATA_WIDTH*58],
														result_temp[`DATA_WIDTH*60 - 1:`DATA_WIDTH*59],

														result_temp[`DATA_WIDTH*41 - 1:`DATA_WIDTH*40],
														result_temp[`DATA_WIDTH*42 - 1:`DATA_WIDTH*41],
														result_temp[`DATA_WIDTH*43 - 1:`DATA_WIDTH*42],
														result_temp[`DATA_WIDTH*44 - 1:`DATA_WIDTH*43],
														result_temp[`DATA_WIDTH*45 - 1:`DATA_WIDTH*44],
														result_temp[`DATA_WIDTH*46 - 1:`DATA_WIDTH*45],
														result_temp[`DATA_WIDTH*47 - 1:`DATA_WIDTH*46],
														result_temp[`DATA_WIDTH*48 - 1:`DATA_WIDTH*47],
														result_temp[`DATA_WIDTH*49 - 1:`DATA_WIDTH*48],
														result_temp[`DATA_WIDTH*50 - 1:`DATA_WIDTH*49],

														result_temp[`DATA_WIDTH*31 - 1:`DATA_WIDTH*30],
														result_temp[`DATA_WIDTH*32 - 1:`DATA_WIDTH*31],
														result_temp[`DATA_WIDTH*33 - 1:`DATA_WIDTH*32],
														result_temp[`DATA_WIDTH*34 - 1:`DATA_WIDTH*33],
														result_temp[`DATA_WIDTH*35 - 1:`DATA_WIDTH*34],
														result_temp[`DATA_WIDTH*36 - 1:`DATA_WIDTH*35],
														result_temp[`DATA_WIDTH*37 - 1:`DATA_WIDTH*36],
														result_temp[`DATA_WIDTH*38 - 1:`DATA_WIDTH*37],
														result_temp[`DATA_WIDTH*39 - 1:`DATA_WIDTH*38],
														result_temp[`DATA_WIDTH*40 - 1:`DATA_WIDTH*39],

														result_temp[`DATA_WIDTH*21 - 1:`DATA_WIDTH*20],
														result_temp[`DATA_WIDTH*22 - 1:`DATA_WIDTH*21],
														result_temp[`DATA_WIDTH*23 - 1:`DATA_WIDTH*22],
														result_temp[`DATA_WIDTH*24 - 1:`DATA_WIDTH*23],
														result_temp[`DATA_WIDTH*25 - 1:`DATA_WIDTH*24],
														result_temp[`DATA_WIDTH*26 - 1:`DATA_WIDTH*25],
														result_temp[`DATA_WIDTH*27 - 1:`DATA_WIDTH*26],
														result_temp[`DATA_WIDTH*28 - 1:`DATA_WIDTH*27],
														result_temp[`DATA_WIDTH*29 - 1:`DATA_WIDTH*28],
														result_temp[`DATA_WIDTH*30 - 1:`DATA_WIDTH*29],

														result_temp[`DATA_WIDTH*11 - 1:`DATA_WIDTH*10],
														result_temp[`DATA_WIDTH*12 - 1:`DATA_WIDTH*11],
														result_temp[`DATA_WIDTH*13 - 1:`DATA_WIDTH*12],
														result_temp[`DATA_WIDTH*14 - 1:`DATA_WIDTH*13],
														result_temp[`DATA_WIDTH*15 - 1:`DATA_WIDTH*14],
														result_temp[`DATA_WIDTH*16 - 1:`DATA_WIDTH*15],
														result_temp[`DATA_WIDTH*17 - 1:`DATA_WIDTH*16],
														result_temp[`DATA_WIDTH*18 - 1:`DATA_WIDTH*17],
														result_temp[`DATA_WIDTH*19 - 1:`DATA_WIDTH*18],
														result_temp[`DATA_WIDTH*20 - 1:`DATA_WIDTH*19],

														result_temp[`DATA_WIDTH*1 - 1:`DATA_WIDTH*0],
														result_temp[`DATA_WIDTH*2 - 1:`DATA_WIDTH*1],
														result_temp[`DATA_WIDTH*3 - 1:`DATA_WIDTH*2],
														result_temp[`DATA_WIDTH*4 - 1:`DATA_WIDTH*3],
														result_temp[`DATA_WIDTH*5 - 1:`DATA_WIDTH*4],
														result_temp[`DATA_WIDTH*6 - 1:`DATA_WIDTH*5],
														result_temp[`DATA_WIDTH*7 - 1:`DATA_WIDTH*6],
														result_temp[`DATA_WIDTH*8 - 1:`DATA_WIDTH*7],
														result_temp[`DATA_WIDTH*9 - 1:`DATA_WIDTH*8],
														result_temp[`DATA_WIDTH*10 - 1:`DATA_WIDTH*9]
													};
								end
								else if (activation == 1) begin // ReLU
									if (result_temp[`DATA_WIDTH*131 - 1:`DATA_WIDTH*131 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*140 - 1:`DATA_WIDTH*139] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*140 - 1:`DATA_WIDTH*139] <= result_temp[`DATA_WIDTH*131 - 1:`DATA_WIDTH*130];
									end
									if (result_temp[`DATA_WIDTH*132 - 1:`DATA_WIDTH*132 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*139 - 1:`DATA_WIDTH*138] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*139 - 1:`DATA_WIDTH*138] <= result_temp[`DATA_WIDTH*132 - 1:`DATA_WIDTH*131];
									end
									if (result_temp[`DATA_WIDTH*133 - 1:`DATA_WIDTH*133 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*138 - 1:`DATA_WIDTH*137] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*138 - 1:`DATA_WIDTH*137] <= result_temp[`DATA_WIDTH*133 - 1:`DATA_WIDTH*132];
									end
									if (result_temp[`DATA_WIDTH*134 - 1:`DATA_WIDTH*134 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*137 - 1:`DATA_WIDTH*136] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*137 - 1:`DATA_WIDTH*136] <= result_temp[`DATA_WIDTH*134 - 1:`DATA_WIDTH*133];
									end
									if (result_temp[`DATA_WIDTH*135 - 1:`DATA_WIDTH*135 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*136 - 1:`DATA_WIDTH*135] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*136 - 1:`DATA_WIDTH*135] <= result_temp[`DATA_WIDTH*135 - 1:`DATA_WIDTH*134];
									end
									if (result_temp[`DATA_WIDTH*136 - 1:`DATA_WIDTH*136 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*135 - 1:`DATA_WIDTH*134] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*135 - 1:`DATA_WIDTH*134] <= result_temp[`DATA_WIDTH*136 - 1:`DATA_WIDTH*135];
									end
									if (result_temp[`DATA_WIDTH*137 - 1:`DATA_WIDTH*137 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*134 - 1:`DATA_WIDTH*133] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*134 - 1:`DATA_WIDTH*133] <= result_temp[`DATA_WIDTH*137 - 1:`DATA_WIDTH*136];
									end
									if (result_temp[`DATA_WIDTH*138 - 1:`DATA_WIDTH*138 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*133 - 1:`DATA_WIDTH*132] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*133 - 1:`DATA_WIDTH*132] <= result_temp[`DATA_WIDTH*138 - 1:`DATA_WIDTH*137];
									end
									if (result_temp[`DATA_WIDTH*139 - 1:`DATA_WIDTH*139 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*132 - 1:`DATA_WIDTH*131] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*132 - 1:`DATA_WIDTH*131] <= result_temp[`DATA_WIDTH*139 - 1:`DATA_WIDTH*138];
									end
									if (result_temp[`DATA_WIDTH*140 - 1:`DATA_WIDTH*140 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*131 - 1:`DATA_WIDTH*130] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*131 - 1:`DATA_WIDTH*130] <= result_temp[`DATA_WIDTH*140 - 1:`DATA_WIDTH*139];
									end

									if (result_temp[`DATA_WIDTH*121 - 1:`DATA_WIDTH*121 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*130 - 1:`DATA_WIDTH*129] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*130 - 1:`DATA_WIDTH*129] <= result_temp[`DATA_WIDTH*121 - 1:`DATA_WIDTH*120];
									end
									if (result_temp[`DATA_WIDTH*122 - 1:`DATA_WIDTH*122 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*129 - 1:`DATA_WIDTH*128] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*129 - 1:`DATA_WIDTH*128] <= result_temp[`DATA_WIDTH*122 - 1:`DATA_WIDTH*121];
									end
									if (result_temp[`DATA_WIDTH*123 - 1:`DATA_WIDTH*123 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*128 - 1:`DATA_WIDTH*127] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*128 - 1:`DATA_WIDTH*127] <= result_temp[`DATA_WIDTH*123 - 1:`DATA_WIDTH*122];
									end
									if (result_temp[`DATA_WIDTH*124 - 1:`DATA_WIDTH*124 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*127 - 1:`DATA_WIDTH*126] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*127 - 1:`DATA_WIDTH*126] <= result_temp[`DATA_WIDTH*124 - 1:`DATA_WIDTH*123];
									end
									if (result_temp[`DATA_WIDTH*125 - 1:`DATA_WIDTH*125 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*126 - 1:`DATA_WIDTH*125] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*126 - 1:`DATA_WIDTH*125] <= result_temp[`DATA_WIDTH*125 - 1:`DATA_WIDTH*124];
									end
									if (result_temp[`DATA_WIDTH*126 - 1:`DATA_WIDTH*126 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*125 - 1:`DATA_WIDTH*124] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*125 - 1:`DATA_WIDTH*124] <= result_temp[`DATA_WIDTH*126 - 1:`DATA_WIDTH*125];
									end
									if (result_temp[`DATA_WIDTH*127 - 1:`DATA_WIDTH*127 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*124 - 1:`DATA_WIDTH*123] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*124 - 1:`DATA_WIDTH*123] <= result_temp[`DATA_WIDTH*127 - 1:`DATA_WIDTH*126];
									end
									if (result_temp[`DATA_WIDTH*128 - 1:`DATA_WIDTH*128 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*123 - 1:`DATA_WIDTH*122] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*123 - 1:`DATA_WIDTH*122] <= result_temp[`DATA_WIDTH*128 - 1:`DATA_WIDTH*127];
									end
									if (result_temp[`DATA_WIDTH*129 - 1:`DATA_WIDTH*129 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*122 - 1:`DATA_WIDTH*121] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*122 - 1:`DATA_WIDTH*121] <= result_temp[`DATA_WIDTH*129 - 1:`DATA_WIDTH*128];
									end
									if (result_temp[`DATA_WIDTH*130 - 1:`DATA_WIDTH*130 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*121 - 1:`DATA_WIDTH*120] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*121 - 1:`DATA_WIDTH*120] <= result_temp[`DATA_WIDTH*130 - 1:`DATA_WIDTH*129];
									end

									if (result_temp[`DATA_WIDTH*111 - 1:`DATA_WIDTH*111 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*120 - 1:`DATA_WIDTH*119] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*120 - 1:`DATA_WIDTH*119] <= result_temp[`DATA_WIDTH*111 - 1:`DATA_WIDTH*110];
									end
									if (result_temp[`DATA_WIDTH*112 - 1:`DATA_WIDTH*112 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*119 - 1:`DATA_WIDTH*118] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*119 - 1:`DATA_WIDTH*118] <= result_temp[`DATA_WIDTH*112 - 1:`DATA_WIDTH*111];
									end
									if (result_temp[`DATA_WIDTH*113 - 1:`DATA_WIDTH*113 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*118 - 1:`DATA_WIDTH*117] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*118 - 1:`DATA_WIDTH*117] <= result_temp[`DATA_WIDTH*113 - 1:`DATA_WIDTH*112];
									end
									if (result_temp[`DATA_WIDTH*114 - 1:`DATA_WIDTH*114 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*117 - 1:`DATA_WIDTH*116] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*117 - 1:`DATA_WIDTH*116] <= result_temp[`DATA_WIDTH*114 - 1:`DATA_WIDTH*113];
									end
									if (result_temp[`DATA_WIDTH*115 - 1:`DATA_WIDTH*115 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*116 - 1:`DATA_WIDTH*115] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*116 - 1:`DATA_WIDTH*115] <= result_temp[`DATA_WIDTH*115 - 1:`DATA_WIDTH*114];
									end
									if (result_temp[`DATA_WIDTH*116 - 1:`DATA_WIDTH*116 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*115 - 1:`DATA_WIDTH*114] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*115 - 1:`DATA_WIDTH*114] <= result_temp[`DATA_WIDTH*116 - 1:`DATA_WIDTH*115];
									end
									if (result_temp[`DATA_WIDTH*117 - 1:`DATA_WIDTH*117 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*114 - 1:`DATA_WIDTH*113] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*114 - 1:`DATA_WIDTH*113] <= result_temp[`DATA_WIDTH*117 - 1:`DATA_WIDTH*116];
									end
									if (result_temp[`DATA_WIDTH*118 - 1:`DATA_WIDTH*118 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*113 - 1:`DATA_WIDTH*112] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*113 - 1:`DATA_WIDTH*112] <= result_temp[`DATA_WIDTH*118 - 1:`DATA_WIDTH*117];
									end
									if (result_temp[`DATA_WIDTH*119 - 1:`DATA_WIDTH*119 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*112 - 1:`DATA_WIDTH*111] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*112 - 1:`DATA_WIDTH*111] <= result_temp[`DATA_WIDTH*119 - 1:`DATA_WIDTH*118];
									end
									if (result_temp[`DATA_WIDTH*120 - 1:`DATA_WIDTH*120 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*111 - 1:`DATA_WIDTH*110] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*111 - 1:`DATA_WIDTH*110] <= result_temp[`DATA_WIDTH*120 - 1:`DATA_WIDTH*119];
									end

									if (result_temp[`DATA_WIDTH*101 - 1:`DATA_WIDTH*101 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*110 - 1:`DATA_WIDTH*109] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*110 - 1:`DATA_WIDTH*109] <= result_temp[`DATA_WIDTH*101 - 1:`DATA_WIDTH*100];
									end
									if (result_temp[`DATA_WIDTH*102 - 1:`DATA_WIDTH*102 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*109 - 1:`DATA_WIDTH*108] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*109 - 1:`DATA_WIDTH*108] <= result_temp[`DATA_WIDTH*102 - 1:`DATA_WIDTH*101];
									end
									if (result_temp[`DATA_WIDTH*103 - 1:`DATA_WIDTH*103 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*108 - 1:`DATA_WIDTH*107] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*108 - 1:`DATA_WIDTH*107] <= result_temp[`DATA_WIDTH*103 - 1:`DATA_WIDTH*102];
									end
									if (result_temp[`DATA_WIDTH*104 - 1:`DATA_WIDTH*104 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*107 - 1:`DATA_WIDTH*106] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*107 - 1:`DATA_WIDTH*106] <= result_temp[`DATA_WIDTH*104 - 1:`DATA_WIDTH*103];
									end
									if (result_temp[`DATA_WIDTH*105 - 1:`DATA_WIDTH*105 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*106 - 1:`DATA_WIDTH*105] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*106 - 1:`DATA_WIDTH*105] <= result_temp[`DATA_WIDTH*105 - 1:`DATA_WIDTH*104];
									end
									if (result_temp[`DATA_WIDTH*106 - 1:`DATA_WIDTH*106 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*105 - 1:`DATA_WIDTH*104] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*105 - 1:`DATA_WIDTH*104] <= result_temp[`DATA_WIDTH*106 - 1:`DATA_WIDTH*105];
									end
									if (result_temp[`DATA_WIDTH*107 - 1:`DATA_WIDTH*107 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*104 - 1:`DATA_WIDTH*103] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*104 - 1:`DATA_WIDTH*103] <= result_temp[`DATA_WIDTH*107 - 1:`DATA_WIDTH*106];
									end
									if (result_temp[`DATA_WIDTH*108 - 1:`DATA_WIDTH*108 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*103 - 1:`DATA_WIDTH*102] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*103 - 1:`DATA_WIDTH*102] <= result_temp[`DATA_WIDTH*108 - 1:`DATA_WIDTH*107];
									end
									if (result_temp[`DATA_WIDTH*109 - 1:`DATA_WIDTH*109 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*102 - 1:`DATA_WIDTH*101] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*102 - 1:`DATA_WIDTH*101] <= result_temp[`DATA_WIDTH*109 - 1:`DATA_WIDTH*108];
									end
									if (result_temp[`DATA_WIDTH*110 - 1:`DATA_WIDTH*110 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*101 - 1:`DATA_WIDTH*100] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*101 - 1:`DATA_WIDTH*100] <= result_temp[`DATA_WIDTH*110 - 1:`DATA_WIDTH*109];
									end

									if (result_temp[`DATA_WIDTH*91 - 1:`DATA_WIDTH*91 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*100 - 1:`DATA_WIDTH*99] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*100 - 1:`DATA_WIDTH*99] <= result_temp[`DATA_WIDTH*91 - 1:`DATA_WIDTH*90];
									end
									if (result_temp[`DATA_WIDTH*92 - 1:`DATA_WIDTH*92 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*99 - 1:`DATA_WIDTH*98] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*99 - 1:`DATA_WIDTH*98] <= result_temp[`DATA_WIDTH*92 - 1:`DATA_WIDTH*91];
									end
									if (result_temp[`DATA_WIDTH*93 - 1:`DATA_WIDTH*93 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*98 - 1:`DATA_WIDTH*97] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*98 - 1:`DATA_WIDTH*97] <= result_temp[`DATA_WIDTH*93 - 1:`DATA_WIDTH*92];
									end
									if (result_temp[`DATA_WIDTH*94 - 1:`DATA_WIDTH*94 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*97 - 1:`DATA_WIDTH*96] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*97 - 1:`DATA_WIDTH*96] <= result_temp[`DATA_WIDTH*94 - 1:`DATA_WIDTH*93];
									end
									if (result_temp[`DATA_WIDTH*95 - 1:`DATA_WIDTH*95 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*96 - 1:`DATA_WIDTH*95] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*96 - 1:`DATA_WIDTH*95] <= result_temp[`DATA_WIDTH*95 - 1:`DATA_WIDTH*94];
									end
									if (result_temp[`DATA_WIDTH*96 - 1:`DATA_WIDTH*96 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*95 - 1:`DATA_WIDTH*94] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*95 - 1:`DATA_WIDTH*94] <= result_temp[`DATA_WIDTH*96 - 1:`DATA_WIDTH*95];
									end
									if (result_temp[`DATA_WIDTH*97 - 1:`DATA_WIDTH*97 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*94 - 1:`DATA_WIDTH*93] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*94 - 1:`DATA_WIDTH*93] <= result_temp[`DATA_WIDTH*97 - 1:`DATA_WIDTH*96];
									end
									if (result_temp[`DATA_WIDTH*98 - 1:`DATA_WIDTH*98 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*93 - 1:`DATA_WIDTH*92] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*93 - 1:`DATA_WIDTH*92] <= result_temp[`DATA_WIDTH*98 - 1:`DATA_WIDTH*97];
									end
									if (result_temp[`DATA_WIDTH*99 - 1:`DATA_WIDTH*99 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*92 - 1:`DATA_WIDTH*91] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*92 - 1:`DATA_WIDTH*91] <= result_temp[`DATA_WIDTH*99 - 1:`DATA_WIDTH*98];
									end
									if (result_temp[`DATA_WIDTH*100 - 1:`DATA_WIDTH*100 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*91 - 1:`DATA_WIDTH*90] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*91 - 1:`DATA_WIDTH*90] <= result_temp[`DATA_WIDTH*100 - 1:`DATA_WIDTH*99];
									end

									if (result_temp[`DATA_WIDTH*81 - 1:`DATA_WIDTH*81 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*90 - 1:`DATA_WIDTH*89] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*90 - 1:`DATA_WIDTH*89] <= result_temp[`DATA_WIDTH*81 - 1:`DATA_WIDTH*80];
									end
									if (result_temp[`DATA_WIDTH*82 - 1:`DATA_WIDTH*82 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*89 - 1:`DATA_WIDTH*88] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*89 - 1:`DATA_WIDTH*88] <= result_temp[`DATA_WIDTH*82 - 1:`DATA_WIDTH*81];
									end
									if (result_temp[`DATA_WIDTH*83 - 1:`DATA_WIDTH*83 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*88 - 1:`DATA_WIDTH*87] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*88 - 1:`DATA_WIDTH*87] <= result_temp[`DATA_WIDTH*83 - 1:`DATA_WIDTH*82];
									end
									if (result_temp[`DATA_WIDTH*84 - 1:`DATA_WIDTH*84 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*87 - 1:`DATA_WIDTH*86] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*87 - 1:`DATA_WIDTH*86] <= result_temp[`DATA_WIDTH*84 - 1:`DATA_WIDTH*83];
									end
									if (result_temp[`DATA_WIDTH*85 - 1:`DATA_WIDTH*85 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*86 - 1:`DATA_WIDTH*85] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*86 - 1:`DATA_WIDTH*85] <= result_temp[`DATA_WIDTH*85 - 1:`DATA_WIDTH*84];
									end
									if (result_temp[`DATA_WIDTH*86 - 1:`DATA_WIDTH*86 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*85 - 1:`DATA_WIDTH*84] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*85 - 1:`DATA_WIDTH*84] <= result_temp[`DATA_WIDTH*86 - 1:`DATA_WIDTH*85];
									end
									if (result_temp[`DATA_WIDTH*87 - 1:`DATA_WIDTH*87 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*84 - 1:`DATA_WIDTH*83] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*84 - 1:`DATA_WIDTH*83] <= result_temp[`DATA_WIDTH*87 - 1:`DATA_WIDTH*86];
									end
									if (result_temp[`DATA_WIDTH*88 - 1:`DATA_WIDTH*88 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*83 - 1:`DATA_WIDTH*82] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*83 - 1:`DATA_WIDTH*82] <= result_temp[`DATA_WIDTH*88 - 1:`DATA_WIDTH*87];
									end
									if (result_temp[`DATA_WIDTH*89 - 1:`DATA_WIDTH*89 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*82 - 1:`DATA_WIDTH*81] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*82 - 1:`DATA_WIDTH*81] <= result_temp[`DATA_WIDTH*89 - 1:`DATA_WIDTH*88];
									end
									if (result_temp[`DATA_WIDTH*90 - 1:`DATA_WIDTH*90 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*81 - 1:`DATA_WIDTH*80] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*81 - 1:`DATA_WIDTH*80] <= result_temp[`DATA_WIDTH*90 - 1:`DATA_WIDTH*89];
									end

									if (result_temp[`DATA_WIDTH*71 - 1:`DATA_WIDTH*71 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*80 - 1:`DATA_WIDTH*79] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*80 - 1:`DATA_WIDTH*79] <= result_temp[`DATA_WIDTH*71 - 1:`DATA_WIDTH*70];
									end
									if (result_temp[`DATA_WIDTH*72 - 1:`DATA_WIDTH*72 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*79 - 1:`DATA_WIDTH*78] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*79 - 1:`DATA_WIDTH*78] <= result_temp[`DATA_WIDTH*72 - 1:`DATA_WIDTH*71];
									end
									if (result_temp[`DATA_WIDTH*73 - 1:`DATA_WIDTH*73 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*78 - 1:`DATA_WIDTH*77] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*78 - 1:`DATA_WIDTH*77] <= result_temp[`DATA_WIDTH*73 - 1:`DATA_WIDTH*72];
									end
									if (result_temp[`DATA_WIDTH*74 - 1:`DATA_WIDTH*74 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*77 - 1:`DATA_WIDTH*76] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*77 - 1:`DATA_WIDTH*76] <= result_temp[`DATA_WIDTH*74 - 1:`DATA_WIDTH*73];
									end
									if (result_temp[`DATA_WIDTH*75 - 1:`DATA_WIDTH*75 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*76 - 1:`DATA_WIDTH*75] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*76 - 1:`DATA_WIDTH*75] <= result_temp[`DATA_WIDTH*75 - 1:`DATA_WIDTH*74];
									end
									if (result_temp[`DATA_WIDTH*76 - 1:`DATA_WIDTH*76 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*75 - 1:`DATA_WIDTH*74] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*75 - 1:`DATA_WIDTH*74] <= result_temp[`DATA_WIDTH*76 - 1:`DATA_WIDTH*75];
									end
									if (result_temp[`DATA_WIDTH*77 - 1:`DATA_WIDTH*77 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*74 - 1:`DATA_WIDTH*73] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*74 - 1:`DATA_WIDTH*73] <= result_temp[`DATA_WIDTH*77 - 1:`DATA_WIDTH*76];
									end
									if (result_temp[`DATA_WIDTH*78 - 1:`DATA_WIDTH*78 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*73 - 1:`DATA_WIDTH*72] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*73 - 1:`DATA_WIDTH*72] <= result_temp[`DATA_WIDTH*78 - 1:`DATA_WIDTH*77];
									end
									if (result_temp[`DATA_WIDTH*79 - 1:`DATA_WIDTH*79 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*72 - 1:`DATA_WIDTH*71] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*72 - 1:`DATA_WIDTH*71] <= result_temp[`DATA_WIDTH*79 - 1:`DATA_WIDTH*78];
									end
									if (result_temp[`DATA_WIDTH*80 - 1:`DATA_WIDTH*80 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*71 - 1:`DATA_WIDTH*70] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*71 - 1:`DATA_WIDTH*70] <= result_temp[`DATA_WIDTH*80 - 1:`DATA_WIDTH*79];
									end

									if (result_temp[`DATA_WIDTH*61 - 1:`DATA_WIDTH*61 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*70 - 1:`DATA_WIDTH*69] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*70 - 1:`DATA_WIDTH*69] <= result_temp[`DATA_WIDTH*61 - 1:`DATA_WIDTH*60];
									end
									if (result_temp[`DATA_WIDTH*62 - 1:`DATA_WIDTH*62 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*69 - 1:`DATA_WIDTH*68] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*69 - 1:`DATA_WIDTH*68] <= result_temp[`DATA_WIDTH*62 - 1:`DATA_WIDTH*61];
									end
									if (result_temp[`DATA_WIDTH*63 - 1:`DATA_WIDTH*63 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*68 - 1:`DATA_WIDTH*67] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*68 - 1:`DATA_WIDTH*67] <= result_temp[`DATA_WIDTH*63 - 1:`DATA_WIDTH*62];
									end
									if (result_temp[`DATA_WIDTH*64 - 1:`DATA_WIDTH*64 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*67 - 1:`DATA_WIDTH*66] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*67 - 1:`DATA_WIDTH*66] <= result_temp[`DATA_WIDTH*64 - 1:`DATA_WIDTH*63];
									end
									if (result_temp[`DATA_WIDTH*65 - 1:`DATA_WIDTH*65 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*66 - 1:`DATA_WIDTH*65] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*66 - 1:`DATA_WIDTH*65] <= result_temp[`DATA_WIDTH*65 - 1:`DATA_WIDTH*64];
									end
									if (result_temp[`DATA_WIDTH*66 - 1:`DATA_WIDTH*66 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*65 - 1:`DATA_WIDTH*64] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*65 - 1:`DATA_WIDTH*64] <= result_temp[`DATA_WIDTH*66 - 1:`DATA_WIDTH*65];
									end
									if (result_temp[`DATA_WIDTH*67 - 1:`DATA_WIDTH*67 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*64 - 1:`DATA_WIDTH*63] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*64 - 1:`DATA_WIDTH*63] <= result_temp[`DATA_WIDTH*67 - 1:`DATA_WIDTH*66];
									end
									if (result_temp[`DATA_WIDTH*68 - 1:`DATA_WIDTH*68 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*63 - 1:`DATA_WIDTH*62] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*63 - 1:`DATA_WIDTH*62] <= result_temp[`DATA_WIDTH*68 - 1:`DATA_WIDTH*67];
									end
									if (result_temp[`DATA_WIDTH*69 - 1:`DATA_WIDTH*69 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*62 - 1:`DATA_WIDTH*61] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*62 - 1:`DATA_WIDTH*61] <= result_temp[`DATA_WIDTH*69 - 1:`DATA_WIDTH*68];
									end
									if (result_temp[`DATA_WIDTH*70 - 1:`DATA_WIDTH*70 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*61 - 1:`DATA_WIDTH*60] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*61 - 1:`DATA_WIDTH*60] <= result_temp[`DATA_WIDTH*70 - 1:`DATA_WIDTH*69];
									end

									if (result_temp[`DATA_WIDTH*51 - 1:`DATA_WIDTH*51 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*60 - 1:`DATA_WIDTH*59] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*60 - 1:`DATA_WIDTH*59] <= result_temp[`DATA_WIDTH*51 - 1:`DATA_WIDTH*50];
									end
									if (result_temp[`DATA_WIDTH*52 - 1:`DATA_WIDTH*52 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*59 - 1:`DATA_WIDTH*58] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*59 - 1:`DATA_WIDTH*58] <= result_temp[`DATA_WIDTH*52 - 1:`DATA_WIDTH*51];
									end
									if (result_temp[`DATA_WIDTH*53 - 1:`DATA_WIDTH*53 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*58 - 1:`DATA_WIDTH*57] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*58 - 1:`DATA_WIDTH*57] <= result_temp[`DATA_WIDTH*53 - 1:`DATA_WIDTH*52];
									end
									if (result_temp[`DATA_WIDTH*54 - 1:`DATA_WIDTH*54 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*57 - 1:`DATA_WIDTH*56] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*57 - 1:`DATA_WIDTH*56] <= result_temp[`DATA_WIDTH*54 - 1:`DATA_WIDTH*53];
									end
									if (result_temp[`DATA_WIDTH*55 - 1:`DATA_WIDTH*55 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*56 - 1:`DATA_WIDTH*55] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*56 - 1:`DATA_WIDTH*55] <= result_temp[`DATA_WIDTH*55 - 1:`DATA_WIDTH*54];
									end
									if (result_temp[`DATA_WIDTH*56 - 1:`DATA_WIDTH*56 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*55 - 1:`DATA_WIDTH*54] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*55 - 1:`DATA_WIDTH*54] <= result_temp[`DATA_WIDTH*56 - 1:`DATA_WIDTH*55];
									end
									if (result_temp[`DATA_WIDTH*57 - 1:`DATA_WIDTH*57 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*54 - 1:`DATA_WIDTH*53] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*54 - 1:`DATA_WIDTH*53] <= result_temp[`DATA_WIDTH*57 - 1:`DATA_WIDTH*56];
									end
									if (result_temp[`DATA_WIDTH*58 - 1:`DATA_WIDTH*58 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*53 - 1:`DATA_WIDTH*52] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*53 - 1:`DATA_WIDTH*52] <= result_temp[`DATA_WIDTH*58 - 1:`DATA_WIDTH*57];
									end
									if (result_temp[`DATA_WIDTH*59 - 1:`DATA_WIDTH*59 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*52 - 1:`DATA_WIDTH*51] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*52 - 1:`DATA_WIDTH*51] <= result_temp[`DATA_WIDTH*59 - 1:`DATA_WIDTH*58];
									end
									if (result_temp[`DATA_WIDTH*60 - 1:`DATA_WIDTH*60 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*51 - 1:`DATA_WIDTH*50] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*51 - 1:`DATA_WIDTH*50] <= result_temp[`DATA_WIDTH*60 - 1:`DATA_WIDTH*59];
									end

									if (result_temp[`DATA_WIDTH*41 - 1:`DATA_WIDTH*41 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*50 - 1:`DATA_WIDTH*49] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*50 - 1:`DATA_WIDTH*49] <= result_temp[`DATA_WIDTH*41 - 1:`DATA_WIDTH*40];
									end
									if (result_temp[`DATA_WIDTH*42 - 1:`DATA_WIDTH*42 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*49 - 1:`DATA_WIDTH*48] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*49 - 1:`DATA_WIDTH*48] <= result_temp[`DATA_WIDTH*42 - 1:`DATA_WIDTH*41];
									end
									if (result_temp[`DATA_WIDTH*43 - 1:`DATA_WIDTH*43 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*48 - 1:`DATA_WIDTH*47] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*48 - 1:`DATA_WIDTH*47] <= result_temp[`DATA_WIDTH*43 - 1:`DATA_WIDTH*42];
									end
									if (result_temp[`DATA_WIDTH*44 - 1:`DATA_WIDTH*44 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*47 - 1:`DATA_WIDTH*46] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*47 - 1:`DATA_WIDTH*46] <= result_temp[`DATA_WIDTH*44 - 1:`DATA_WIDTH*43];
									end
									if (result_temp[`DATA_WIDTH*45 - 1:`DATA_WIDTH*45 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*46 - 1:`DATA_WIDTH*45] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*46 - 1:`DATA_WIDTH*45] <= result_temp[`DATA_WIDTH*45 - 1:`DATA_WIDTH*44];
									end
									if (result_temp[`DATA_WIDTH*46 - 1:`DATA_WIDTH*46 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*45 - 1:`DATA_WIDTH*44] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*45 - 1:`DATA_WIDTH*44] <= result_temp[`DATA_WIDTH*46 - 1:`DATA_WIDTH*45];
									end
									if (result_temp[`DATA_WIDTH*47 - 1:`DATA_WIDTH*47 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*44 - 1:`DATA_WIDTH*43] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*44 - 1:`DATA_WIDTH*43] <= result_temp[`DATA_WIDTH*47 - 1:`DATA_WIDTH*46];
									end
									if (result_temp[`DATA_WIDTH*48 - 1:`DATA_WIDTH*48 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*43 - 1:`DATA_WIDTH*42] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*43 - 1:`DATA_WIDTH*42] <= result_temp[`DATA_WIDTH*48 - 1:`DATA_WIDTH*47];
									end
									if (result_temp[`DATA_WIDTH*49 - 1:`DATA_WIDTH*49 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*42 - 1:`DATA_WIDTH*41] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*42 - 1:`DATA_WIDTH*41] <= result_temp[`DATA_WIDTH*49 - 1:`DATA_WIDTH*48];
									end
									if (result_temp[`DATA_WIDTH*50 - 1:`DATA_WIDTH*50 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*41 - 1:`DATA_WIDTH*40] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*41 - 1:`DATA_WIDTH*40] <= result_temp[`DATA_WIDTH*50 - 1:`DATA_WIDTH*49];
									end

									if (result_temp[`DATA_WIDTH*31 - 1:`DATA_WIDTH*31 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*40 - 1:`DATA_WIDTH*39] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*40 - 1:`DATA_WIDTH*39] <= result_temp[`DATA_WIDTH*31 - 1:`DATA_WIDTH*30];
									end
									if (result_temp[`DATA_WIDTH*32 - 1:`DATA_WIDTH*32 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*39 - 1:`DATA_WIDTH*38] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*39 - 1:`DATA_WIDTH*38] <= result_temp[`DATA_WIDTH*32 - 1:`DATA_WIDTH*31];
									end
									if (result_temp[`DATA_WIDTH*33 - 1:`DATA_WIDTH*33 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*38 - 1:`DATA_WIDTH*37] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*38 - 1:`DATA_WIDTH*37] <= result_temp[`DATA_WIDTH*33 - 1:`DATA_WIDTH*32];
									end
									if (result_temp[`DATA_WIDTH*34 - 1:`DATA_WIDTH*34 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*37 - 1:`DATA_WIDTH*36] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*37 - 1:`DATA_WIDTH*36] <= result_temp[`DATA_WIDTH*34 - 1:`DATA_WIDTH*33];
									end
									if (result_temp[`DATA_WIDTH*35 - 1:`DATA_WIDTH*35 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*36 - 1:`DATA_WIDTH*35] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*36 - 1:`DATA_WIDTH*35] <= result_temp[`DATA_WIDTH*35 - 1:`DATA_WIDTH*34];
									end
									if (result_temp[`DATA_WIDTH*36 - 1:`DATA_WIDTH*36 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*35 - 1:`DATA_WIDTH*34] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*35 - 1:`DATA_WIDTH*34] <= result_temp[`DATA_WIDTH*36 - 1:`DATA_WIDTH*35];
									end
									if (result_temp[`DATA_WIDTH*37 - 1:`DATA_WIDTH*37 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*34 - 1:`DATA_WIDTH*33] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*34 - 1:`DATA_WIDTH*33] <= result_temp[`DATA_WIDTH*37 - 1:`DATA_WIDTH*36];
									end
									if (result_temp[`DATA_WIDTH*38 - 1:`DATA_WIDTH*38 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*33 - 1:`DATA_WIDTH*32] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*33 - 1:`DATA_WIDTH*32] <= result_temp[`DATA_WIDTH*38 - 1:`DATA_WIDTH*37];
									end
									if (result_temp[`DATA_WIDTH*39 - 1:`DATA_WIDTH*39 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*32 - 1:`DATA_WIDTH*31] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*32 - 1:`DATA_WIDTH*31] <= result_temp[`DATA_WIDTH*39 - 1:`DATA_WIDTH*38];
									end
									if (result_temp[`DATA_WIDTH*40 - 1:`DATA_WIDTH*40 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*31 - 1:`DATA_WIDTH*30] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*31 - 1:`DATA_WIDTH*30] <= result_temp[`DATA_WIDTH*40 - 1:`DATA_WIDTH*39];
									end

									if (result_temp[`DATA_WIDTH*21 - 1:`DATA_WIDTH*21 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*30 - 1:`DATA_WIDTH*29] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*30 - 1:`DATA_WIDTH*29] <= result_temp[`DATA_WIDTH*21 - 1:`DATA_WIDTH*20];
									end
									if (result_temp[`DATA_WIDTH*22 - 1:`DATA_WIDTH*22 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*29 - 1:`DATA_WIDTH*28] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*29 - 1:`DATA_WIDTH*28] <= result_temp[`DATA_WIDTH*22 - 1:`DATA_WIDTH*21];
									end
									if (result_temp[`DATA_WIDTH*23 - 1:`DATA_WIDTH*23 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*28 - 1:`DATA_WIDTH*27] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*28 - 1:`DATA_WIDTH*27] <= result_temp[`DATA_WIDTH*23 - 1:`DATA_WIDTH*22];
									end
									if (result_temp[`DATA_WIDTH*24 - 1:`DATA_WIDTH*24 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*27 - 1:`DATA_WIDTH*26] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*27 - 1:`DATA_WIDTH*26] <= result_temp[`DATA_WIDTH*24 - 1:`DATA_WIDTH*23];
									end
									if (result_temp[`DATA_WIDTH*25 - 1:`DATA_WIDTH*25 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*26 - 1:`DATA_WIDTH*25] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*26 - 1:`DATA_WIDTH*25] <= result_temp[`DATA_WIDTH*25 - 1:`DATA_WIDTH*24];
									end
									if (result_temp[`DATA_WIDTH*26 - 1:`DATA_WIDTH*26 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*25 - 1:`DATA_WIDTH*24] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*25 - 1:`DATA_WIDTH*24] <= result_temp[`DATA_WIDTH*26 - 1:`DATA_WIDTH*25];
									end
									if (result_temp[`DATA_WIDTH*27 - 1:`DATA_WIDTH*27 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*24 - 1:`DATA_WIDTH*23] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*24 - 1:`DATA_WIDTH*23] <= result_temp[`DATA_WIDTH*27 - 1:`DATA_WIDTH*26];
									end
									if (result_temp[`DATA_WIDTH*28 - 1:`DATA_WIDTH*28 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*23 - 1:`DATA_WIDTH*22] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*23 - 1:`DATA_WIDTH*22] <= result_temp[`DATA_WIDTH*28 - 1:`DATA_WIDTH*27];
									end
									if (result_temp[`DATA_WIDTH*29 - 1:`DATA_WIDTH*29 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*22 - 1:`DATA_WIDTH*21] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*22 - 1:`DATA_WIDTH*21] <= result_temp[`DATA_WIDTH*29 - 1:`DATA_WIDTH*28];
									end
									if (result_temp[`DATA_WIDTH*30 - 1:`DATA_WIDTH*30 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*21 - 1:`DATA_WIDTH*20] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*21 - 1:`DATA_WIDTH*20] <= result_temp[`DATA_WIDTH*30 - 1:`DATA_WIDTH*29];
									end

									if (result_temp[`DATA_WIDTH*11 - 1:`DATA_WIDTH*11 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*20 - 1:`DATA_WIDTH*19] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*20 - 1:`DATA_WIDTH*19] <= result_temp[`DATA_WIDTH*11 - 1:`DATA_WIDTH*10];
									end
									if (result_temp[`DATA_WIDTH*12 - 1:`DATA_WIDTH*12 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*19 - 1:`DATA_WIDTH*18] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*19 - 1:`DATA_WIDTH*18] <= result_temp[`DATA_WIDTH*12 - 1:`DATA_WIDTH*11];
									end
									if (result_temp[`DATA_WIDTH*13 - 1:`DATA_WIDTH*13 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*18 - 1:`DATA_WIDTH*17] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*18 - 1:`DATA_WIDTH*17] <= result_temp[`DATA_WIDTH*13 - 1:`DATA_WIDTH*12];
									end
									if (result_temp[`DATA_WIDTH*14 - 1:`DATA_WIDTH*14 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*17 - 1:`DATA_WIDTH*16] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*17 - 1:`DATA_WIDTH*16] <= result_temp[`DATA_WIDTH*14 - 1:`DATA_WIDTH*13];
									end
									if (result_temp[`DATA_WIDTH*15 - 1:`DATA_WIDTH*15 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*16 - 1:`DATA_WIDTH*15] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*16 - 1:`DATA_WIDTH*15] <= result_temp[`DATA_WIDTH*15 - 1:`DATA_WIDTH*14];
									end
									if (result_temp[`DATA_WIDTH*16 - 1:`DATA_WIDTH*16 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*15 - 1:`DATA_WIDTH*14] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*15 - 1:`DATA_WIDTH*14] <= result_temp[`DATA_WIDTH*16 - 1:`DATA_WIDTH*15];
									end
									if (result_temp[`DATA_WIDTH*17 - 1:`DATA_WIDTH*17 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*14 - 1:`DATA_WIDTH*13] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*14 - 1:`DATA_WIDTH*13] <= result_temp[`DATA_WIDTH*17 - 1:`DATA_WIDTH*16];
									end
									if (result_temp[`DATA_WIDTH*18 - 1:`DATA_WIDTH*18 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*13 - 1:`DATA_WIDTH*12] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*13 - 1:`DATA_WIDTH*12] <= result_temp[`DATA_WIDTH*18 - 1:`DATA_WIDTH*17];
									end
									if (result_temp[`DATA_WIDTH*19 - 1:`DATA_WIDTH*19 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*12 - 1:`DATA_WIDTH*11] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*12 - 1:`DATA_WIDTH*11] <= result_temp[`DATA_WIDTH*19 - 1:`DATA_WIDTH*18];
									end
									if (result_temp[`DATA_WIDTH*20 - 1:`DATA_WIDTH*20 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*11 - 1:`DATA_WIDTH*10] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*11 - 1:`DATA_WIDTH*10] <= result_temp[`DATA_WIDTH*20 - 1:`DATA_WIDTH*19];
									end

									if (result_temp[`DATA_WIDTH*1 - 1:`DATA_WIDTH*1 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*10 - 1:`DATA_WIDTH*9] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*10 - 1:`DATA_WIDTH*9] <= result_temp[`DATA_WIDTH*1 - 1:`DATA_WIDTH*0];
									end
									if (result_temp[`DATA_WIDTH*2 - 1:`DATA_WIDTH*2 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*9 - 1:`DATA_WIDTH*8] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*9 - 1:`DATA_WIDTH*8] <= result_temp[`DATA_WIDTH*2 - 1:`DATA_WIDTH*1];
									end
									if (result_temp[`DATA_WIDTH*3 - 1:`DATA_WIDTH*3 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*8 - 1:`DATA_WIDTH*7] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*8 - 1:`DATA_WIDTH*7] <= result_temp[`DATA_WIDTH*3 - 1:`DATA_WIDTH*2];
									end
									if (result_temp[`DATA_WIDTH*4 - 1:`DATA_WIDTH*4 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*7 - 1:`DATA_WIDTH*6] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*7 - 1:`DATA_WIDTH*6] <= result_temp[`DATA_WIDTH*4 - 1:`DATA_WIDTH*3];
									end
									if (result_temp[`DATA_WIDTH*5 - 1:`DATA_WIDTH*5 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*6 - 1:`DATA_WIDTH*5] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*6 - 1:`DATA_WIDTH*5] <= result_temp[`DATA_WIDTH*5 - 1:`DATA_WIDTH*4];
									end
									if (result_temp[`DATA_WIDTH*6 - 1:`DATA_WIDTH*6 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*5 - 1:`DATA_WIDTH*4] <= result_temp[`DATA_WIDTH*6 - 1:`DATA_WIDTH*5];
									end
									if (result_temp[`DATA_WIDTH*7 - 1:`DATA_WIDTH*7 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*4 - 1:`DATA_WIDTH*3] <= result_temp[`DATA_WIDTH*7 - 1:`DATA_WIDTH*6];
									end
									if (result_temp[`DATA_WIDTH*8 - 1:`DATA_WIDTH*8 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*3 - 1:`DATA_WIDTH*2] <= result_temp[`DATA_WIDTH*8 - 1:`DATA_WIDTH*7];
									end
									if (result_temp[`DATA_WIDTH*9 - 1:`DATA_WIDTH*9 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*2 - 1:`DATA_WIDTH*1] <= result_temp[`DATA_WIDTH*9 - 1:`DATA_WIDTH*8];
									end
									if (result_temp[`DATA_WIDTH*10 - 1:`DATA_WIDTH*10 - 1] == 1) begin
										result_buffer[`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*1 - 1:`DATA_WIDTH*0] <= result_temp[`DATA_WIDTH*10 - 1:`DATA_WIDTH*9];
									end
								end
								// ======== End: result buffer ========

								mau_rst			<= 0;
							end
						end
						else begin
							result_ready		<= 0;
							
							mau_rst				<= 1;

							clk_num <= kernel_size * kernel_size;

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
										// ======== End: kernel size case, clk type 0 ======== 
									endcase
								end
							end
							else if ((clk_count-(clk_count/kernel_size)*kernel_size) == 0) begin // clk type 2
								for (l1=0; l1<`PARA_X; l1=l1+1)
								begin
			                        case(kernel_size)
										// ======== Begin: kernel size case, clk type 2 ========
										3:
											begin
												register[l1] <= register_ks3_2[l1];
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
										// ======== End: kernel size case, clk type 3 ======== 
									endcase
								end
							end
				
							// ======== End: register operation ========

							clk_count <= clk_count + 1;
						end
					end
				1: // fc
					begin
						if(clk_count == (clk_num + 1)) begin
							if (&mau_out_ready == 1) begin // MultAddUnits are ready
								clk_num <= kernel_size;

								clk_count		<= 0;
								result_ready	<= 1;

								// ======== Begin: result buffer ========
								result_buffer	<= {
													ma_result[0],
													ma_result[1],
													ma_result[2],
													ma_result[3],
													ma_result[4],
													ma_result[5],
													ma_result[6],
													ma_result[7],
													ma_result[8],
													ma_result[9]
												};
								// ======== End: result buffer ========

								mau_rst			<= 0;
							end
						end
						else begin
							result_ready		<= 0;
							
							mau_rst				<= 1;

							clk_num <= kernel_size;

							// ======== Begin: MultAddUnitFloat16 input data ========
								//                                  PARA_Y
								register[0] <= input_data[`DATA_WIDTH*10 - 1:`DATA_WIDTH*0];
							// ======== End: MultAddUnitFloat16 input data ========

							clk_count <= clk_count + 1;
						end
						
					end
			endcase
		end
	end

endmodule