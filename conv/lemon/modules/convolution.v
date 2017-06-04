`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/25 09:45:18
// Design Name: 
// Module Name: convolution
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

`include "ram_parameters.vh"
`include "alexnet_parameters.vh"

module convolution(
	input clk,
	input convRst,

	input [3:0] runLayer,                // which layer to run

    input [`WEIGHT_RAM_WIDTH - 1:0] readWeight, // get weight from weight RAM, 11*11, 5*5 3*3, not the whole weight, but each slice
    input [15:0]   readBias,             // get bias from bias RAM
    input [15:0]   readFM,               // get fm from layer data RAM, just a 16 bits value, do more times to get the matrix

    input addResultValid,
    input [15:0] addResult,

    input [15:0] multResult,

    output reg [`CONV_MAX_LINE_SIZE - 1:0] multData,
    output reg [`CONV_MAX_LINE_SIZE - 1:0] multWeight,

    output reg addAValid,
    output reg addBValid,

    output reg [15:0] addA,
    output reg [15:0] addB,

	output reg [18:0] layerReadAddr,     // read address of layer RAM
    output reg [9:0]  weightReadAddr,    // read address of weight RAM
    output reg        biasReadAddr,      // read address of bias RAM

    output reg [15:0] writeOutputLayerData,
    output reg [18:0] writeOutputLayerAddr,

    output reg updateBias,               // send to pcie_controller and update a bias
    output reg updateBiasAddr,

    output reg updateWeight,             // send to pcie_controller and update a weight    
    output reg [9:0] updateWeightAddr,

   	output reg convStatus,               // conv status, 0:idle or running; 1:done, done means the conv finish and output data is ready

    output reg multRst,
    output reg multEna
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
    reg [18:0] inputLayerStartIndex;
    reg [18:0] outputLayerStartIndex;
    
    reg [8:0] weight_count;       // loop 4, max value 384 < 512=2^9, the kernel number
    reg [8:0] depth_count;        // loop 2, max value 384 < 512=2^9, count the input feature map depth
    reg [3:0] weight_line_count;  // loop 1, max value 11 < 16=2^4, the kernel matrix line

    reg [7:0] fm_x;               // loop 3, max value 227 < 256=2^8, the fm matrix start location
    reg [7:0] fm_y;  

    reg [1:0] get_weight_number; 
    reg [1:0] get_bias_number;         // count the bias number, get only one bias each time
    reg [11:0] get_fm_number;    // max value 3*3*384=3456 < 4096=2^12, count the fm matrix number

    reg [`WEIGHT_RAM_WIDTH - 1:0] weight; // 11*11*16=1936
    reg [15:0] bias;
    reg [15:0] fm[120:0];        // 11*11=121 max value

    reg [175:0] weight_window[10:0];    // max value 11 lines, each line 11*16=176

    reg [3:0] mul_clk_count;
    reg write_to_layer_ram_count;
    reg bias_start_flag;
    reg [11:0]i;

    always @(posedge clk or posedge convRst) begin
        if(!convRst) begin // reset
            convStatus = 0;
            currentLayer = IDLE;

            layerReadAddr = 524287; // 2^19 max value
            weightReadAddr = 1023; // 2^10 max value
            biasReadAddr = 0;
            bias_start_flag = 0;

            weight_count = 0;
            depth_count = 0;
            weight_line_count = 0;

            fm_x = 0;
            fm_y = 0;

            get_weight_number = 0;
            get_bias_number = 0;
            get_fm_number = 0;

            writeOutputLayerAddr = 19'bx;

            mul_clk_count = 0;
            write_to_layer_ram_count = 0;

            multEna = 1;
            multRst = 0;
            // todo more 
        end
    end

    always @(posedge clk) begin
    	if(convRst) begin
            case(runLayer)
                IDLE: 
                	begin
                		currentLayer = runLayer;
                	end
                CONV1:
                    begin
                    	if(currentLayer != runLayer) begin
                            convStatus = 0;
                            currentLayer = runLayer;

                    		inputLayerStartIndex = `LAYER_RAM_START_INDEX_0;
                            outputLayerStartIndex = `LAYER_RAM_START_INDEX_1;
                            layerReadAddr = 524287; // 2^19 max value
                            weightReadAddr = 1023; // 2^10 max value
                            biasReadAddr = 0;
                            bias_start_flag = 0;

                            weight_count = 0;
                            depth_count = 0;
                            weight_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            get_weight_number = 0;
                            get_bias_number = 0;
                            get_fm_number = 0;

                            writeOutputLayerAddr = 19'bx;

                            mul_clk_count = 0;
                            write_to_layer_ram_count = 0;

                            multEna = 1;
                            multRst = 0;
                    	end
                        else begin
                            multEna = 1;
                            multRst = 1;

                            if(weight_count < `CONV1_KERNERL_NUMBER) begin      // loop 4
                                if(fm_y < `CONV1_FM) begin                      // loop 3, fm_y = fm_y + stride
                                    if(fm_x < `CONV1_FM) begin                  // loop 3, fm_x = fm_x + stride
                                        if(depth_count < `CONV1_FM_DEPTH) begin // loop 2
                                            // read bias data
                                            if(get_bias_number < 1) begin
                                                if(bias_start_flag == 0) begin
                                                    biasReadAddr = 0;
                                                    bias_start_flag = 1;
                                                end
                                                else if(biasReadAddr == 0)
                                                    biasReadAddr = 1;
                                                else if(biasReadAddr == 1)
                                                    biasReadAddr = 0;

                                                get_bias_number = 1;
                                            end
                                            else if(get_bias_number == 3) begin // get read value
                                                bias = readBias;
                                                //get_bias_number = 3;
                                            end
                                            else begin  
                                                get_bias_number = get_bias_number + 1;
                                            end

                                            // read weight data
                                            if(get_weight_number < 1) begin
                                                if (weightReadAddr == 1023) // start to read, go to the first weight
                                                    weightReadAddr = `WEIGHT_RAM_START_INDEX_0;
                                                else if(weightReadAddr <  `WEIGHT_RAM_START_INDEX_0 + `CONV1_FM_DEPTH) // the first weight
                                                    weightReadAddr = weightReadAddr + 1;
                                                else if(weightReadAddr == `WEIGHT_RAM_START_INDEX_0 + `CONV1_FM_DEPTH) // change to the second weight
                                                    weightReadAddr = `WEIGHT_RAM_START_INDEX_1;
                                                else if(weightReadAddr <  `WEIGHT_RAM_START_INDEX_1 + `CONV1_FM_DEPTH ) // the second weight
                                                    weightReadAddr = weightReadAddr + 1;

                                                get_weight_number = 1;
                                            end
                                            else if(get_weight_number == 3) begin // get read value 
                                                weight = readWeight;
                                                //get_weight_number = 3;
                                            end
                                            else begin 
                                                get_weight_number = get_weight_number + 1;
                                            end

                                            // read feature map part data
                                            if(get_fm_number < (`CONV1_KERNERL * `CONV1_KERNERL)) begin
                                                if(layerReadAddr == 524287) // the beginning
                                                    layerReadAddr = inputLayerStartIndex;

                                                else if(((get_fm_number + 1) % `CONV1_KERNERL) == 0) // go to next line
                                                    layerReadAddr = layerReadAddr + `CONV1_FM - `CONV1_KERNERL;
                                                else
                                                    layerReadAddr = layerReadAddr + 1;

                                                get_fm_number = get_fm_number + 1;

                                                if (get_fm_number >= 4) begin
                                                    fm[get_fm_number - 4] = readFM;
                                                end

                                            end
                                            else if(get_fm_number < (`CONV1_KERNERL * `CONV1_KERNERL + 3)) begin
                                                get_fm_number = get_fm_number + 1;
                                                fm[get_fm_number - 4] = readFM;
                                            end

                                            // kernel(weight and bias) is ready and do the conv
                                            if(    get_bias_number == 3 
                                                && get_weight_number == 3
                                                && get_fm_number == (`CONV1_KERNERL * `CONV1_KERNERL + 3)) begin

                                                weight_window[0]  = weight[`DATA_WIDTH * `CONV1_KERNERL - 1 :0];
                                                weight_window[1]  = weight[`DATA_WIDTH * `CONV1_KERNERL * 2  - 1:`DATA_WIDTH * `CONV1_KERNERL];
                                                weight_window[2]  = weight[`DATA_WIDTH * `CONV1_KERNERL * 3  - 1:`DATA_WIDTH * `CONV1_KERNERL * 2];
                                                weight_window[3]  = weight[`DATA_WIDTH * `CONV1_KERNERL * 4  - 1:`DATA_WIDTH * `CONV1_KERNERL * 3];
                                                weight_window[4]  = weight[`DATA_WIDTH * `CONV1_KERNERL * 5  - 1:`DATA_WIDTH * `CONV1_KERNERL * 4];
                                                weight_window[5]  = weight[`DATA_WIDTH * `CONV1_KERNERL * 6  - 1:`DATA_WIDTH * `CONV1_KERNERL * 5];
                                                weight_window[6]  = weight[`DATA_WIDTH * `CONV1_KERNERL * 7  - 1:`DATA_WIDTH * `CONV1_KERNERL * 6];
                                                weight_window[7]  = weight[`DATA_WIDTH * `CONV1_KERNERL * 8  - 1:`DATA_WIDTH * `CONV1_KERNERL * 7];
                                                weight_window[8]  = weight[`DATA_WIDTH * `CONV1_KERNERL * 9  - 1:`DATA_WIDTH * `CONV1_KERNERL * 8];
                                                weight_window[9]  = weight[`DATA_WIDTH * `CONV1_KERNERL * 10 - 1:`DATA_WIDTH * `CONV1_KERNERL * 9];
                                                weight_window[10] = weight[`DATA_WIDTH * `CONV1_KERNERL * 11 - 1:`DATA_WIDTH * `CONV1_KERNERL * 10];

                                                if(weight_line_count < `CONV1_KERNERL) begin
                                                    // multX11
                                                    i = weight_line_count * `CONV1_KERNERL;
                                                    multData = {fm[i+10], fm[i+9], fm[i+8], fm[i+7], fm[i+6], fm[i+5], fm[i+4], fm[i+3], fm[i+2], fm[i+1], fm[i]};
                                                    multWeight = weight_window[weight_line_count];
                                                    weight_line_count = weight_line_count + 1;

                                                    // wait 10 clk and add
                                                    if(mul_clk_count == 10) begin
                                                        addAValid = 1;
                                                        addBValid = 1;
                                                        addA = multResult;
                                                        addB = addResult;
                                                    end
                                                    else begin
                                                        mul_clk_count = mul_clk_count + 1;
                                                    end
                                                        
                                                end
                                                else begin
                                                    // go to next weight depth
                                                    weight_line_count = 0;
                                                    depth_count = depth_count + 1;
                                                    mul_clk_count = 0;
                                                end
                                                        
                                            end
                                        end
                                        else begin
                                            // finish a kernel conv, add bias, and write to layer ram
                                            addAValid = 1;
                                            addBValid = 1;

                                            addA = bias;
                                            addB = addResult; 

                                            // write addResult to layer RAM  
                                            if(write_to_layer_ram_count == 0) begin
                                                write_to_layer_ram_count = 1;
                                            end
                                            else if(write_to_layer_ram_count == 1) begin // write data
                                                writeOutputLayerData = addResult;
                                                if(writeOutputLayerAddr == 19'bx) begin
                                                    writeOutputLayerAddr = outputLayerStartIndex;
                                                end
                                                else begin
                                                    writeOutputLayerAddr = writeOutputLayerAddr + 1;
                                                end

                                                // go to next feature map part data
                                                fm_x = fm_x + `CONV1_STRIDE;
                                                get_fm_number = 0;

                                                layerReadAddr = fm_x + fm_y * `CONV1_FM ;
                                            end
                                        end
                                    end
                                    else begin
                                        fm_x = 0;
                                        fm_y = fm_y + `CONV1_STRIDE;
                                    end
                                end
                                else begin
                                    fm_y = 0;
                                    // go to next kernel
                                    get_weight_number = 0;
                                    weight_count = weight_count + 1;
                                end
                            end
                            else begin
                                convStatus = 1;
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
                            currentLayer = runLayer;

                            inputLayerStartIndex = `LAYER_RAM_START_INDEX_0;
                            outputLayerStartIndex = `LAYER_RAM_START_INDEX_1;
                            weightReadAddr = 0;
                            biasReadAddr = 0;
                            convStatus = 0;

                            weight_count = 0;
                            depth_count = 0;
                            weight_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            writeOutputLayerAddr = 0;

                            get_weight_number = 0;
                            get_bias_number = 0;
                            get_fm_number = 0;
                        end
                    end
                POOL2:
                    begin
                        currentLayer = runLayer;
                    end
                CONV3:
                    begin
                        if(currentLayer != runLayer) begin
                            currentLayer = runLayer;

                            inputLayerStartIndex = `LAYER_RAM_START_INDEX_0;
                            outputLayerStartIndex = `LAYER_RAM_START_INDEX_1;
                            weightReadAddr = 0;
                            biasReadAddr = 0;
                            convStatus = 0;

                            weight_count = 0;
                            depth_count = 0;
                            weight_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            writeOutputLayerAddr = 0;

                            get_weight_number = 0;
                            get_bias_number = 0;
                            get_fm_number = 0;
                        end
                    end
                CONV4:
                    begin
                        if(currentLayer != runLayer) begin
                            currentLayer = runLayer;

                            inputLayerStartIndex = `LAYER_RAM_START_INDEX_1;
                            outputLayerStartIndex = `LAYER_RAM_START_INDEX_0;
                            weightReadAddr = 0;
                            biasReadAddr = 0;
                            convStatus = 0;

                            weight_count = 0;
                            depth_count = 0;
                            weight_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            writeOutputLayerAddr = 0;

                            get_weight_number = 0;
                            get_bias_number = 0;
                            get_fm_number = 0;
                        end
                    end
                CONV5:
                    begin
                        if(currentLayer != runLayer) begin
                            currentLayer = runLayer;

                            inputLayerStartIndex = `LAYER_RAM_START_INDEX_0;
                            outputLayerStartIndex = `LAYER_RAM_START_INDEX_1;
                            weightReadAddr = 0;
                            biasReadAddr = 0;
                            convStatus = 0;

                            weight_count = 0;
                            depth_count = 0;
                            weight_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            writeOutputLayerAddr = 0;

                            get_weight_number = 0;
                            get_bias_number = 0;
                            get_fm_number = 0;
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
