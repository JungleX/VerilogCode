						fmr_ena[SET_INDEX]		<= 1;
						fmr_wea[SET_INDEX]		<= 1;
						fmr_addra[SET_INDEX]	<= write_fm_data_addr;
						fmr_dina[SET_INDEX]		<= init_fm_data[`POOL_SIZE*`PARA_Y*`DATA_WIDTH*SET_INDEX_ADD_ONE - 1:`POOL_SIZE*`PARA_Y*`DATA_WIDTH*SET_INDEX]; 