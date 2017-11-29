													fm_ena_add_write[SET_INDEX] <= 1;
													fm_ena_zero_w[SET_INDEX] 	<= 0;
													fm_ena_w[SET_INDEX] 		<= 0;
													fm_ena_para_w[SET_INDEX] 	<= 1;
													fm_addr_para_write[SET_INDEX] <= fm_zero_start_addr[SET_INDEX] 
																			+ cur_out_slice*((fm_size_out+`PARA_X-1)/`PARA_X)*(((fm_size_out+`PARA_Y-1)/`PARA_Y)*`PARA_Y) 
																			+ cur_out_index[SET_INDEX]; 
													fm_out_size[SET_INDEX] <= fm_size_out; 

													fm_para_din[(cur_write_start_ram+SET_INDEX)-((cur_write_start_ram+SET_INDEX)/`PARA_X)*`PARA_X] <= {
																	}; 