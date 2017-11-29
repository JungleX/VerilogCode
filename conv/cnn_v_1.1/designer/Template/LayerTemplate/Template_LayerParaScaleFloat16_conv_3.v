										weight_addr_read[SET_INDEX]	<= weight_addr_read[SET_INDEX] + 1;
										conv_weight[SET_INDEX]		<= weight_dout[SET_INDEX][`DATA_WIDTH - 1:0]; 