									if (result_temp[`DATA_WIDTH*SET_INDEX_ADD_ONE - 1:`DATA_WIDTH*SET_INDEX_ADD_ONE - 1] == 1) begin
										result_buffer[`DATA_WIDTH*SET_INDEX_0_ADD_ONE - 1:`DATA_WIDTH*SET_INDEX_0] <= 0;
									end
									else begin
										result_buffer[`DATA_WIDTH*SET_INDEX_0_ADD_ONE - 1:`DATA_WIDTH*SET_INDEX_0] <= result_temp[`DATA_WIDTH*SET_INDEX_ADD_ONE - 1:`DATA_WIDTH*SET_INDEX];
									end 