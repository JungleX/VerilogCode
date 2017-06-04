`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/21 18:59:25
// Design Name: 
// Module Name: pcie_controller
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

`include "alexnet_parameters.vh"

module pcie_controller(
    input clk,
    input pcieRst,
    
    input pcieLayerCmd,                  // 0: idle; 1:write data to layer RAM, just for the original feature map and 2 kenerl at beginning
    input [3:0] runLayer,                // which layer to run  
    
    input updateBias,                    // add a bais to bias RAM
    input updateBiasAddr,
    input updateWeight,                  // add a weight to weight RAM
    input [9:0] updateWeightAddr,
    
    output reg updateBiasDone,           // 1:done
    output reg updateWeightDone,         // 1:done
    
    output reg pcieDataReady,            // feature map of conv 1
    output reg connnectPC,               // todo, ask PC for data
    
    output reg layerWriteEn,
    output reg [15:0] writeLayerData,    // write data to layer data RAM
    output reg [18:0] writeLayerAddr,     // layer data addreses
    
    output reg weightWriteEn,
    output reg [1935:0] writeWeightData, // write data to weight RAM
    output reg [9:0] weightDataAddr,
    
    output reg biasWriteEn,
    output reg [15:0] writeBiasData,     // write data to bias RAM
    output reg biasDataAddr,
    
    output reg wea                       // ram a port, 1:for write
    );
    
    parameter   IDLE  = 4'd0,
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
    
    reg [3:0] currentLayer;
    
    reg [15:0] pcie_data[0:`CONV1_FM_DATA_SIZE - 1];   // get layer data from file, max value conv1
    reg [15:0] weight_data[0:`CONV1_KERNEL_SIZE - 1];  // get weight data from file, max value conv1
    reg [15:0] bias_data[0:`CONV4_KERNEL_SIZE - 1]; // get bias from file, max value conv4
    
    reg [17:0] fm_count;            // 18 bits, max value 262144 > 227*227*3=154587, count the feature map data
    reg [8:0] weight_depth_count;   // 9  bits, amx value 512 > 384 > 256 > 96 > 3*2=6
    reg [8:0] weight_count;         // 9  bits, amx value 512 > 384 > 256 > 96
    reg bias_write_count;
    reg [8:0] bias_count;           // 9  bits, amx value 512 > 384 > 256 > 96

    reg pcDataReady;                // 1:ready; todo set it according to connectPC
    
    reg [9:0] i;                    // 10 bits, max value 1024

    always @(posedge clk or posedge pcieRst) begin
        if(!pcieRst) begin // reset
            pcieDataReady = 0;
            
            fm_count = 0;
            weight_depth_count = 0;
            bias_count = 0;
            bias_write_count = 0;
            weight_count = 0;
            
            pcDataReady = 0;
            writeLayerAddr = 0; 
            weightDataAddr = 0;
            biasDataAddr = 0;
            
            layerWriteEn = 0;
            weightWriteEn = 0;
            biasWriteEn = 0;
            
            currentLayer = IDLE;
            
            wea = 1;
        end
    end
    
    always @(posedge clk) begin
        if(pcieRst) begin
            wea = 1;
            case(runLayer)
                IDLE: 
                    begin
                        if(currentLayer != runLayer) begin
                            weight_depth_count = 0; 
                            bias_write_count = 0;
                            currentLayer = runLayer;       
                        end
                        else begin
                            if(pcDataReady == 0) begin // get data from PC
                                // just for test, use connectPC later
                                $readmemb("data.mem", pcie_data); 
                                $readmemb("weight.mem", weight_data); 
                                $readmemb("bias.mem", bias_data); 
                                pcDataReady = 1;
                            end
                            else if(pcieLayerCmd == 1) begin // write data to layer data RMA
                                if(fm_count >= `CONV1_FM_DATA_SIZE && weight_depth_count >= (`CONV1_FM_DEPTH * 2) && bias_count >= 2) begin // load data done
                                //if(fm_count >= 10 && weight_depth_count >= 6 && bias_count >= 2) begin // just for test
                                    pcieDataReady = 1;
                                    
                                    layerWriteEn = 0;
                                    weightWriteEn = 0;
                                    biasWriteEn = 0;
                                end
                                else begin
                                    // load layer data, load the whole feature map to layer data RAM
                                    if(fm_count < `CONV1_FM_DATA_SIZE) begin 
                                        layerWriteEn = 1;
                                        if(fm_count == 0)
                                            writeLayerAddr = 0;
                                        else
                                            writeLayerAddr = writeLayerAddr + 1;
                                            
                                        writeLayerData = pcie_data[fm_count];

                                        fm_count = fm_count + 1;
                                    end
                                    else begin
                                        layerWriteEn = 0;
                                    end
                                    
                                    // load weight data
                                    if(weight_depth_count < (`CONV1_FM_DEPTH * 2) ) begin
                                        weightWriteEn = 1;
                                        
                                        if(weight_depth_count == 0)
                                            weightDataAddr = 0;
                                        else
                                            weightDataAddr = weightDataAddr + 1;
                                            
                                        i = weight_depth_count * `CONV1_KERNERL_MATRIX;
                                        writeWeightData = { weight_data[i+120], weight_data[i+119], weight_data[i+118], weight_data[i+117], weight_data[i+116], weight_data[i+115], weight_data[i+114],weight_data[i+113], weight_data[i+112], weight_data[i+111], weight_data[i+110],
                                                            weight_data[i+109], weight_data[i+108], weight_data[i+107], weight_data[i+106], weight_data[i+105], weight_data[i+104], weight_data[i+103],weight_data[i+102], weight_data[i+101], weight_data[i+100], weight_data[i+99],
                                                            weight_data[i+98], weight_data[i+97], weight_data[i+96], weight_data[i+95], weight_data[i+94], weight_data[i+93], weight_data[i+92],weight_data[i+91], weight_data[i+90], weight_data[i+89], weight_data[i+88],
                                                            weight_data[i+87], weight_data[i+86], weight_data[i+85], weight_data[i+84], weight_data[i+83], weight_data[i+82], weight_data[i+81],weight_data[i+80], weight_data[i+79], weight_data[i+78], weight_data[i+77],
                                                            weight_data[i+76], weight_data[i+75], weight_data[i+74], weight_data[i+73], weight_data[i+72], weight_data[i+71], weight_data[i+70],weight_data[i+69], weight_data[i+68], weight_data[i+67], weight_data[i+66],
                                                            weight_data[i+65], weight_data[i+64], weight_data[i+63], weight_data[i+62], weight_data[i+61], weight_data[i+60], weight_data[i+59],weight_data[i+58], weight_data[i+57], weight_data[i+56], weight_data[i+55],
                                                            weight_data[i+54], weight_data[i+53], weight_data[i+52], weight_data[i+51], weight_data[i+50], weight_data[i+49], weight_data[i+48],weight_data[i+47], weight_data[i+46], weight_data[i+45], weight_data[i+44],
                                                            weight_data[i+43], weight_data[i+42], weight_data[i+41], weight_data[i+40], weight_data[i+39], weight_data[i+38], weight_data[i+37],weight_data[i+36], weight_data[i+35], weight_data[i+34], weight_data[i+33],
                                                            weight_data[i+32], weight_data[i+31], weight_data[i+30], weight_data[i+29], weight_data[i+28], weight_data[i+27], weight_data[i+26],weight_data[i+25], weight_data[i+24], weight_data[i+23], weight_data[i+22],
                                                            weight_data[i+21], weight_data[i+20], weight_data[i+19], weight_data[i+18], weight_data[i+17], weight_data[i+16], weight_data[i+15],weight_data[i+14], weight_data[i+13], weight_data[i+12], weight_data[i+11],
                                                            weight_data[i+10], weight_data[i+9], weight_data[i+8], weight_data[i+7], weight_data[i+6], weight_data[i+5], weight_data[i+4],weight_data[i+3], weight_data[i+2], weight_data[i+1], weight_data[i]}; 
                                        
                                        weight_depth_count = weight_depth_count + 1;
                                        
                                        if(weight_depth_count % `CONV1_FM_DEPTH == 0)
                                            weight_count = weight_count + 1;    
                                    end
                                    else begin
                                        weightWriteEn = 0;
                                    end

                                    // load bias data
                                    if(bias_count < 2) begin
                                        biasWriteEn = 1;
                                        
                                        if(bias_count == 0)
                                            biasDataAddr = 0;
                                        else 
                                            biasDataAddr = biasDataAddr + 1;
                                            
                                        writeBiasData = bias_data[bias_count];
                                        bias_count = bias_count + 1;
                                    end
                                    else begin
                                        biasWriteEn = 0;
                                    end

                                end
                            end
                        end
                    end
                CONV1:
                    begin
                        if(currentLayer != runLayer) begin
                            weight_depth_count = 0; 
                            bias_write_count = 0;
                            currentLayer = runLayer;  

                            updateWeightDone = 0;   
                            updateBiasDone = 0;
                            
                            weightWriteEn = 0;
                            biasWriteEn = 0;
                        end
                        else begin
                            if(updateWeight == 1 && weight_count < `CONV1_KERNERL_NUMBER) begin
                                if(weight_depth_count < `CONV1_FM_DEPTH ) begin
                                    updateWeightDone = 0;
                                    weightWriteEn = 1;
                                    
                                    i = weight_count * `CONV1_KERNERL_MATRIX * `CONV1_FM_DEPTH + weight_depth_count * `CONV1_KERNERL_MATRIX; // the start index of current weight
                                    writeWeightData = { weight_data[i+120], weight_data[i+119], weight_data[i+118], weight_data[i+117], weight_data[i+116], weight_data[i+115], weight_data[i+114],weight_data[i+113], weight_data[i+112], weight_data[i+111], weight_data[i+110],
                                                        weight_data[i+109], weight_data[i+108], weight_data[i+107], weight_data[i+106], weight_data[i+105], weight_data[i+104], weight_data[i+103],weight_data[i+102], weight_data[i+101], weight_data[i+100], weight_data[i+99],
                                                        weight_data[i+98], weight_data[i+97], weight_data[i+96], weight_data[i+95], weight_data[i+94], weight_data[i+93], weight_data[i+92],weight_data[i+91], weight_data[i+90], weight_data[i+89], weight_data[i+88],
                                                        weight_data[i+87], weight_data[i+86], weight_data[i+85], weight_data[i+84], weight_data[i+83], weight_data[i+82], weight_data[i+81],weight_data[i+80], weight_data[i+79], weight_data[i+78], weight_data[i+77],
                                                        weight_data[i+76], weight_data[i+75], weight_data[i+74], weight_data[i+73], weight_data[i+72], weight_data[i+71], weight_data[i+70],weight_data[i+69], weight_data[i+68], weight_data[i+67], weight_data[i+66],
                                                        weight_data[i+65], weight_data[i+64], weight_data[i+63], weight_data[i+62], weight_data[i+61], weight_data[i+60], weight_data[i+59],weight_data[i+58], weight_data[i+57], weight_data[i+56], weight_data[i+55],
                                                        weight_data[i+54], weight_data[i+53], weight_data[i+52], weight_data[i+51], weight_data[i+50], weight_data[i+49], weight_data[i+48],weight_data[i+47], weight_data[i+46], weight_data[i+45], weight_data[i+44],
                                                        weight_data[i+43], weight_data[i+42], weight_data[i+41], weight_data[i+40], weight_data[i+39], weight_data[i+38], weight_data[i+37],weight_data[i+36], weight_data[i+35], weight_data[i+34], weight_data[i+33],
                                                        weight_data[i+32], weight_data[i+31], weight_data[i+30], weight_data[i+29], weight_data[i+28], weight_data[i+27], weight_data[i+26],weight_data[i+25], weight_data[i+24], weight_data[i+23], weight_data[i+22],
                                                        weight_data[i+21], weight_data[i+20], weight_data[i+19], weight_data[i+18], weight_data[i+17], weight_data[i+16], weight_data[i+15],weight_data[i+14], weight_data[i+13], weight_data[i+12], weight_data[i+11],
                                                        weight_data[i+10], weight_data[i+9], weight_data[i+8], weight_data[i+7], weight_data[i+6], weight_data[i+5], weight_data[i+4],weight_data[i+3], weight_data[i+2], weight_data[i+1], weight_data[i]}; 
                                 
                                    weightDataAddr = updateWeightAddr + weight_depth_count * 1;                                           
                                    weight_depth_count = weight_depth_count + 1;                                
                                end
                                else begin
                                    updateWeightDone = 1;
                                    weightWriteEn = 0;

                                    weight_depth_count = 0;
                                    weight_count = weight_count + 1;
                                end
                            end
                        
                            if(updateBias == 1 && bias_count < `CONV1_KERNERL_NUMBER) begin
                                if(bias_write_count < 1) begin
                                    updateBiasDone = 0;
                                    biasWriteEn = 1;

                                    writeBiasData = bias_data[bias_count];
                                    biasDataAddr = updateBiasAddr;
                                    bias_write_count = 1;
                                end
                                else begin
                                    updateBiasDone = 1;
                                    biasWriteEn = 0;

                                    bias_write_count = 0;
                                    bias_count = bias_count + 1;
                                end
                            end 
                        end 
                    end                 
                POOL1:
                    begin
                        currentLayer = runLayer;
                    end   
                CONV2:
                    begin
                        if(currentLayer != runLayer) begin
                            weight_depth_count = 0;
                            bias_write_count = 0;
                            bias_count = 0;
                            weight_count = 0;
                            currentLayer = runLayer;

                            updateWeightDone = 0;   
                            updateBiasDone = 0;
                            
                            weightWriteEn = 0;
                            biasWriteEn = 0;

                            $readmemb("conv2_weight.mem", weight_data); 
                            $readmemb("conv2_bias.mem", bias_data);                 
                        end   
                        else begin
                            if(updateWeight == 1 && weight_count < `CONV2_KERNERL_NUMBER) begin
                                if(weight_depth_count < `CONV2_FM_DEPTH) begin
                                    updateWeightDone = 0; 
                                    weightWriteEn = 1;

                                    i = weight_count * `CONV2_KERNERL_MATRIX * `CONV2_FM_DEPTH + weight_depth_count * `CONV2_KERNERL_MATRIX; // the start index of current weight
                                    writeWeightData = { weight_data[i+24], weight_data[i+23], weight_data[i+22], weight_data[i+21], weight_data[i+20], 
                                                        weight_data[i+19], weight_data[i+18], weight_data[i+17], weight_data[i+16], weight_data[i+15],
                                                        weight_data[i+14], weight_data[i+13], weight_data[i+12], weight_data[i+11], weight_data[i+10], 
                                                        weight_data[i+9],  weight_data[i+8],  weight_data[i+7],  weight_data[i+6],  weight_data[i+5], 
                                                        weight_data[i+4],  weight_data[i+3],  weight_data[i+2],  weight_data[i+1],  weight_data[i]}; 
                                 
                                    weightDataAddr = updateWeightAddr + weight_depth_count * 1;                                           
                                    weight_depth_count = weight_depth_count + 1;                                
                                end
                                else begin
                                    updateWeightDone = 1;
                                    weightWriteEn = 0;

                                    weight_depth_count = 0;
                                    weight_count = weight_count + 1;
                                end
                            end
                        
                            if(updateBias == 1 && bias_count < `CONV2_KERNERL_NUMBER) begin
                                if(bias_write_count < 1) begin
                                    updateBiasDone =  0;
                                    biasWriteEn = 1;

                                    writeBiasData = bias_data[bias_count];
                                    biasDataAddr = updateBiasAddr;
                                    bias_write_count = 1;
                                end
                                else begin
                                    updateBiasDone = 1;
                                    biasWriteEn = 0;

                                    bias_write_count = 0;
                                    bias_count = bias_count + 1;
                                end
                            end 
                        end               
                    end 
                POOL2:
                    begin
                        currentLayer = runLayer;
                    end 
                CONV3:
                    begin
                        if(currentLayer != runLayer) begin
                            weight_depth_count = 0;
                            bias_write_count = 0;
                            bias_count = 0;
                            weight_count = 0;
                            currentLayer = runLayer;

                            updateWeightDone = 0;   
                            updateBiasDone = 0;

                            weightWriteEn = 0;
                            biasWriteEn = 0;

                            $readmemb("conv3_weight.mem", weight_data); 
                            $readmemb("conv3_bias.mem", bias_data);                  
                        end 
                        else begin
                           if(updateWeight == 1 && weight_count < `CONV3_KERNERL_NUMBER) begin
                                if(weight_depth_count < `CONV3_FM_DEPTH) begin
                                    updateWeightDone = 0; 
                                    weightWriteEn = 1;

                                    i = weight_count * `CONV3_KERNERL_MATRIX * `CONV3_FM_DEPTH + weight_depth_count * `CONV3_KERNERL_MATRIX; // the start index of current weight
                                    writeWeightData = { weight_data[i+8], weight_data[i+7], weight_data[i+6],  
                                                        weight_data[i+5], weight_data[i+4], weight_data[i+3],  
                                                        weight_data[i+2], weight_data[i+1], weight_data[i]}; 
                                 
                                    weightDataAddr = updateWeightAddr + weight_depth_count * 1;                                           
                                    weight_depth_count = weight_depth_count + 1;                                
                                end
                                else begin
                                    updateWeightDone = 1;
                                    weightWriteEn = 0;

                                    weight_depth_count = 0;
                                    weight_count = weight_count + 1;
                                end
                            end
                        
                            if(updateBias == 1 && bias_count < `CONV3_KERNERL_NUMBER) begin
                                if(bias_write_count < 1) begin
                                    updateBiasDone =  0;
                                    biasWriteEn = 1;

                                    writeBiasData = bias_data[bias_count];
                                    biasDataAddr = updateBiasAddr;
                                    bias_write_count = 1;
                                end
                                else begin
                                    updateBiasDone = 1;
                                    biasWriteEn = 0;

                                    bias_write_count = 0;
                                    bias_count = bias_count + 1;
                                end
                            end   
                        end                
                    end 
                CONV4:
                    begin
                        if(currentLayer != runLayer) begin
                            weight_depth_count = 0;
                            bias_write_count = 0;
                            bias_count = 0;
                            weight_count = 0;
                            currentLayer = runLayer; 

                            updateWeightDone = 0;   
                            updateBiasDone = 0;

                            weightWriteEn = 0;
                            biasWriteEn = 0;  
 
                            $readmemb("conv4_weight.mem", weight_data); 
                            $readmemb("conv4_bias.mem", bias_data);               
                        end 
                        else begin
                            if(updateWeight == 1 && weight_count < `CONV4_KERNERL_NUMBER) begin
                                if(weight_depth_count < `CONV4_FM_DEPTH) begin
                                    updateWeightDone = 0; 
                                    weightWriteEn = 1;

                                    i = weight_count * `CONV4_KERNERL_MATRIX * `CONV4_FM_DEPTH + weight_depth_count * `CONV4_KERNERL_MATRIX; // the start index of current weight
                                    writeWeightData = { weight_data[i+8], weight_data[i+7], weight_data[i+6],  
                                                        weight_data[i+5], weight_data[i+4], weight_data[i+3],  
                                                        weight_data[i+2], weight_data[i+1], weight_data[i]}; 
                                 
                                    weightDataAddr = updateWeightAddr + weight_depth_count * 1;                                           
                                    weight_depth_count = weight_depth_count + 1;                                
                                end
                                else begin
                                    updateWeightDone = 1;
                                    weightWriteEn = 0;

                                    weight_depth_count = 0;
                                    weight_count = weight_count + 1;
                                end
                            end
                        
                            if(updateBias == 1 && bias_count < `CONV4_KERNERL_NUMBER) begin
                                if(bias_write_count < 1) begin
                                    updateBiasDone = 0;
                                    biasWriteEn = 1;

                                    writeBiasData = bias_data[bias_count];
                                    biasDataAddr = updateBiasAddr;
                                    bias_write_count = 1;
                                end
                                else begin
                                    updateBiasDone = 1;
                                    biasWriteEn = 0;

                                    bias_write_count = 0;
                                    bias_count = bias_count + 1;
                                end
                            end
                        end                
                    end 
                CONV5:
                    begin
                        if(currentLayer != runLayer) begin
                            weight_depth_count = 0;
                            bias_write_count = 0;
                            bias_count = 0;
                            weight_count = 0;
                            currentLayer = runLayer;  

                            updateWeightDone = 0;   
                            updateBiasDone = 0;
                             
                            weightWriteEn = 0;
                            biasWriteEn = 0;

                            $readmemb("conv5_weight.mem", weight_data); 
                            $readmemb("conv5_bias.mem", bias_data);                
                        end 
                        else begin
                            if(updateWeight == 1 && weight_count < `CONV5_KERNERL_NUMBER) begin
                                if(weight_depth_count < `CONV5_FM_DEPTH) begin
                                    updateWeightDone = 0;
                                    weightWriteEn = 1;

                                    i = weight_count * `CONV5_KERNERL_MATRIX * `CONV5_FM_DEPTH + weight_depth_count * `CONV5_KERNERL_MATRIX; // the start index of current weight
                                    writeWeightData = { weight_data[i+8], weight_data[i+7], weight_data[i+6],  
                                                        weight_data[i+5], weight_data[i+4], weight_data[i+3],  
                                                        weight_data[i+2], weight_data[i+1], weight_data[i]}; 
                                 
                                    weightDataAddr = updateWeightAddr + weight_depth_count * 1;                                           
                                    weight_depth_count = weight_depth_count + 1;                                
                                end
                                else begin
                                    updateWeightDone = 1;
                                    weightWriteEn = 0;

                                    weight_depth_count = 0;
                                    weight_count = weight_count + 1;
                                end
                            end
                        
                            if(updateBias == 1 && bias_count < `CONV5_KERNERL_NUMBER) begin
                                if(bias_write_count < 1) begin
                                    updateBiasDone = 0;
                                    biasWriteEn = 1;

                                    writeBiasData = bias_data[bias_count];
                                    biasDataAddr = updateBiasAddr;
                                    bias_write_count = 1;
                                end
                                else begin
                                    updateBiasDone = 1;
                                    biasWriteEn = 0;

                                    bias_write_count = 0;
                                    bias_count = bias_count + 1;
                                end
                            end 
                        end
                    end 
                POOL5:
                    begin
                        currentLayer = runLayer;
                    end 
                FC6:
                    begin
                    end 
                FC7:
                    begin
                    end 
                FC8:
                    begin
                    end     
            endcase
        end
    end
endmodule
