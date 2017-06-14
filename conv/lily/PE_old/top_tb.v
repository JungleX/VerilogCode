`timescale 10ns/1ns
`include "bit_width.vh"

module top_tb();
reg clk;
reg enable;
reg [`PCIE_DATA_WIDTH-1:0] pcie_data[0:154586];   //227*227*3
reg [15:0] data;
wire finish;
wire ready;
integer loading_size = 0;

top top(.clk(clk),
    .enable(enable),
    .pcie_data(data),
    .ready(ready),
    .finish(finish));
    
initial
    begin
    clk = 0;
    enable = 0;
    $readmemb("H:/git/VerilogCode/conv/PE/image_0001.mem", pcie_data);
    #5 enable = 1;
    end
        
always #1 clk = ~clk;
    
always @(posedge clk)
begin
    if(!ready)
        loading_size <= 0;
    else begin
    if(loading_size<51529)
        begin
        data <= pcie_data[loading_size];
        loading_size <= loading_size+1;
        end
    end
end

endmodule