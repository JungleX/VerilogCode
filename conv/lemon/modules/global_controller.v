`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/15 15:43:07
// Design Name: 
// Module Name: global_controller
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


module global_controller(
    input clk,
    input ena,
    input rst,
    input pcieDataReady,    // data from pcie(data of conv1) is ready to use. 1:ready; 0:idle or writing 
    input layerDataReady,   // todo, if the all data of AlexNet can store on-chip, use this signal, data of other layers is ready

    input convStatus,       // conv status, 0:idle or running; 1:done
    input poolStatus,       // pool status, 0:idle or running; 1:done
    input fcStatus,         // fc status, 0:idle or running; 1:done
     
    input biasFull,         // todo, 1:bias RAM is full 
    input biasEmpty,        // todo, 1:bias RAM is empty
    
    input weightFull,       // todo, 1:weight RAM is full
    input weightEmpty,      // todo, 1:weight RAM is empty
    
    output reg[3:0] runLayer,// which layer to run
    
    output reg pcieCmd,     // control pcie to write data to bias RAM, weight RAM and layer data RAM. 
    
    output reg biasReadEn,   // enable bias read
    output reg weightReadEn, // enable weight read
    output reg layerReadEn,  // enable layer data read
    
    output reg biasRst,      // reset the bias RAM
    output reg weightRst,    // reset the weight RAM
    output reg pcieRst,      // todo, wait to do more design
    output reg convRst,      // reset conv operation
    output reg poolRst,      // reset pool operation
    output reg fcRst         // reset fc operation
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
 
    // reset the whole CNN
    always @(posedge clk or posedge rst) begin
        if(ena) begin
            if(!rst) begin
                runLayer = IDLE;   // idle, no layer to run
                pcieCmd = 0;  // disable pcie operation
                    
                biasReadEn = 0;
                weightReadEn = 0;    
                layerReadEn = 0;
                           
                biasRst = 1;     // FIFO reset signal, 1 to reset
                weightRst = 1;
                pcieRst = 0;
                convRst = 0;
                poolRst = 0;
                fcRst = 0;
                
            end
            else begin
                biasRst = 0;     // FIFO reset signal, 0 to not reset
                weightRst = 0;
                pcieRst = 1;
                convRst = 1;
                poolRst = 1;
                fcRst = 1;
            end
        end
    end
    
    always @(posedge clk) begin
        if(ena && rst) begin
            case(runLayer)
                IDLE:
                    begin
                        if(pcieDataReady == 0) begin // if pcie date is not ready, status: idle
                            pcieCmd = 1;
                            runLayer = IDLE;
                            biasReadEn = 0;
                            weightReadEn = 0;    
                            layerReadEn = 0;
                        end
                        if(pcieDataReady == 1) begin // if pcie date is ready, start to conv1
                            pcieCmd = 0;
                            convRst = 0;
                            runLayer = CONV1;
                            biasReadEn = 1;
                            weightReadEn = 1;    
                            layerReadEn = 1;
                        end    
                    end
                CONV1:
                    begin
                        if(convStatus == 1) begin // current conv is done, load data for next layer
                            pcieCmd = 1; // write to on-chip memory
                            biasReadEn = 0;
                            weightReadEn = 0;    
                            layerReadEn = 0;
                            if(pcieDataReady == 1) begin // complete the load
                                pcieCmd = 0;
                                poolRst = 0;
                                runLayer = POOL1;
                                biasReadEn = 0;
                                weightReadEn = 0;    
                                layerReadEn = 1;
                            end
                        end
                        else begin
                            convRst = 1;
                            runLayer = CONV1;
                            biasReadEn = 1;
                            weightReadEn = 1;
                            layerReadEn = 1;
                        end
                    end     
                POOL1:
                    begin
                        if(poolStatus == 1) begin // pool finish, load new data
                            pcieCmd = 1;
                            biasReadEn = 0;
                            weightReadEn = 0;    
                            layerReadEn = 0;
                            if(pcieDataReady == 1) begin // new data is ready, go to conv2
                                pcieCmd = 0;
                                convRst = 0;
                                runLayer = CONV2;
                                biasReadEn = 1;
                                weightReadEn = 1;    
                                layerReadEn = 1;
                            end
                        end
                        else begin
                            poolRst = 1;
                            runLayer = POOL1;
                            biasReadEn = 0;
                            weightReadEn = 0;
                            layerReadEn = 1;
                        end                        
                    end
                CONV2:
                    begin
                        if(convStatus == 1) begin
                            pcieCmd = 1;
                            biasReadEn = 0;
                            weightReadEn = 0;    
                            layerReadEn = 0;
                            if(pcieDataReady == 1) begin
                                pcieCmd = 0;
                                poolRst = 0;
                                runLayer = POOL2;
                                biasReadEn = 0;
                                weightReadEn = 0;
                                layerReadEn = 1;
                            end
                        end
                        else begin
                            convRst = 1;
                            runLayer = CONV2;
                            biasReadEn = 1;
                            weightReadEn = 1;
                            layerReadEn = 1;
                        end                        
                    end   
                POOL2:
                    begin
                        if(poolStatus == 1) begin
                            pcieCmd = 1;
                            biasReadEn = 0;
                            weightReadEn = 0;    
                            layerReadEn = 0;
                            if(pcieDataReady == 1) begin
                                pcieCmd = 0;
                                convRst = 0;
                                runLayer = CONV3;
                                biasReadEn = 1;
                                weightReadEn = 1;
                                layerReadEn = 1;
                            end
                        end
                        else begin
                            poolRst = 1;
                            runLayer = POOL2;
                            biasReadEn = 0;
                            weightReadEn = 0;
                            layerReadEn = 1;
                        end    
                    end
                CONV3:
                    begin
                        if(convStatus == 1) begin
                            pcieCmd = 1;
                            biasReadEn = 0;
                            weightReadEn = 0;    
                            layerReadEn = 0;
                            if(pcieDataReady == 1) begin
                                pcieCmd = 0;
                                convRst = 0;
                                runLayer = CONV4;
                                biasReadEn = 1;
                                weightReadEn = 1;
                                layerReadEn = 1;
                            end
                        end
                        else begin
                            convRst = 1;
                            runLayer = CONV3;
                            biasReadEn = 1;
                            weightReadEn = 1;
                            layerReadEn = 1;
                        end                     
                    end  
                CONV4:
                    begin
                        if(convStatus == 1) begin
                            pcieCmd = 1;
                            biasReadEn = 0;
                            weightReadEn = 0;    
                            layerReadEn = 0;
                            if(pcieDataReady == 1) begin
                                pcieCmd = 0;
                                convRst = 0;
                                runLayer = CONV5;
                                biasReadEn = 1;
                                weightReadEn = 1;
                                layerReadEn = 1;
                            end
                        end
                        else begin
                            convRst = 1;
                            runLayer = CONV4;
                            biasReadEn = 1;
                            weightReadEn = 1;
                            layerReadEn = 1;
                        end                       
                    end
                CONV5:
                    begin
                        if(convStatus == 1) begin
                            pcieCmd = 1;
                            biasReadEn = 0;
                            weightReadEn = 0;    
                            layerReadEn = 0;
                            if(pcieDataReady == 1) begin
                                pcieCmd = 0;
                                poolRst = 0;
                                runLayer = POOL5;
                                biasReadEn = 0;
                                weightReadEn = 0;
                                layerReadEn = 1;
                            end
                        end
                        else begin
                            convRst = 1;
                            runLayer = CONV5;
                            biasReadEn = 1;
                            weightReadEn = 1;
                            layerReadEn = 1;
                        end                       
                    end
                POOL5:
                    begin
                        if(poolStatus == 1) begin
                            pcieCmd = 1;
                            biasReadEn = 0;
                            weightReadEn = 0;    
                            layerReadEn = 0;
                            if(pcieDataReady == 1) begin
                                pcieCmd = 0;
                                fcRst = 0;
                                runLayer = FC6;
                                biasReadEn = 1;
                                weightReadEn = 1;
                                layerReadEn = 1;
                            end
                        end
                        else begin
                            poolRst = 1;
                            runLayer = POOL5;
                            biasReadEn = 0;
                            weightReadEn = 0;
                            layerReadEn = 1;
                        end                     
                    end
                FC6:
                    begin
                        if(fcStatus == 1) begin
                            pcieCmd = 1;
                            biasReadEn = 0;
                            weightReadEn = 0;    
                            layerReadEn = 0;
                            if(pcieDataReady == 1) begin
                                pcieCmd = 0;
                                fcRst = 0;
                                runLayer = FC7;
                                biasReadEn = 1;
                                weightReadEn = 1;
                                layerReadEn = 1;
                            end
                        end
                        else begin
                            fcRst = 1;
                            runLayer = FC6;
                            biasReadEn = 1;
                            weightReadEn = 1;
                            layerReadEn = 1;
                        end                        
                    end
                FC7:
                    begin
                        if(fcStatus == 1) begin
                            pcieCmd = 1;
                            biasReadEn = 0;
                            weightReadEn = 0;    
                            layerReadEn = 0;
                            if(pcieDataReady == 1) begin
                                pcieCmd = 0;
                                fcRst = 0;
                                runLayer = FC8;
                                biasReadEn = 1;
                                weightReadEn = 1;
                                layerReadEn = 1;
                            end
                        end
                        else begin
                            fcRst = 1;
                            runLayer = FC7;
                            biasReadEn = 1;
                            weightReadEn = 1;
                            layerReadEn = 1;
                        end                       
                    end
                FC8:
                    begin
                        if(fcStatus == 1) begin
                            runLayer = IDLE;
                            biasReadEn = 0;
                            weightReadEn = 0;    
                            layerReadEn = 0;
                        end
                        else begin
                            fcRst = 1;
                            runLayer = FC8;
                            biasReadEn = 1;
                            weightReadEn = 1;
                            layerReadEn = 1;
                        end                       
                    end
            endcase
        end
    
    end
    
endmodule