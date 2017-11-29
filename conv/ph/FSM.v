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
    
wire clk;

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
reg [`LAYER_NUM_WIDTH - 1:0] layer_num;
reg [1:0] layer_type; // 0: prepare init feature map and weight data; 1:conv; 2:pool; 3:fc;
reg [1:0] pre_layer_type;

reg init = 1'b0;
reg init_disable = 1'b1;
reg init_cnt = 1'b1;
wire start;

initial
begin
    layer_num = `LAYER_NUM_WIDTH'b0;
	layer_type = 2'b00;
	pre_layer_type = 2'b00;
	init = 1'b0;
	init_disable = 1'b1;
	init_cnt = 1'b1;
end
	
always @(*) assign workstate = transmission_start & (!rst);
always @(posedge clk) begin
    if (rst) begin
    init <= 0;
    init_disable <= 1;
    layer_num <= `LAYER_NUM_WIDTH'b0;
	layer_type <= 2'b00;
    pre_layer_type <= 2'b00;
    end
end                                                             //rst all



always @(posedge clk)
    if (!init_cnt) init_cnt <= 1'b1;
always @(posedge clk) begin
    if ((workstate) && (init_disable)) begin
        init <= 1;
        init_disable <= 0;
        init_cnt <= 0;
    end
end
 
always @(posedge clk) begin
    if ((start) && (init_cnt) && (!init_disable))
        init <= 1'b0;
end

always @(posedge clk) begin
if (workstate) begin
case (layer_num)
3'b000:layer_type <= 2'b00;
3'b001:layer_type <= 2'b01;
3'b010:layer_type <= 2'b10;
3'b011:layer_type <= 2'b11;
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
    
    .init(init),
    .start(start),
    
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
	.fm_size(8),
	.fm_depth(2),

	.fm_size_out(8), // include padding
	.padding_out(1),

	// conv
	.kernel_num(6), // fm_depth_out
	.kernel_size(3),

	// pool
	.pool_type(0), // 0: max pool; 1: avg pool
	.pool_win_size(2), 

	// activation
	.activation(1), // 0: none; 1: ReLU. current just none or ReLU

	.update_weight_ram(update_weight_ram), // 0: not update; 1: update
	.update_weight_ram_addr(update_weight_ram_addr),

	.init_fm_ram_ready(init_fm_ram_ready), // 0: not ready; 1: ready
	.init_weight_ram_ready(init_weight_ram_read), // 0: not ready; 1: ready
	output reg layer_ready
    );

    
endmodule
