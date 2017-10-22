	// === Begin: kernel size = SET_KERNEL_SIZE_NUMBER ===
	// clk type 0
	// clk 0
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_SET_KERNEL_SIZE_FLAG_0[`PARA_X - 1:0];
	generate
		genvar k_SET_KERNEL_SIZE_FLAG_0;
		for (k_SET_KERNEL_SIZE_FLAG_0 = 0; k_SET_KERNEL_SIZE_FLAG_0 < `PARA_X; k_SET_KERNEL_SIZE_FLAG_0 = k_SET_KERNEL_SIZE_FLAG_0 + 1)
		begin:identifier_SET_KERNEL_SIZE_FLAG_0
			assign register_SET_KERNEL_SIZE_FLAG_0[k_SET_KERNEL_SIZE_FLAG_0][`DATA_WIDTH*(`PARA_Y+(SET_KERNEL_SIZE_NUMBER-1)) - 1:`DATA_WIDTH*(SET_KERNEL_SIZE_NUMBER-1)] = input_data[`DATA_WIDTH*(k_SET_KERNEL_SIZE_FLAG_0+1)*(`PARA_Y) - 1:`DATA_WIDTH*k_SET_KERNEL_SIZE_FLAG_0*(`PARA_Y)];
		end
	endgenerate

	// clk type 1
	// all register group, move and update
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_SET_KERNEL_SIZE_FLAG_1[`PARA_X - 1:0];
	generate
		genvar k_SET_KERNEL_SIZE_FLAG_1_1;
		genvar k_SET_KERNEL_SIZE_FLAG_1_2;
		for (k_SET_KERNEL_SIZE_FLAG_1_1 = 0; k_SET_KERNEL_SIZE_FLAG_1_1 < `PARA_X; k_SET_KERNEL_SIZE_FLAG_1_1 = k_SET_KERNEL_SIZE_FLAG_1_1 + 1)
		begin:identifier_SET_KERNEL_SIZE_FLAG_1_0
			for (k_SET_KERNEL_SIZE_FLAG_1_2 = 0; k_SET_KERNEL_SIZE_FLAG_1_2 < (`PARA_Y + (SET_KERNEL_SIZE_NUMBER - 2)); k_SET_KERNEL_SIZE_FLAG_1_2 = k_SET_KERNEL_SIZE_FLAG_1_2 + 1)
			begin:identifier_SET_KERNEL_SIZE_FLAG_1_1
				assign register_SET_KERNEL_SIZE_FLAG_1[k_SET_KERNEL_SIZE_FLAG_1_1][`DATA_WIDTH*(k_SET_KERNEL_SIZE_FLAG_1_2+1) - 1:`DATA_WIDTH*k_SET_KERNEL_SIZE_FLAG_1_2] = register[k_SET_KERNEL_SIZE_FLAG_1_1][`DATA_WIDTH*(k_SET_KERNEL_SIZE_FLAG_1_2+2) - 1:`DATA_WIDTH*(k_SET_KERNEL_SIZE_FLAG_1_2+1)];
			end

			assign register_SET_KERNEL_SIZE_FLAG_1[k_SET_KERNEL_SIZE_FLAG_1_1][`DATA_WIDTH*(`PARA_Y+(SET_KERNEL_SIZE_NUMBER-1)) - 1:`DATA_WIDTH*(`PARA_Y+(SET_KERNEL_SIZE_NUMBER-2))] = input_data[`DATA_WIDTH*(k_SET_KERNEL_SIZE_FLAG_1_1+1) - 1:`DATA_WIDTH*k_SET_KERNEL_SIZE_FLAG_1_1];
		end
	endgenerate

	// clk type 2
	// move between register group, update PARA_Y register in last register group
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_SET_KERNEL_SIZE_FLAG_2[`PARA_X - 1:0];
	generate
		genvar k_SET_KERNEL_SIZE_FLAG_2;
		for (k_SET_KERNEL_SIZE_FLAG_2 = 0; k_SET_KERNEL_SIZE_FLAG_2 < (`PARA_X - 1); k_SET_KERNEL_SIZE_FLAG_2 = k_SET_KERNEL_SIZE_FLAG_2 + 1)
		begin:identifier_SET_KERNEL_SIZE_FLAG_2
			assign register_SET_KERNEL_SIZE_FLAG_2[k_SET_KERNEL_SIZE_FLAG_2][`DATA_WIDTH*(`PARA_Y+(SET_KERNEL_SIZE_NUMBER-1)) - 1:`DATA_WIDTH*(SET_KERNEL_SIZE_NUMBER-1)] = register[k_SET_KERNEL_SIZE_FLAG_2+1][`DATA_WIDTH*`PARA_Y - 1:0];
			assign register_SET_KERNEL_SIZE_FLAG_2[k_SET_KERNEL_SIZE_FLAG_2][`DATA_WIDTH*(SET_KERNEL_SIZE_NUMBER-1) - 1:0] = register[k_SET_KERNEL_SIZE_FLAG_2+1][`DATA_WIDTH*(`PARA_Y+(SET_KERNEL_SIZE_NUMBER-1)) - 1:`DATA_WIDTH*`PARA_Y];
		end
		assign register_SET_KERNEL_SIZE_FLAG_2[`PARA_X - 1][`DATA_WIDTH*(`PARA_Y+(SET_KERNEL_SIZE_NUMBER-1)) - 1:`DATA_WIDTH*(SET_KERNEL_SIZE_NUMBER-1)] = input_data[`DATA_WIDTH*`PARA_Y - 1:0];
	endgenerate

	// clk tpye 3
	// move between register group, update one register in last register group
	wire [`DATA_WIDTH*(`PARA_Y + `KERNEL_SIZE_MAX - 1) - 1:0] register_SET_KERNEL_SIZE_FLAG_3[`PARA_X - 1:0];
	generate
		genvar k_SET_KERNEL_SIZE_FLAG_3_1;
		genvar k_SET_KERNEL_SIZE_FLAG_3_2;
		genvar k_SET_KERNEL_SIZE_FLAG_3_3;

		for (k_SET_KERNEL_SIZE_FLAG_3_1 = 0; k_SET_KERNEL_SIZE_FLAG_3_1 < (`PARA_X-1); k_SET_KERNEL_SIZE_FLAG_3_1 = k_SET_KERNEL_SIZE_FLAG_3_1 + 1)
		begin:identifier__SET_KERNEL_SIZE_FLAG_3_1
			for (k_SET_KERNEL_SIZE_FLAG_3_2 = 0; k_SET_KERNEL_SIZE_FLAG_3_2 < (`PARA_Y + (SET_KERNEL_SIZE_NUMBER - 2)); k_SET_KERNEL_SIZE_FLAG_3_2 = k_SET_KERNEL_SIZE_FLAG_3_2 + 1)
			begin:identifier_SET_KERNEL_SIZE_FLAG_3_1
				assign register_SET_KERNEL_SIZE_FLAG_3[k_SET_KERNEL_SIZE_FLAG_3_1][`DATA_WIDTH*(k_SET_KERNEL_SIZE_FLAG_3_2+1) - 1:`DATA_WIDTH*k_SET_KERNEL_SIZE_FLAG_3_2] = register[k_SET_KERNEL_SIZE_FLAG_3_1][`DATA_WIDTH*(k_SET_KERNEL_SIZE_FLAG_3_2+2) - 1:`DATA_WIDTH*(k_SET_KERNEL_SIZE_FLAG_3_2+1)];
			end

			assign register_SET_KERNEL_SIZE_FLAG_3[k_SET_KERNEL_SIZE_FLAG_3_1][`DATA_WIDTH*(`PARA_Y+(SET_KERNEL_SIZE_NUMBER-1)) - 1:`DATA_WIDTH*(`PARA_Y+(SET_KERNEL_SIZE_NUMBER-2))] = register[k_SET_KERNEL_SIZE_FLAG_3_1][`DATA_WIDTH - 1:0];
		end

		for (k_SET_KERNEL_SIZE_FLAG_3_3 = 0; k_SET_KERNEL_SIZE_FLAG_3_3 < (`PARA_Y + (SET_KERNEL_SIZE_NUMBER - 2)); k_SET_KERNEL_SIZE_FLAG_3_3 = k_SET_KERNEL_SIZE_FLAG_3_3 + 1)
		begin:identifier__SET_KERNEL_SIZE_FLAG_3_2
			assign register_SET_KERNEL_SIZE_FLAG_3[`PARA_X - 1][`DATA_WIDTH*(k_SET_KERNEL_SIZE_FLAG_3_3+1) - 1:`DATA_WIDTH*k_SET_KERNEL_SIZE_FLAG_3_3] = register[`PARA_X - 1][`DATA_WIDTH*(k_SET_KERNEL_SIZE_FLAG_3_3+2) - 1:`DATA_WIDTH*(k_SET_KERNEL_SIZE_FLAG_3_3+1)];
		end

		assign register_SET_KERNEL_SIZE_FLAG_3[`PARA_X - 1][`DATA_WIDTH*(`PARA_Y+(SET_KERNEL_SIZE_NUMBER-1)) - 1:`DATA_WIDTH*(`PARA_Y+(SET_KERNEL_SIZE_NUMBER-2))] = input_data[`DATA_WIDTH - 1:0];
	endgenerate
	// === End: kernel size = SET_KERNEL_SIZE_NUMBER ===

