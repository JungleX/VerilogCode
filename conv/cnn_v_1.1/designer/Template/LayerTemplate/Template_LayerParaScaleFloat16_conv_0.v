									fm_ena_add_write[SET_INDEX] <= 0;
									fm_ena_zero_w[SET_INDEX] 	<= 1;
									fm_ena_w[SET_INDEX] 		<= 0;
									fm_ena_para_w[SET_INDEX] 	<= 0;

									fm_zero_start_addr[SET_INDEX]	<= ((cur_fm_swap+1)-(((cur_fm_swap+1)/2)*2))*`FM_RAM_HALF;
									fm_zero_end_addr[SET_INDEX]		<= (((cur_fm_swap+1)-(((cur_fm_swap+1)/2)*2))+1)*`FM_RAM_HALF - 1;

									cur_out_index[SET_INDEX]	<= ((padding_out-SET_INDEX+`PARA_X-1)/`PARA_X)*((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y+padding_out; 