`timescale 1ns / 1ps
`include "bit_width.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/04/21 14:01:43
// Design Name: 
// Module Name: fifo_tb
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

`define clk_period 10

module fifo_tb();
    reg clk;

    //weight
    reg w_rst;
    wire w_full;
    reg [`IMG_DATA_MATRIX_WIDTH - 1:0] w_din;
    reg w_wr_en;
    wire w_empty;
    wire [`IMG_DATA_MATRIX_WIDTH - 1:0] w_dout;
    reg w_rd_en;
    
    // bias    
    reg b_rst;
    wire b_full;
    reg [`IMG_DATA_WIDTH - 1:0] b_din;
    reg b_wr_en;
    wire b_empty;
    wire [`IMG_DATA_WIDTH - 1:0] b_dout;
    reg b_rd_en;
    
    integer i;
    reg [`IMG_DATA_WIDTH - 1:0] weight[0:`WEIGHT_SIZE_1 * `WEIGHT_SIZE_1 - 1];// 3*3
    reg [`IMG_DATA_WIDTH - 1:0] bias[0:0];
     
    // weight 
    weight_fifo weight_ram(
        .clk(clk),
        .srst(w_rst),
        .full(w_full),
        .din(w_din),
        .wr_en(w_wr_en),
        .empty(w_empty),
        .dout(w_dout),
        .rd_en(w_rd_en)
    );    
   
    //bias
    bias_fifo bias_ram(
        .clk(clk),
        .srst(b_rst),
        .full(b_full),
        .din(b_din),
        .wr_en(b_wr_en),
        .empty(b_empty),
        .dout(b_dout),
        .rd_en(b_rd_en)
        );
    
    initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
        $readmemb("weight.mem", weight);
//        for(i=0; i<9; i=i+3)
//            $display("%d %d %d", weight[i+0], weight[i+1], weight[i+2]);
    
        $readmemb("bias.mem", bias);
//        for(i=0; i<2; i=i+1)
//            $display("%d", bias);
    
        // reset
        w_rst = 1'b1;
        w_wr_en = 1'b0;
        w_rd_en = 1'b0;
        w_din = 72'b0;
        
        b_rst = 1'b0;
        b_wr_en = 1'b0;
        b_rd_en = 1'b0;
        b_din = 72'b0;        
        
        #`clk_period
        w_rst = 1'b0;
        b_rst = 1'b0;
        
        w_wr_en = 1'b1; // write
        w_din = {weight[0], weight[1], weight[2], weight[3], weight[4], weight[5], weight[6], weight[7], weight[8]};
        b_wr_en = 1'b1; // write
        b_din = bias[0];     
        
        #`clk_period 
        w_wr_en = 1'b0; 
        w_rd_en = 1'b1; // read
        b_wr_en = 1'b0; 
        b_rd_en = 1'b1; // read
    end
  
endmodule
