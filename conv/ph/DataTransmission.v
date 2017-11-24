`timescale 1ns / 1ps
`include "CNN_Parameter.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/23 21:48:21
// Design Name: 
// Module Name: DataTransmission
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module DataTransmission(
    input clk,
    input rst,
    
    input init,                                                               //init: a waveform generated in FSM which looks like:_____-______
    
    input update_weight_ram, // 0: not update; 1: update
    input [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] update_weight_ram_addr,
    
    input init_fm_ram_ready, // 0: not ready; 1: ready
    input init_weight_ram_ready, // 0: not ready; 1: ready
    
    output reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] init_fm_data,
    output reg [`WRITE_ADDR_WIDTH - 1:0] write_fm_data_addr,
    output reg init_fm_data_done = 1'b0,
    
    output reg [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_data,
    output reg [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] write_weight_data_addr,
    output reg weight_data_done // weight data transmission, 0: not ready; 1: ready
    );
    


reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] fm_set_one;
reg [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_set_one;

generate
genvar fm;
for(fm = 0;fm < `PARA_X*`PARA_Y;fm = fm + 1) 
begin:featuremap
always @(*)
fm_set_one[`DATA_WIDTH*(fm+1) - 1:`DATA_WIDTH*fm] = 16'h3c00;
end
endgenerate

generate
genvar wr;
for(wr = 0;wr<`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL;wr = wr + 1)
begin:weightram
always @(*)
weight_set_one[`DATA_WIDTH*(fm+1) - 1:`DATA_WIDTH*fm] = 16'h3c00;
end
endgenerate
//provide all-1 arrays for featuremap and weightram



reg cnt;
always @(posedge clk) begin
if (init) begin
init_fm_data <= fm_set_one;
write_fm_data_addr <= 0;
init_fm_data_done <= 1;
weight_data <= weight_set_one;
write_weight_data_addr <= 0;
weight_data_done <= 1;
cnt <= 0;
end
end//signal "init" sustains for only 1 clock cycle.



always @(posedge clk) if (cnt == 0) cnt <= 1; //delay for 1 clock cycle;
always @(posedge clk) if ((cnt == 1) && (init_fm_ram_ready == 1) && (init_weight_ram_ready == 1)) init_fm_data_done <= 0; //if both these two "ready" signals are 1,set signal "done" into 0.



//always @(posedge clk) begin
//if (update_weight_ram) begin
//weight_data <= {$random} % 2^`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH ;

//connection between signal "update" and weightram which is not conpleted yet
endmodule
