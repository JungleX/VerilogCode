`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/23 09:25:46
// Design Name: 
// Module Name: pcie_controller_tb
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
module pcie_controller_tb();

    reg clk;
    reg pcieRst;
    
    reg pcieLayerCmd;    // 0: idle; 1:write data to layer RAM, just for the original feature map and 2 kenerl at beginning
    reg [3:0] runLayer;        // which layer to run
    
    reg updateBias;      // add a bais to bias RAM
    reg updateBiasAddr;
    reg updateWeight;    // add a weight to weight RAM
    reg [9:0] updateWeightAddr;
    
    wire updateBiasDone;   // 1:done
    wire updateWeightDone; // 1:done
    
    wire pcieDataReady; // feature map of conv 1
    wire connnectPC;    // todo; ask PC for data
    
    wire layerWriteEn;
    wire [31:0] writeLayerData;// write data to layer data RAM
    wire [17:0] layerDataAddr;  // layer data addreses
    
    wire weightWriteEn;
    wire [1935:0] writeWeightData;  // write data to weight RAM
    wire [9:0] weightDataAddr;
    
    wire biasWriteEn;
    wire [15:0] writeBiasData;  // write data to bias RAM
    wire biasDataAddr;
    wire wea;

    pcie_controller pc(
        .clk(clk),
        .pcieRst(pcieRst),
        
        .pcieLayerCmd(pcieLayerCmd),    // 0: idle; 1:write data to layer RAM, just for the original feature map and 2 kenerl at beginning
        .runLayer(runLayer),        // which layer to run
        
        .updateBias(updateBias),      // add a bais to bias RAM
        .updateBiasAddr(updateBiasAddr),
        .updateWeight(updateWeight),    // add a weight to weight RAM
        .updateWeightAddr(updateWeightAddr),
        
        .updateBiasDone(updateBiasDone),   // 1:done
        .updateWeightDone(updateWeightDone), // 1:done
        
        .pcieDataReady(pcieDataReady), // feature map of conv 1
        .connnectPC(connnectPC),    // todo, ask PC for data
        
        .layerWriteEn(layerWriteEn),
        .writeLayerData(writeLayerData),// write data to layer data RAM
        .layerDataAddr(layerDataAddr),  // layer data addreses
        
        .weightWriteEn(weightWriteEn),
        .writeWeightData(writeWeightData),  // write data to weight RAM
        .weightDataAddr(weightDataAddr),
        
        .biasWriteEn(biasWriteEn),
        .writeBiasData(writeBiasData),  // write data to bias RAM
        .biasDataAddr(biasDataAddr),
        
        .wea(wea)
    );

    parameter IDLE  = 4'd0,
                CONV1 = 4'd1,       
                POOL1 = 4'd2,
                CONV2 = 4'd3,       
                POOL2 = 4'd4,
                CONV3 = 4'd5,      
                CONV4 = 4'd6,  
                CONV5 = 4'd7,
                POOL5 = 4'd8,
                FC6   = 4'd9,
                FC7   = 4'd10,
                FC8   = 4'd11;    

    initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
        #0
        pcieRst = 0;
        
        // IDLE
        #`clk_period
        // 1
        pcieRst = 1;
        runLayer = IDLE;
        pcieLayerCmd = 1;
        
        // CONV1
        #(`clk_period*9)
        // 10
        runLayer = CONV1;
        updateWeight = 1;
        updateWeightAddr = 3;
        updateBias = 1;
        updateBiasAddr = 1;
        
        #(`clk_period*3)
        // 13
        updateBias = 0;

        #(`clk_period*2)
        // 15
        updateWeight = 0;
        updateBias = 0;
        
        #`clk_period
        // 16
        runLayer = CONV1;
        updateWeight = 1;
        updateWeightAddr = 0;
        updateBias = 1;
        updateBiasAddr = 0;        

        #(`clk_period*2)
        // 18
        updateBias = 0;

        #(`clk_period*2)
        // 20
        updateWeight = 0;
        updateBias = 0;
        
//        // CONV2
//        #`clk_period
//        // 21
//        runLayer = CONV2;
//        updateWeight = 1;
//        updateWeightAddr = 3;
//        updateBias = 1;
//        updateBiasAddr = 1;

//        #(`clk_period*3)
//        // 24
//        updateBias = 0;

//        #(`clk_period*2)
//        // 26
//        updateWeight = 0;
//        updateBias = 0;        

//        #`clk_period
//        // 27
//        runLayer = CONV2;
//        updateWeight = 1;
//        updateWeightAddr = 0;
//        updateBias = 1;
//        updateBiasAddr = 0;

//        #(`clk_period*2)
//        // 29
//        updateBias = 0;

//        #(`clk_period*2)
//        // 31
//        updateWeight = 0;
//        updateBias = 0;  
        
//        // CONV3
//        #`clk_period
//        // 32
//        runLayer = CONV3;
//        updateWeight = 1;
//        updateWeightAddr = 3;
//        updateBias = 1;
//        updateBiasAddr = 1;

//        #(`clk_period*3)
//        // 35
//        updateBias = 0;

//        #(`clk_period*2)
//        // 37
//        updateWeight = 0;
//        updateBias = 0; 

//        #`clk_period
//        // 38
//        runLayer = CONV3;
//        updateWeight = 1;
//        updateWeightAddr = 0;
//        updateBias = 1;
//        updateBiasAddr = 0;
        
//        #(`clk_period*2)
//        // 40
//        updateBias = 0;

//        #(`clk_period*2)
//        // 42
//        updateWeight = 0;
//        updateBias = 0; 

//        // CONV4
//        #`clk_period
//        // 43
//        runLayer = CONV4;
//        updateWeight = 1;
//        updateWeightAddr = 3;
//        updateBias = 1;
//        updateBiasAddr = 1;

//        #(`clk_period*3)
//        // 46
//        updateBias = 0;

//        #(`clk_period*2)
//        // 48
//        updateWeight = 0;
//        updateBias = 0; 

//        #`clk_period
//        // 49
//        runLayer = CONV4;
//        updateWeight = 1;
//        updateWeightAddr = 0;
//        updateBias = 1;
//        updateBiasAddr = 0;

//        #(`clk_period*2)
//        // 51
//        updateBias = 0;

//        #(`clk_period*2)
//        // 53
//        updateWeight = 0;
//        updateBias = 0; 

//        // CONV5
//        #`clk_period
//        // 54
//        runLayer = CONV5;
//        updateWeight = 1;
//        updateWeightAddr = 3;
//        updateBias = 1;
//        updateBiasAddr = 1;               
        
//        #(`clk_period*3)
//        // 57
//        updateBias = 0;

//        #(`clk_period*2)
//        // 59
//        updateWeight = 0;
//        updateBias = 0; 

//        #`clk_period
//        // 60
//        runLayer = CONV5;
//        updateWeight = 1;
//        updateWeightAddr = 0;
//        updateBias = 1;
//        updateBiasAddr = 0;       
                         
    end
    
endmodule
