										fmr_enb[SET_INDEX]		<= 1;
										//fmr_addrb[SET_INDEX]	<= cur_fm_swap*`FM_RAM_HALF + cur_x/`PARA_X*((fm_size+`PARA_Y-1)/`PARA_Y)+cur_y/`PARA_Y+cur_slice*((fm_size+`PARA_Y-1)/`PARA_Y)*((fm_size+`PARA_X-1)/`PARA_X);
										fmr_addrb[SET_INDEX]	<= 0;// test 