`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/24 15:03:39
// Design Name: 
// Module Name: alexnet_tb
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

module alexnet_tb();
    reg clk;
    reg gcEna;
    reg gcRst;

    wire pcieDataReady;
    
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
    

    reg updateBias;
    reg updateBiasAddr;
    reg updateWeight;
    reg [9:0] updateWeightAddr;

    wire updateBiasDone;   // 1:done
    wire updateWeightDone; // 1:done
    
    wire connnectPC;    // todo; ask PC for data
    
    wire layerWriteEn;
    wire [15:0] writeLayerData;// write data to layer data RAM
    wire [18:0] layerDataAddr;  // layer data addreses
    
    wire weightWriteEn;
    wire [1935:0] writeWeightData;  // write data to weight RAM
    wire [9:0] weightDataAddr;
    
    wire biasWriteEn;
    wire [15:0] writeBiasData;  // write data to bias RAM
    wire biasDataAddr;
    wire wea;    
    
    reg [18:0] layerReadAddr;
    reg [9:0] weightReadAddr;
    reg biasReadAddr;
    
    wire [15:0] layerReadData;
    wire [1935:0] weightReadData;
    wire [15:0] biasReadData;
    
    reg layerReadEnTest;
    reg weightReadEnTest;
    reg biasReadEnTest;

    global_controller globalController(
    	// input
        .clk(clk),
        .ena(gcEna),
        .rst(gcRst),
        .pcieDataReady(pcieDataReady),    

        .convStatus(convStatus),    
        .poolStatus(poolStatus),       
        .fcStatus(fcStatus),         
    
    	// output
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

    pcie_controller pcieController(
    	// input
        .clk(clk),
        .pcieRst(pcieRst),
        
        .pcieLayerCmd(pcieLayerCmd),   
        .runLayer(runLayer),        
        
        // output
        .updateBias(updateBias),      
        .updateBiasAddr(updateBiasAddr),
        .updateWeight(updateWeight),    
        .updateWeightAddr(updateWeightAddr),
        
        .updateBiasDone(updateBiasDone),   
        .updateWeightDone(updateWeightDone), 
        
        .pcieDataReady(pcieDataReady), 
        .connnectPC(connnectPC),    
        
        .layerWriteEn(layerWriteEn),
        .writeLayerData(writeLayerData),
        .layerDataAddr(layerDataAddr),  
        
        .weightWriteEn(weightWriteEn),
        .writeWeightData(writeWeightData), 
        .weightDataAddr(weightDataAddr),
        
        .biasWriteEn(biasWriteEn),
        .writeBiasData(writeBiasData),  
        .biasDataAddr(biasDataAddr),
        
        .wea(wea)
    );

    layer_ram layerRam(
        .addra(layerDataAddr),
        .clka(clk),
        .dina(writeLayerData),
        .ena(layerWriteEn),
        .wea(wea),
        
        .addrb(layerReadAddr),
        .clkb(clk),
        .doutb(layerReadData),
        //.enb(layerReadEn)
        .enb(layerReadEnTest) // just for test
    );

    weight_ram weightRam(
        .addra(weightDataAddr),
        .clka(clk),
        .dina(writeWeightData),
        .ena(weightWriteEn),
        .wea(wea),
        
        .addrb(weightReadAddr),
        .clkb(clk),
        .doutb(weightReadData),
        //.enb(weightReadEn)   
        .enb(weightReadEnTest) // just for test
    );
    
    bias_ram biasRam(
        .addra(biasDataAddr),
        .clka(clk),
        .dina(writeBiasData),
        .ena(biasWriteEn),
        .wea(wea),
        
        .addrb(biasReadAddr),
        .clkb(clk),
        .doutb(biasReadData),
        //.enb(biasReadEn)   
        .enb(biasReadEnTest)  // just for test   
    );

    integer reading_size = 0;

    initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;
    
    initial begin
        // 0
        #0  
        gcEna = 0; // disable the controller and do nothing
        gcRst = 0;
        
        // 1
        #`clk_period
        gcEna = 1; // enable the controller
        gcRst = 0; // reset the controller  

        // 3
        #(`clk_period*2)
        gcEna = 1;
        gcRst = 1; // disable the reset 
        // idle
        convStatus = 0; // no conv 
        poolStatus = 0; // no pool
        fcStatus = 0;   // no fc

        // 11
        #(`clk_period*8)
        // read the RAM data

        // layerReadData
        while(reading_size <= 10) begin 
            #`clk_period
            if(reading_size == 0)
            	layerReadAddr = 0;
            else 
            	layerReadAddr = layerReadAddr + 1;
            
            layerReadEnTest = 1;
            reading_size = reading_size + 1;
        end
        #`clk_period
        layerReadEnTest = 0;

        // weightReadData
        reading_size = 0;
        while(reading_size <= 6) begin 
            #`clk_period
            if(reading_size == 0)
            	weightReadAddr = 0;
            else 
            	weightReadAddr = weightReadAddr + 1;
            
            weightReadEnTest = 1;
            reading_size = reading_size + 1;
        end
        #`clk_period
        weightReadEnTest = 0;

        // biasReadData
        reading_size = 0;
        while(reading_size <= 2) begin 
            #`clk_period
            if(reading_size == 0)
            	biasReadAddr = 0;
            else 
            	biasReadAddr = biasReadAddr + 1;
            
            biasReadEnTest = 1;
            reading_size = reading_size + 1;
        end
        #`clk_period
        biasReadEnTest = 0;

    end
endmodule
