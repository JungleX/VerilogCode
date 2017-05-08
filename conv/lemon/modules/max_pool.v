`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/02 19:44:52
// Design Name: 
// Module Name: max_pool
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
`include "cnn_parameters.vh"

module max_pool(
    input clk,
    input reset,
    input [`NH_VECTOR_WIDTH - 1:0] nh_vector,
    output [`POOL_OUT_WIDTH - 1:0] pool_out
    );
                 
    wire [`POOL_OUT_WIDTH - 1:0] adder_tree_wire0;
    wire [`POOL_OUT_WIDTH - 1:0] adder_tree_wire1;
    wire [`POOL_OUT_WIDTH - 1:0] adder_tree_wire2;
    wire [`POOL_OUT_WIDTH - 1:0] adder_tree_wire3;
    
    wire [`POOL_OUT_WIDTH - 1:0] adder_tree_wire4;
    wire [`POOL_OUT_WIDTH - 1:0] adder_tree_wire5;
    
    wire [`POOL_OUT_WIDTH - 1:0] adder_tree_wire6;
    
    assign adder_tree_wire0 = (nh_vector[`NN_WIDTH - 1:0] >= nh_vector[`NN_WIDTH*2-1:`NN_WIDTH])?nh_vector[`NN_WIDTH - 1:0]:nh_vector[`NN_WIDTH*2-1:`NN_WIDTH];
    assign adder_tree_wire1 = (nh_vector[`NN_WIDTH*3 - 1:`NN_WIDTH*2] >= nh_vector[`NN_WIDTH*4 - 1:`NN_WIDTH*3])?nh_vector[`NN_WIDTH*3 - 1:`NN_WIDTH*2]:nh_vector[`NN_WIDTH*4 - 1:`NN_WIDTH*3];
    assign adder_tree_wire2 = (nh_vector[`NN_WIDTH*5 - 1:`NN_WIDTH*4] >= nh_vector[`NN_WIDTH*6 - 1:`NN_WIDTH*5])?nh_vector[`NN_WIDTH*5 - 1:`NN_WIDTH*4]:nh_vector[`NN_WIDTH*6 - 1:`NN_WIDTH*5];
    assign adder_tree_wire3 = (nh_vector[`NN_WIDTH*7 - 1:`NN_WIDTH*6] >= nh_vector[`NN_WIDTH*8 - 1:`NN_WIDTH*7])?nh_vector[`NN_WIDTH*7 - 1:`NN_WIDTH*6]:nh_vector[`NN_WIDTH*8 - 1:`NN_WIDTH*7];
    
    assign adder_tree_wire4 = (adder_tree_wire0 >= adder_tree_wire1)?adder_tree_wire0:adder_tree_wire1;
    assign adder_tree_wire5 = (adder_tree_wire2 >= adder_tree_wire3)?adder_tree_wire2:adder_tree_wire3;
    
    assign adder_tree_wire6 = (adder_tree_wire4 >= adder_tree_wire5)?adder_tree_wire4:adder_tree_wire5;
             
    assign pool_out = (adder_tree_wire6 >= nh_vector[`NN_WIDTH*9-1:`NN_WIDTH*8])?adder_tree_wire6:nh_vector[`NN_WIDTH*9-1:`NN_WIDTH*8];
    
endmodule
