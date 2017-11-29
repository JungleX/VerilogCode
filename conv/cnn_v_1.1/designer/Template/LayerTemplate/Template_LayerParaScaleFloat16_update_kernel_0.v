							weight_ena_w[SET_INDEX]			<= 1;
							weight_addr_write[SET_INDEX]	<= write_weight_data_addr;
							weight_din[SET_INDEX]			<= weight_data[`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*SET_INDEX_ADD_ONE - 1:`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`DATA_WIDTH*SET_INDEX]; 