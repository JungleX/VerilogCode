`timescale 1ns / 1ps

`define clk_period 10

`include "CNN_Parameter.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/29 21:09:33
// Design Name: 
// Module Name: DTtb
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


module DTtb();
    reg clk;
    reg rst;
       
    reg init;
    wire start;
    
    reg update_weight_ram;// 0: not update; 1: update
    reg [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] update_weight_ram_addr;
    
    wire [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] init_fm_data;
    wire [`WRITE_ADDR_WIDTH - 1:0] write_fm_data_addr;
    wire init_fm_data_done;
    
    wire [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_data;
    wire [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] write_weight_data_addr;
    wire weight_data_done; // weight data transmission, 0: not ready; 1: ready
    
    wire update_ena;
    wire cnt1;
    wire cnt2;
    wire upp;
    
    DataTransmission cnn(
       .clk(clk),
       .rst(rst),
       
       .init(init),
       .start(start),
       
       .update_weight_ram(update_weight_ram), // 0: not update; 1: update
       .update_weight_ram_addr(update_weight_ram_addr),
       
       .init_fm_data(init_fm_data),
       .write_fm_data_addr(write_fm_data_addr),
       .init_fm_data_done(init_fm_data_done),
       
       .weight_data(weight_data),
       .write_weight_data_addr(write_weight_data_addr),
       .weight_data_done(weight_data_done),
       
       .update_ena(update_ena),
       .cnt1(cnt1),
       .cnt2(cnt2),
       .upp(upp)
    );
    
    
initial
clk = 1'b0;
always #(`clk_period/2) clk = ~clk;

initial begin
    #0
       
    #(`clk_period * 0.3)
    rst <= 1;
    
    #(`clk_period * 0.7)
    rst <= 0;
    
    #(`clk_period * 0.3)
    init <= 1;
    
    #(`clk_period * 0.2)
    
    #(`clk_period * 40)
    #(`clk_period)
    init <= 0;
    #(`clk_period * 10)
    #(`clk_period)
    update_weight_ram <= 1;
    update_weight_ram_addr <= 4;
    
    #(`clk_period * 10)
    #(`clk_period)
    update_weight_ram <= 0;
end
endmodule
