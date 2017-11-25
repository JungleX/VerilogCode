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

always @(*) assign workstate = transmission_start & (!rst);
always @(posedge clk)
if (rst) begin
layer_num = `LAYER_NUM_WIDTH'b0;
pre_layer_type = 2'b00;
end

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



wire update_weight_ram; // 0: not update; 1: update
wire [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] update_weight_ram_addr;
wire init_fm_ram_ready; // 0: not ready; 1: ready
wire init_weight_ram_ready;
wire [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] init_fm_data;
wire [`WRITE_ADDR_WIDTH - 1:0] write_fm_data_addr;
wire init_fm_data_done;
wire [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_data;
wire [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] write_weight_data_addr;
wire weight_data_done;

DataTransmission DT(
    .clk(clk),
    .rst(rst),
    
    .init(init),                                                               //init: a waveform generated in FSM which looks like:_____-______
    
    .update_weight_ram(update_weight_ram), // 0: not update; 1: update
    .update_weight_ram_addr(update_weight_ram_addr),
    
    .init_fm_ram_ready(init_fm_ram_ready), // 0: not ready; 1: ready
    .init_weight_ram_ready(init_weight_ram_ready), // 0: not ready; 1: ready
    
    .init_fm_data(init_fm_data),
    .write_fm_data_addr(write_fm_data_addr),
    .init_fm_data_done(init_fm_data_done),
    
    .weight_data(weight_data),
    .write_weight_data_addr(write_weight_data_addr),
    .weight_data_done(weight_data_done) // weight data transmission, 0: not ready; 1: ready
    );
    
    
    
LayerParaScaleFloat16 LPS(
	.clk(clk),
	.rst(rst),

	.layer_type(layer_type), // 0: prepare init feature map and weight data; 1:conv; 2:pool; 3:fc;
	input [1:0] pre_layer_type,

	input [`LAYER_NUM_WIDTH - 1:0] layer_num,

	// data init and data update
	.init_fm_data(init_fm_data),
	.write_fm_data_addr(write_fm_data_addr),
	.init_fm_data_done(init_fm_data_done), // feature map data transmission, 0: not ready; 1: ready

	.weight_data(weight_data),
	.write_weight_data_addr(write_weight_data_addr),
	.weight_data_done(weight_data_done), // weight data transmission, 0: not ready; 1: ready

	// common configuration
	input [`FM_SIZE_WIDTH - 1:0] fm_size,
	input [`KERNEL_SIZE_WIDTH - 1:0] fm_depth,

	input [`FM_SIZE_WIDTH - 1:0] fm_size_out, // include padding
	input [`PADDING_NUM_WIDTH - 1:0] padding_out,

	// conv
	input [`KERNEL_NUM_WIDTH - 1:0] kernel_num, // fm_depth_out
	input [`KERNEL_SIZE_WIDTH - 1:0] kernel_size,

	// pool
	input pool_type, // 0: max pool; 1: avg pool
	input [`POOL_SIZE_WIDTH - 1:0] pool_win_size, 

	// activation
	input [1:0] activation, // 0: none; 1: ReLU. current just none or ReLU

	.update_weight_ram(update_weight_ram), // 0: not update; 1: update
	.update_weight_ram_addr(update_weight_ram_addr),

	.init_fm_ram_ready(init_fm_ram_ready), // 0: not ready; 1: ready
	.init_weight_ram_ready(init_weight_ram_read), // 0: not ready; 1: ready
	output reg layer_ready
    );

    
endmodule
