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
    
    input init,
    output reg start,
    
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

initial
begin
    fm_set_one <= {`PARA_X*`PARA_Y{16'h3c00}};
    weight_set_one <= {`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL{16'h3c00}};
end
//provide all-1 arrays for featuremap and weightram

always @(posedge clk) start <= init;

reg cnt;
reg update_ena = 1'b0;
reg [5:0] ini_cnt = 6'b0; 
always @(posedge clk) begin

    if (rst) begin
        init_fm_data <= 0;
        write_fm_data_addr <= 0;
        init_fm_data_done <= 0;
        weight_data <= 0;
        write_weight_data_addr <= 0;
        weight_data_done <= 0;
        update_ena <= 0;
    end
    
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
always @(posedge clk) if ((cnt == 1) && (init_fm_ram_ready == 1)) init_fm_data_done <= 0;
always @(posedge clk) if ((cnt == 1) && (init_weight_ram_ready == 1)) begin
weight_data_done <= 0;
update_ena <= 1;
end



always @(posedge clk) begin
if (update_weight_ram && update_ena) begin
weight_data <= weight_set_one;
write_weight_data_addr <= update_weight_ram_addr;
weight_data_done <= 1;
end
end

always @(posedge clk) begin
if((!update_weight_ram) && update_ena) weight_data_done <= 0;
end
//connection between signal "update" and weightram 
endmodule
