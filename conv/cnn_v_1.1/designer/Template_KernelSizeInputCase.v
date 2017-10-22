                    SET_KERNEL_SIZE_CASE:
                        begin
                            for(l1=0; l1<`PARA_X*`PARA_Y; l1=l1+1)
                            begin
                                mult_a[l1] <= mult_a_temp_ksSET_KERNEL_SIZE_CASE[l1];
                            end
                        end
                        