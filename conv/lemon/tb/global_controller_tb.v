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
    reg layerDataReady;
    
    reg convStatus;
    reg poolStatus;
    reg fcStatus;

    reg biasFull;
    reg biasEmpty;
    
    reg weightFull;
    reg weightEmpty;
    
    wire[3:0] runLayer;
    wire pcieCmd;
    
    wire biasReadEn;
    wire weightReadEn;
    wire layerReadEn;
    
    wire biasRst;
    wire weightRst;
    wire pcieRst;
    wire convRst;
    wire poolRst;
    wire fcRst;

    global_controller gc(
        .clk(clk),
        .ena(ena),
        .rst(rst),
        .pcieDataReady(pcieDataReady),    // data from pcie(data of conv1) is ready to use
        .layerDataReady(layerDataReady),   // todo, if the all data of AlexNet can store on-chip, use this signal, data of other layers is ready

        .convStatus(convStatus),       // conv status, 0:idle or running; 1:done
        .poolStatus(poolStatus),       // pool status, 0:idle or running; 1:done
        .fcStatus(fcStatus),         // fc status, 0:idle or running; 1:done
     
        .biasFull(biasFull),         // 1:bias RAM is full 
        .biasEmpty(biasEmpty),        // 1:bias RAM is empty
    
        .weightFull(weightFull),       // 1:weight RAM is full
        .weightEmpty(weightEmpty),      // 1:weight RAM is empty
    
        .runLayer(runLayer),// which layer to run
    
        .pcieCmd(pcieCmd),     // control pcie to write data to bias RAM, weight RAM and layer data RAM. 
    
        .biasReadEn(biasReadEn),   // enable bias read
        .weightReadEn(weightReadEn), // enable weight read
        .layerReadEn(layerReadEn),  // enable layer data read
    
        .biasRst(biasRst),      // reset the bias RAN
        .weightRst(weightRst),    // reset the weight RAM
        .pcieRst(pcieRst),      // todo, wait to do more design
        .convRst(convRst),      // todo, reset conv operation
        .poolRst(poolRst),      // reset pool operation
        .fcRst(fcRst)           // reset fc operation
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
        // conv1 finish, new pcie data is writting to on-chip memory 
        pcieDataReady = 0;
        convStatus = 1;
        poolStatus = 0;
        fcStatus = 0;
 
        // 6
        #`clk_period
        // complete loading data, go to pool1
        pcieDataReady = 1;
        convStatus = 1;
        poolStatus = 0;
        fcStatus = 0;

        // 7
        #`clk_period
        // pool1
        pcieDataReady = 1;
        convStatus = 0;
        poolStatus = 0; // running
        fcStatus = 0;   

        // 8
        #`clk_period
        // pool1 finish, load new data
        pcieDataReady = 0;
        convStatus = 0;
        poolStatus = 1;
        fcStatus = 0;
 
        // 9
         #`clk_period
        // complete loading data, go to conv2
        pcieDataReady = 1;
        convStatus = 0;
        poolStatus = 1;
        fcStatus = 0;

        // 10
        #`clk_period
        // conv2
        pcieDataReady = 1;
        convStatus = 0;
        poolStatus = 0;
        fcStatus = 0;
        
        // 11
        #`clk_period
        // conv2 finish, load new data
        pcieDataReady = 0;
        convStatus = 1; 
        poolStatus = 0;
        fcStatus = 0;

        // 12
        #`clk_period
        // complete loading data, go to pool2
        pcieDataReady = 1;
        convStatus = 1; 
        poolStatus = 0;
        fcStatus = 0;   
 
        // 13
        #`clk_period
        // pool2
        pcieDataReady = 1;
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 0;      
              
        // 14                                              
        #`clk_period
        // pool2 finish, load new data
        pcieDataReady = 0;
        convStatus = 0; 
        poolStatus = 1;
        fcStatus = 0;                                                           

        // 15
        #`clk_period
        // complete loading data, go to conv3
        pcieDataReady = 1;
        convStatus = 0;
        poolStatus = 1;
        fcStatus = 0;

        // 16
        #`clk_period
        // conv3
        pcieDataReady = 1;
        convStatus = 0;
        poolStatus = 0;
        fcStatus = 0;
        
        // 17
        #`clk_period
        // conv3 finish, load new data
        pcieDataReady = 0;
        convStatus = 1; 
        poolStatus = 0;
        fcStatus = 0; 
 
        // 18
        #`clk_period
        // complete loading data, go to conv4
        pcieDataReady = 1;
        convStatus = 1;
        poolStatus = 0;
        fcStatus = 0;

        // 19
        #`clk_period
        // conv4
        pcieDataReady = 1;
        convStatus = 0;
        poolStatus = 0;
        fcStatus = 0;
       
        // 20
        #`clk_period
        // conv4 finish, load new data
        pcieDataReady = 0;
        convStatus = 1; 
        poolStatus = 0;
        fcStatus = 0;     
       
        // 21
        #`clk_period
        // complete loading data, go to conv5
        pcieDataReady = 1;
        convStatus = 1;
        poolStatus = 0;
        fcStatus = 0;

        // 22
        #`clk_period
        // conv5
        pcieDataReady = 1;
        convStatus = 0;
        poolStatus = 0;
        fcStatus = 0;
     
        // 23
        #`clk_period
        // conv5 finish, load new data
        pcieDataReady = 0;
        convStatus = 1; 
        poolStatus = 0;
        fcStatus = 0;  
     
        // 24
        #`clk_period
        // complete loading data, go to pool5
        pcieDataReady = 1;
        convStatus = 1; 
        poolStatus = 0;
        fcStatus = 0;   

        // 25
        #`clk_period
        // pool5
        pcieDataReady = 1;
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 0;      
             
        // 26                                            
        #`clk_period
        // pool5 finish, load new data
        pcieDataReady = 0;
        convStatus = 0; 
        poolStatus = 1;
        fcStatus = 0;         

        // 27
        #`clk_period
        // complete loading data, go to fc6
        pcieDataReady = 1;
        convStatus = 0; 
        poolStatus = 1;
        fcStatus = 0;   

        // 28
        #`clk_period
        // fc6
        pcieDataReady = 1;
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 0;      
             
        // 29                                            
        #`clk_period
        // fc6 finish, load new data
        pcieDataReady = 0;
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 1;
     
        // 30
        #`clk_period
        // complete loading data, go to fc7
        pcieDataReady = 1;
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 1;   

        // 31
        #`clk_period
        // fc7
        pcieDataReady = 1;
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 0;      
             
        // 32                                            
        #`clk_period
        // fc7 finish, load new data
        pcieDataReady = 0;
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 1;
 
        // 33
        #`clk_period
        // complete loading data, go to fc8
        pcieDataReady = 1;
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 1;   

        // 34
        #`clk_period
        // fc8
        pcieDataReady = 1;
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 0;      
             
        // 35                                            
        #`clk_period
        // fc8 finish, load new data
        pcieDataReady = 0;
        convStatus = 0; 
        poolStatus = 0;
        fcStatus = 1;       
     
        // 36
        #`clk_period
        ena = 1; // enable the controller
        rst = 0; // reset the controller   
                    
    end    
    
endmodule
