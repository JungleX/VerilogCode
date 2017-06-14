`include "bit_width.vh"

module conv(
    input[3:0] layer,
    input[15:0] pcie_data,
    input[127:0] infm,            //16*8
    output[127:0] outfm,
    output[135:0] addr                          //8 * (addr+1)    
    );
    
    parameter CONV1 = 4'b0001,CONV2 = 4'b0011,CONV3 = 4'b0101,CONV4 = 4'b0110,CONV5 = 4'b0111;
    
    

endmodule