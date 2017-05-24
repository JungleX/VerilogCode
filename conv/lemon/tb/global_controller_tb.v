`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/15 21:47:22
// Design Name:  
// Module Name: global_controller_tb
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

module global_controller_tb();
    reg clk;
    reg ena;
    reg rst;
    
    reg pcieDataReady;
    
    reg convStatus;
    reg poolStatus;
    reg fcStatus;
    
    wire[3:0] runLayer;
    wire pcieLayerCmd;
    
    wire biasReadEn;
    wire weightReadEn;
    wire layerReadEn;

    wire pcieRst;
    wire convRst;
    wire poolRst;
    wire fcRst;

    global_controller gc(
        .clk(clk),
        .ena(ena),
        .rst(rst),
        .pcieDataReady(pcieDataReady),   

        .convStatus(convStatus),       
        .poolStatus(poolStatus),       
        .fcStatus(fcStatus),             
        
        .runLayer(runLayer),
    
        .pcieLayerCmd(pcieLayerCmd), 
    
        .biasReadEn(biasReadEn),   
        .weightReadEn(weightReadEn),
        .layerReadEn(layerReadEn),

        .pcieRst(pcieRst),     
        .convRst(convRst),      
        .poolRst(poolRst),      
        .fcRst(fcRst)           
    );

    initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;
    
    initial begin
        // 0
        #0  
        ena = 0; // disable the controller and do nothing
        rst = 0;

        // 1
        #`clk_period
        ena = 1; // enable the controller
        rst = 0; // reset the controller       
        
        // 2
        #`clk_period
        ena = 1;
        rst = 1; // disable the reset
        // idle
        pcieDataReady = 0; // pcie data is writting to on-chip memory
        convStatus = 0; // no conv 
        poolStatus = 0; // no pool
        fcStatus = 0;   // no fc
        
        // 3
        #`clk_period
        // complete loading data, go to conv1
        pcieDataReady = 1;
        convStatus = 0;
        poolStatus = 0;
        fcStatus = 0;

        // 4
        #`clk_period
        // conv1
        pcieDataReady = 1;
        convStatus = 0; // running
        poolStatus = 0;
        fcStatus = 0;
        
        // 5
        #`clk_period
        // conv1 finish, go to pool1;
        convStatus = 1;
        poolStatus = 0;
        fcStatus = 0;

        // 6
        #`clk_period
        // pool1
        convStatus = 0;
        poolStatus = 0; // running
        fcStatus = 0;   

        // 7
        #`clk_period
        // pool1 finish, go to conv2
        convStatus = 0;
        poolStatus = 1;
        fcStatus = 0;

        // 8
        #`clk_period
        // conv2
        convStatus = 0; // running
        poolStatus = 0;
        fcStatus = 0;
        
        // 9
        #`clk_period
        // conv2 finish, go to pool2
        convStatus = 1; 
        poolStatus = 0;
        fcStatus = 0;   
 
        // 10
        #`clk_period
        // pool2
        convStatus = 0; 
        poolStatus = 0; // running
        fcStatus = 0;      
              
        // 11                                              
        #`clk_period
        // pool2 finish, go to conv3
        convStatus = 0;
        poolStatus = 1;
        fcStatus = 0;

        // 12
        #`clk_period
        // conv3;
        convStatus = 0; // running
        poolStatus = 0;
        fcStatus = 0;
        
        // 13
        #`clk_period
        // conv3 finish, go to conv4
        convStatus = 1;
        poolStatus = 0;
        fcStatus = 0;

        // 14
        #`clk_period
        // conv4
        convStatus = 0; // running
        poolStatus = 0;
        fcStatus = 0;
       
        // 15
        #`clk_period
        // conv4 finish,go to conv5
        convStatus = 1;
        poolStatus = 0;
        fcStatus = 0;

        // 16
        #`clk_period
        // conv5
        convStatus = 0; // running
        poolStatus = 0;
        fcStatus = 0;
     
        // 17
        #`clk_period
        // conv5 finish, go to pool5
        convStatus = 1; 
        poolStatus = 0;
        fcStatus = 0;   

        // 18
        #`clk_period
        // pool5
        convStatus = 0; 
        poolStatus = 0; // running
        fcStatus = 0;      
             
        // 19                                          
        #`clk_period
        // pool5 finish, go to fc6
        convStatus = 0; 
        poolStatus = 1;
        fcStatus = 0;   

        // 20
        #`clk_period
        // fc6
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 0; // running     
             
        // 21                                         
        #`clk_period
        // fc6 finish, go to fc7
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 1;   

        // 22
        #`clk_period
        // fc7
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 0; // running     
             
        // 23                                           
        #`clk_period
        // fc7 finish, go to fc8
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 1;   

        // 24
        #`clk_period
        // fc8
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 0; // running     
             
        // 25                                            
        #`clk_period
        // fc8 finish, go to idle
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 1;       
     
        // 26
        #`clk_period
        fcStatus = 0; 
        ena = 1; // enable the controller
        rst = 0; // reset the controller   
                    
    end    
    
endmodule
