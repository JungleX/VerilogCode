										weight_ena_r[SET_INDEX]		<= 1;
										weight_ena_fc_r[SET_INDEX]	<= 0;
										weight_addr_read[SET_INDEX]	<= cur_kernel_swap*`WEIGHT_RAM_HALF + cur_kernel_slice*`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX; 