										fm_ena_r[SET_INDEX]			<= 1;
										fm_addr_read[SET_INDEX]		<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fm_sub_addr_read[SET_INDEX]	<= 0; 