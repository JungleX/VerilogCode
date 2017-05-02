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
    reg [`NH_VECTOR_WIDTH - 1:0] sub_in; 
    wire [`POOL_OUT_WIDTH - 1:0] sub_out;

    max_pool dut(
        .clk(clock),
        .reset(reset),
        .nh_vector(sub_in),
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
    reset = 1'b1;

    #10
    reset = 1'b0;
    sub_in = {8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8};
    
    #10
    reset = 1'b0;
    sub_in = {8'd9, 8'd1, 8'd5, 8'd3, 8'd4, 8'd7, 8'd6, 8'd0, 8'd8};
    
end

endmodule
