`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/23 21:51:34
// Design Name: 
// Module Name: FSM
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


module FSM(
     input clk_p,
     input clk_n,
     input rst,
     input transmission_start
    );
    
IBUFDS #(
        .DIFF_TERM("FALSE"),
        .IBUF_LOW_PWR("TRUE"),
        .IOSTANDARD("DEFAULT")
         )IBUFDS_inst(
        .O(clk),
        .I(clk_p),
        .IB(clk_n)
        );    
        
reg workstate;
reg [`LAYER_NUM_WIDTH - 1:0] layer_num = `LAYER_NUM_WIDTH'b0;
reg [1:0] layer_type; // 0: prepare init feature map and weight data; 1:conv; 2:pool; 3:fc;
reg [1:0] pre_layer_type = 2'b00;

always @(*) assign workstate = transmission_start;

reg init = 1'b0;
reg dis_init = 1'b0;
always @(posedge clk) dis_init <= workstate;
always @(posedge clk) begin
if ((workstate == 1) && (dis_init == 0)) init <= 1'b1;
else init <= 1'b0;
end//generate a initial waveform which sustains for only 1 clock cycle,looking like:_______-_______

always @(posedge clk) begin
if (workstate) begin
case (layer_num)
3'b000:layer_type <= 2'b00;
3'b001:layer_type <= 2'b01;
3'b010:layer_type <= 2'b01;
3'b011:layer_type <= 2'b10;
3'b100:layer_type <= 2'b11;
default:layer_type <= 2'b00; 
endcase
end
end//define the layer type of each layer according to the structure of CNN.

    
endmodule
