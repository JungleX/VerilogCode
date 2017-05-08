`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/02 19:54:33
// Design Name: 
// Module Name: max_pool_tb
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

module max_pool_tb();
    reg clock;
    reg reset;
    reg ena;
    reg [`NH_VECTOR_WIDTH - 1:0] sub_in; 
    wire [`POOL_OUT_WIDTH - 1:0] sub_out;

    max_pool dut(
        .clk(clock),
        .ena(ena),
        .reset(reset),
        .in_vector(sub_in),
        .pool_out(sub_out)
    );

    initial 
    begin
        clock = 1'b1;
        repeat (20) clock = #5 ~clock;
    end

    initial 
    begin
    #0
    reset = 1'b0;
    ena = 1'b0;

    #10
    reset = 1'b1;
    ena = 1'b1;
    sub_in = {`NN_WIDTH'b0000000000000000, `NN_WIDTH'b0100101001000000, `NN_WIDTH'b1100101001000000, 
              `NN_WIDTH'b0100100100010000, `NN_WIDTH'b0100100010100000, `NN_WIDTH'b1100100100010000, 
              `NN_WIDTH'b1100100010100000, `NN_WIDTH'b0000000000000000, `NN_WIDTH'b0011110000000000};
    // 0,      12.5, -12.5
    // 10.125, 9.25, -10.125
    // -9.25,  0,    1
    
    #10
    reset = 1'b1;
    sub_in = {`NN_WIDTH'b0000000000000000, `NN_WIDTH'b0100101001000000, `NN_WIDTH'b1100101001000000, 
              `NN_WIDTH'b0100100100010000, `NN_WIDTH'b0100100010100000, `NN_WIDTH'b1100100100010000, 
              `NN_WIDTH'b1100100010100000, `NN_WIDTH'b0100110011100000, `NN_WIDTH'b0011110000000000};
     // 0,      12.5, -12.5
     // 10.125, 9.25, -10.125
     // -9.25,  19.5,    1             
    
    end

endmodule
