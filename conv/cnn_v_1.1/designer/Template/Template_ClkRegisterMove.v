							if (clk_count == 0) begin // clk type 0
								for (l1=0; l1<`PARA_X; l1=l1+1)
								begin
									case(kernel_size)
										// ======== Begin: kernel size case, clk type 0 ========
										// ======== End: kernel size case, clk type 0 ======== 
									endcase
								end
							end
							else if ((clk_count-(clk_count/kernel_size)*kernel_size) == 0) begin // clk type 2
								for (l1=0; l1<`PARA_X; l1=l1+1)
								begin
			                        case(kernel_size)
										// ======== Begin: kernel size case, clk type 2 ========
										// ======== End: kernel size case, clk type 2 ======== 
									endcase
								end
							end
							else if(clk_count > 0 && clk_count < kernel_size) begin // clk type 1
								for (l1=0; l1<`PARA_X; l1=l1+1)
								begin
			                        case(kernel_size)
										// ======== Begin: kernel size case, clk type 1 ========
										// ======== End: kernel size case, clk type 1 ======== 
									endcase
								end
							end
							else begin // clk type 3
								for (l1=0; l1<`PARA_X; l1=l1+1)
								begin
			                        case(kernel_size)
										// ======== Begin: kernel size case, clk type 3 ========
										// ======== End: kernel size case, clk type 3 ======== 
									endcase
								end
							end
				