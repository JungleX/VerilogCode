`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/04/22 22:51:48
// Design Name: 
// Module Name: memory_controller_tb
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

module memory_controller_tb();
    reg clk;
    reg rst;
    reg ena;
    reg[2:0] readState;
    reg[2:0] loadState;
    reg biasFull;
    reg biasEmpty;
    wire biasRst;
    wire biasWrEn;
    wire biasRdEn;
    
    reg weightFull;
    reg weightEmpty;
    wire weightWrEn;
    wire weightRdEn;
    wire weightRst;
    
    wire layerEna;
    wire layerWea; // 0:read or 1:write
    wire layerRst;
      
    wire loadDone;
    wire[3:0] memoryState;
        
    initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;
    
    memory_controller m(
        .clk(clk),
        .rst(rst),
        .ena(ena),
        
        .readState(readState), // from global controller
        .loadState(loadState), // from PCIe controller
        
        .biasFull(biasFull),
        .biasEmpty(biasEmpty),
        .biasRst(biasRst),
        .biasWrEn(biasWrEn),
        .biasRdEn(biasRdEn),
        
        .weightFull(weightFull),
        .weightEmpty(weightEmpty),
        .weightWrEn(weightWrEn),
        .weightRdEn(weightRdEn),
        .weightRst(weightRst),
        
        .layerEna(layerEna),
        .layerWea(layerWea), // 0:read or 1:write
        .layerRst(layerRst),
        
        .loadDone(loadDone),
        .memoryState(memoryState) // to global controller,{biasFull,biasEmpty,weightFull,weightEmpty}
        );
    
    initial begin
        ena = 1'b1;
 // rst ===========================
        rst = 1'b1;
        
        #`clk_period
         rst = 1'b0;
        
        #`clk_period
        rst = 1'b1;
// readState =======================              
        #`clk_period
        rst = 1'b0;
        readState = 3'b111;

        #`clk_period
        readState = 3'b000;

        #`clk_period
        readState = 3'b100;
        
        #`clk_period
        readState = 3'b010;
        
        #`clk_period
        readState = 3'b001;        
        
        #`clk_period
        readState = 3'b110;
        
        #`clk_period
        readState = 3'b101;
        
        #`clk_period
        readState = 3'b011;         
// loadState =======================       
        #`clk_period
        loadState = 3'b111;

        #`clk_period
        loadState = 3'b000;
    
        #`clk_period
        loadState = 3'b100;

        #`clk_period
        loadState = 3'b010;

        #`clk_period
        loadState = 3'b001;        

        #`clk_period
        loadState = 3'b110;

        #`clk_period
        loadState = 3'b101;

        #`clk_period
        loadState = 3'b011;  
// memoryState =======================           
        #`clk_period
        biasFull = 1'b1;
        biasEmpty = 1'b1;
        weightFull = 1'b1;
        weightEmpty = 1'b1;            
        
        #`clk_period
        biasFull = 1'b0;
        biasEmpty = 1'b1;
        weightFull = 1'b1;
        weightEmpty = 1'b1; 
        
        #`clk_period
        biasFull = 1'b0;
        biasEmpty = 1'b0;
        weightFull = 1'b1;
        weightEmpty = 1'b1;

        #`clk_period
        biasFull = 1'b0;
        biasEmpty = 1'b0;
        weightFull = 1'b0;
        weightEmpty = 1'b1;
        
         #`clk_period
        biasFull = 1'b0;
        biasEmpty = 1'b0;
        weightFull = 1'b0;
        weightEmpty = 1'b0;

    end
endmodule
