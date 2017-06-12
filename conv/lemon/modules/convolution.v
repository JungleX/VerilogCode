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
    input poolRst,
    input fcRst,

	input [3:0] runLayer,                // which layer to run

    input [`WEIGHT_RAM_WIDTH - 1:0] readWeight, // get weight from weight RAM, 11*11, 5*5 3*3, not the whole weight, but each slice
    input [15:0]   readBias,             // get bias from bias RAM
    input [15:0]   readFM,               // get fm from layer data RAM, just a 16 bits value, do more times to get the matrix

    input addResultValid,
    input [15:0] addResult,

    input [15:0] multResult,
    input [15:0] maxpoolOut,

    input updateBiasDone,
    input updateWeightDone,

    output reg [`CONV_MAX_LINE_SIZE - 1:0] multData,
    output reg [`CONV_MAX_LINE_SIZE - 1:0] multWeight,

    output reg [`POOL_SIZE - 1:0] maxpoolIn,

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
    output reg poolStatus,               // pool status, 0:idle or running; 1:done, done means the pool finish and output data is ready
    output reg fcStatus,                 // fc status,   0:idle or running; 1:done, done means the pool finish and output data is ready

    output reg multRst,
    output reg multEna,

    output reg maxpoolRst,
    output reg maxpoolEna
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

    reg [15:0] bias;
    reg [15:0] fm[120:0];        // 11*11=121 max value

    reg [175:0] weight_window[10:0];    // max value 11 lines, each line 11*16=176

    reg [4:0] mul_clk_count;
    reg write_to_layer_ram_count;
    reg bias_start_flag;
    reg update_kernel_clk_count;

    reg [1:0] current_weight; // 0: 1 weight start; 1: 1 weight running; 2: 2 weight start; 3: 2 weight running

    reg [4:0] pool_clk_count;

    reg [15:0] conv_temp_result;
    reg [11:0]i;

    reg fc_fm_count;

    always @(posedge clk or posedge convRst) begin
        if(!convRst) begin // reset
            convStatus = 0;
            poolStatus = 0;
            fcStatus = 0;

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

            writeOutputLayerData = 0;
            writeOutputLayerAddr = 524287; // 2^19 max value

            mul_clk_count = 0;
            write_to_layer_ram_count = 0;
            update_kernel_clk_count = 0;

            current_weight = 0;

            conv_temp_result = 0;

            multEna = 1;
            multRst = 0;
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
                    	if(currentLayer != runLayer) begin // initial
                            convStatus = 0;
                            currentLayer = runLayer; // change status

                            inputLayerStartIndex = `LAYER_RAM_START_INDEX_0;
                            outputLayerStartIndex = `LAYER_RAM_START_INDEX_1;
                            layerReadAddr = 524287; // 2^19 max value
                            weightReadAddr = 1023;  // 2^10 max value
                            biasReadAddr = 0;
                            bias_start_flag = 0;

                            weight_count = 0;
                            depth_count = 0;
                            weight_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            // load data
                            get_weight_number = 0;
                            get_bias_number = 0;
                            get_fm_number = 0;

                            writeOutputLayerData = 0;
                            writeOutputLayerAddr = 524287; // 2^19 max value

                            mul_clk_count = 0;
                            write_to_layer_ram_count = 0;
                            update_kernel_clk_count = 0;

                            current_weight = 0;

                            conv_temp_result = 0;

                            multEna = 1;
                            multRst = 0;
                    	end
                        else begin
                            multEna = 1;
                            multRst = 1;

                            if(update_kernel_clk_count == 1) begin
                                if(updateWeightDone == 1) begin
                                    updateWeight = 0;
                                end

                                if(updateBiasDone == 1) begin
                                    updateBias = 0;
                                end

                                if((updateWeight == 0) && (updateBias == 0)) begin
                                    update_kernel_clk_count = 0;    
                                end
                            end

                            if(weight_count < `CONV1_KERNERL_NUMBER) begin             // loop 4
                                if(fm_y < (`CONV1_FM - `CONV1_KERNERL + 1)) begin      // loop 3, fm_y = fm_y + stride
                                    if(fm_x < (`CONV1_FM - `CONV1_KERNERL + 1)) begin  // loop 3, fm_x = fm_x + stride
                                        if(depth_count < `CONV1_FM_DEPTH) begin        // loop 2
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
                                            end
                                            else begin  
                                                get_bias_number = get_bias_number + 1;
                                            end

                                            // read weight data
                                            if(get_weight_number < 1) begin                                                    
                                                if (current_weight == 0) begin      // start to read the first weight
                                                    weightReadAddr = `WEIGHT_RAM_START_INDEX_0;
                                                    current_weight = 1;
                                                end
                                                else if(current_weight == 1) begin  // reading the first weight
                                                    weightReadAddr = weightReadAddr + 1;  
                                                end
                                                else if (current_weight == 2) begin // start to read the second weight
                                                    weightReadAddr = `WEIGHT_RAM_START_INDEX_1;
                                                    current_weight = 3;
                                                end
                                                else if(current_weight == 3) begin // reading the second weight
                                                    weightReadAddr = weightReadAddr + 1;
                                                end

                                                get_weight_number = 1;
                                            end
                                            else if(get_weight_number == 3) begin // get read value 
                                                weight_window[0]  = readWeight[`DATA_WIDTH * `CONV1_KERNERL - 1 :0];
                                                weight_window[1]  = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 2  - 1:`DATA_WIDTH * `CONV1_KERNERL];
                                                weight_window[2]  = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 3  - 1:`DATA_WIDTH * `CONV1_KERNERL * 2];
                                                weight_window[3]  = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 4  - 1:`DATA_WIDTH * `CONV1_KERNERL * 3];
                                                weight_window[4]  = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 5  - 1:`DATA_WIDTH * `CONV1_KERNERL * 4];
                                                weight_window[5]  = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 6  - 1:`DATA_WIDTH * `CONV1_KERNERL * 5];
                                                weight_window[6]  = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 7  - 1:`DATA_WIDTH * `CONV1_KERNERL * 6];
                                                weight_window[7]  = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 8  - 1:`DATA_WIDTH * `CONV1_KERNERL * 7];
                                                weight_window[8]  = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 9  - 1:`DATA_WIDTH * `CONV1_KERNERL * 8];
                                                weight_window[9]  = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 10 - 1:`DATA_WIDTH * `CONV1_KERNERL * 9];
                                                weight_window[10] = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 11 - 1:`DATA_WIDTH * `CONV1_KERNERL * 10];
                                            end
                                            else begin 
                                                get_weight_number = get_weight_number + 1;
                                            end

                                            // read feature map part data
                                            if(get_fm_number < (`CONV1_KERNERL * `CONV1_KERNERL)) begin
                                                if(layerReadAddr == 524287) // the beginning
                                                    layerReadAddr = inputLayerStartIndex;

                                                else if(get_fm_number > 0 && ((get_fm_number) % `CONV1_KERNERL) == 0) // go to next line
                                                    layerReadAddr = layerReadAddr + `CONV1_FM - (`CONV1_KERNERL - 1);
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

                                                if(weight_line_count < `CONV1_KERNERL) begin
                                                    // multX11
                                                    i = weight_line_count * `CONV1_KERNERL;
                                                    multData = {fm[i+10], fm[i+9], fm[i+8], fm[i+7], fm[i+6], fm[i+5], fm[i+4], fm[i+3], fm[i+2], fm[i+1], fm[i]};
                                                    multWeight = weight_window[weight_line_count];
                                                    weight_line_count = weight_line_count + 1;   
                                                end

                                                // wait 10 clk and add
                                                if(mul_clk_count < 11) begin
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                if((mul_clk_count >= 11) && (mul_clk_count < 23)) begin
                                                    addAValid = 1;
                                                    addBValid = 1;
                                                    addA = multResult;
                                                    addB = addResult;
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                else if(mul_clk_count == 23) begin
                                                    addA = conv_temp_result;
                                                    addB = addResult;
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                else if(mul_clk_count == 24) begin
                                                    // save the temp result
                                                    conv_temp_result = addResult;
                                                    multData = 0;
                                                    multWeight = 0;
                                                    addA = 0;
                                                    addB = 0;

                                                    // go to next depth
                                                    depth_count = depth_count + 1;
                                                    get_weight_number = 0;
                                                    get_fm_number = 0;
                                                    weight_line_count = 0;
                                                    mul_clk_count = 0;

                                                    // next depth address
                                                    // the last -1: when read fm data, it will +1
                                                    if(depth_count < `CONV1_FM_DEPTH) begin
                                                        layerReadAddr = inputLayerStartIndex + depth_count * `CONV1_FM * `CONV1_FM + fm_x + fm_y * `CONV1_FM - 1;
                                                    end
                                                end       
                                            end
                                        end
                                        else begin
                                            // finish a kernel conv, add bias, and write to layer ram
                                            addAValid = 1;
                                            addBValid = 1;

                                            addA = bias;
                                            addB = conv_temp_result; 

                                            // write addResult to layer RAM  
                                            if(write_to_layer_ram_count == 0) begin
                                                write_to_layer_ram_count = 1;
                                            end
                                            else if(write_to_layer_ram_count == 1) begin // write data
                                                writeOutputLayerData = addResult;

                                                conv_temp_result = 0;
                                                
                                                addA = 0;
                                                addB = 0;

                                                if(writeOutputLayerAddr == 524287) begin
                                                    writeOutputLayerAddr = outputLayerStartIndex;
                                                end
                                                else begin
                                                    writeOutputLayerAddr = writeOutputLayerAddr + 1;
                                                end

                                                write_to_layer_ram_count = 0;

                                                depth_count = 0;
                                                // go to next feature map part data
                                                fm_x = fm_x + `CONV1_STRIDE;
                                                get_fm_number = 0;
                                                layerReadAddr = inputLayerStartIndex + fm_x + fm_y * `CONV1_FM - 1;

                                                get_weight_number = 0;
                                                
                                                if(current_weight == 0 || current_weight == 1) begin
                                                    current_weight = 0;
                                                end
                                                else if(current_weight == 2 || current_weight == 3) begin
                                                    current_weight = 2;
                                                end
                                                
                                            end
                                        end
                                    end
                                    else begin // go to next fm matrix line
                                        if(current_weight == 0 || current_weight == 1) begin
                                            current_weight = 0;
                                        end
                                        else if(current_weight == 2 || current_weight == 3) begin
                                            current_weight = 2;
                                        end

                                        depth_count = 0;
                                        weight_line_count = 0;

                                        fm_x = 0;
                                        fm_y = fm_y + `CONV1_STRIDE;
                                        layerReadAddr = inputLayerStartIndex + fm_x + fm_y * `CONV1_FM - 1;

                                        get_weight_number = 0;
                                        get_fm_number = 0;

                                        mul_clk_count = 0;
                                        write_to_layer_ram_count = 0;
                                        
                                    end
                                end
                                else begin // go to next kernel
                                    
                                    layerReadAddr = 524287; // the beginning //layerReadAddr = inputLayerStartIndex;

                                    // change to another kernel
                                    if(current_weight == 0 || current_weight == 1) begin
                                        current_weight = 2;
                                    end
                                    else if(current_weight == 2 || current_weight == 3) begin
                                        current_weight = 0;
                                    end

                                    weight_count = weight_count + 1;
                                    depth_count = 0;
                                    weight_line_count = 0;

                                    fm_x = 0;
                                    fm_y = 0;

                                    get_weight_number = 0;
                                    get_bias_number = 0;
                                    get_fm_number = 0;

                                    if(update_kernel_clk_count == 0) begin
                                        // update weight
                                        updateWeight = 1;
                                        if(current_weight == 0) 
                                            updateWeightAddr = `WEIGHT_RAM_START_INDEX_1;
                                        else if(current_weight == 2)
                                            updateWeightAddr = `WEIGHT_RAM_START_INDEX_0;

                                        // update bias
                                        updateBias = 1;
                                        updateBiasAddr = biasReadAddr;

                                        update_kernel_clk_count = 1;
                                    end
                                        
                                end
                            end
                            else begin
                                convStatus = 1;
                            end
                        end
                    end
                POOL1:
                    begin
                        if(currentLayer != runLayer) begin // initial
                            poolStatus = 0;
                            currentLayer = runLayer;

                            inputLayerStartIndex = `LAYER_RAM_START_INDEX_1;
                            outputLayerStartIndex = `LAYER_RAM_START_INDEX_0;
                            layerReadAddr = 524287; // 2^19 max value

                            depth_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            // load data
                            get_fm_number = 0;

                            writeOutputLayerData = 0;
                            writeOutputLayerAddr = 524287; // 2^19 max value

                            pool_clk_count = 0;

                            maxpoolEna = 1;
                            maxpoolRst = 0;
                        end
                        else begin
                            maxpoolEna = 1;
                            maxpoolRst = 1;

                            if(depth_count < `POOL1_DEPTH) begin 
                                if(fm_y < (`POOL1_FM - `POOL1_WINDOW + 1)) begin
                                    if(fm_x < (`POOL1_FM - `POOL1_WINDOW + 1)) begin
                                        // read feature map part data
                                        if(get_fm_number < `POOL1_WINDOW_SIZE) begin
                                            if(layerReadAddr == 524287) begin// the beginning
                                                layerReadAddr = inputLayerStartIndex;
                                            end
                                            else if(get_fm_number > 0 && ((get_fm_number) % `POOL1_WINDOW) == 0) // go to next line
                                                layerReadAddr = layerReadAddr + `POOL1_FM - (`POOL1_WINDOW - 1);
                                            else
                                                layerReadAddr = layerReadAddr + 1;

                                            get_fm_number = get_fm_number + 1;

                                            if (get_fm_number >= 4) begin
                                                fm[get_fm_number - 4] = readFM;
                                            end

                                        end
                                        else if(get_fm_number < (`POOL1_WINDOW_SIZE + 3)) begin
                                            get_fm_number = get_fm_number + 1;
                                            fm[get_fm_number - 4] = readFM;
                                        end

                                        // max pool
                                        if(get_fm_number == (`POOL1_WINDOW_SIZE + 3)) begin
                                            maxpoolIn = {fm[8], fm[7], fm[6], fm[5], fm[4], fm[3], fm[2], fm[1], fm[0]};

                                            // get max pool result
                                            if(pool_clk_count < 6) begin
                                                pool_clk_count = pool_clk_count + 1;
                                            end
                                            else begin
                                                if(writeOutputLayerAddr == 524287) begin
                                                    writeOutputLayerAddr = outputLayerStartIndex;
                                                end
                                                else begin
                                                    writeOutputLayerAddr = writeOutputLayerAddr + 1;
                                                end

                                                writeOutputLayerData = maxpoolOut;

                                                pool_clk_count = 0;

                                                // go to next feature map part data
                                                fm_x = fm_x + `POOL1_STRIDE;
                                                get_fm_number = 0;
                                                layerReadAddr = inputLayerStartIndex + depth_count * `POOL1_FM_DATA + fm_x + fm_y * `POOL1_FM - 1;
                                            end
                                        end
                                    end
                                    else begin
                                        pool_clk_count = 0;

                                        // go to next fm matrix line
                                        fm_x = 0;
                                        fm_y = fm_y + `POOL1_STRIDE;
                                        layerReadAddr = inputLayerStartIndex + depth_count * `POOL1_FM_DATA + fm_y * `POOL1_FM - 1;
                                    end
                                end
                                else begin
                                    // go to next depth
                                    fm_x = 0;
                                    fm_y = 0;
                                    depth_count = depth_count + 1;
                                    layerReadAddr = inputLayerStartIndex + depth_count * `POOL1_FM_DATA - 1;
                                end
                            end
                            else begin
                                poolStatus = 1;
                            end
                        end
                    end 
                CONV2:
                    begin
                        if(currentLayer != runLayer) begin
                            convStatus = 0;
                            currentLayer = runLayer;

                            inputLayerStartIndex = `LAYER_RAM_START_INDEX_0;
                            outputLayerStartIndex = `LAYER_RAM_START_INDEX_1;
                            layerReadAddr = 524287; // 2^19 max value
                            weightReadAddr = 1023;  // 2^10 max value
                            biasReadAddr = 0;
                            bias_start_flag = 0;

                            weight_count = 0;
                            depth_count = 0;
                            weight_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            // load data
                            get_weight_number = 0;
                            get_bias_number = 0;
                            get_fm_number = 0;

                            writeOutputLayerData = 0;
                            writeOutputLayerAddr = 524287; // 2^19 max value

                            mul_clk_count = 0;
                            write_to_layer_ram_count = 0;
                            update_kernel_clk_count = 0;

                            current_weight = 0;

                            conv_temp_result = 0;

                            multEna = 1;
                            multRst = 0;
                        end
                        else begin
                            multEna = 1;
                            multRst = 1;

                            if(update_kernel_clk_count == 1) begin
                                if(updateWeightDone == 1) begin
                                    updateWeight = 0;
                                end

                                if(updateBiasDone == 1) begin
                                    updateBias = 0;
                                end

                                if((updateWeight == 0) && (updateBias == 0)) begin
                                    update_kernel_clk_count = 0;    
                                end
                            end

                            if(weight_count < `CONV2_KERNERL_NUMBER) begin             // loop 4
                                if(fm_y < (`CONV2_FM - `CONV2_KERNERL + 1)) begin      // loop 3, fm_y = fm_y + stride
                                    if(fm_x < (`CONV2_FM - `CONV2_KERNERL + 1)) begin  // loop 3, fm_x = fm_x + stride
                                        if(depth_count < `CONV2_FM_DEPTH) begin        // loop 2
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
                                            end
                                            else begin  
                                                get_bias_number = get_bias_number + 1;
                                            end

                                            // read weight data
                                            if(get_weight_number < 1) begin                                                    
                                                if (current_weight == 0) begin      // start to read the first weight
                                                    weightReadAddr = `WEIGHT_RAM_START_INDEX_0;
                                                    current_weight = 1;
                                                end
                                                else if(current_weight == 1) begin  // reading the first weight
                                                    weightReadAddr = weightReadAddr + 1;  
                                                end
                                                else if (current_weight == 2) begin // start to read the second weight
                                                    weightReadAddr = `WEIGHT_RAM_START_INDEX_1;
                                                    current_weight = 3;
                                                end
                                                else if(current_weight == 3) begin // reading the second weight
                                                    weightReadAddr = weightReadAddr + 1;
                                                end

                                                get_weight_number = 1;
                                            end
                                            else if(get_weight_number == 3) begin // get read value 
                                                weight_window[0]  = {96'b0, readWeight[`DATA_WIDTH * `CONV2_KERNERL - 1 :0]};
                                                weight_window[1]  = {96'b0, readWeight[`DATA_WIDTH * `CONV2_KERNERL * 2  - 1:`DATA_WIDTH * `CONV2_KERNERL]};
                                                weight_window[2]  = {96'b0, readWeight[`DATA_WIDTH * `CONV2_KERNERL * 3  - 1:`DATA_WIDTH * `CONV2_KERNERL * 2]};
                                                weight_window[3]  = {96'b0, readWeight[`DATA_WIDTH * `CONV2_KERNERL * 4  - 1:`DATA_WIDTH * `CONV2_KERNERL * 3]};
                                                weight_window[4]  = {96'b0, readWeight[`DATA_WIDTH * `CONV2_KERNERL * 5  - 1:`DATA_WIDTH * `CONV2_KERNERL * 4]};
                                            end
                                            else begin 
                                                get_weight_number = get_weight_number + 1;
                                            end

                                            // read feature map part data
                                            if(get_fm_number < (`CONV2_KERNERL * `CONV2_KERNERL)) begin
                                                if(layerReadAddr == 524287) // the beginning
                                                    layerReadAddr = inputLayerStartIndex;

                                                else if(get_fm_number > 0 && ((get_fm_number) % `CONV2_KERNERL) == 0) // go to next line
                                                    layerReadAddr = layerReadAddr + `CONV2_FM - (`CONV2_KERNERL - 1);
                                                else
                                                    layerReadAddr = layerReadAddr + 1;

                                                get_fm_number = get_fm_number + 1;

                                                if (get_fm_number >= 4) begin
                                                    fm[get_fm_number - 4] = readFM;
                                                end

                                            end
                                            else if(get_fm_number < (`CONV2_KERNERL * `CONV2_KERNERL + 3)) begin
                                                get_fm_number = get_fm_number + 1;
                                                fm[get_fm_number - 4] = readFM;
                                            end

                                            // kernel(weight and bias) is ready and do the conv
                                            if(    get_bias_number == 3 
                                                && get_weight_number == 3
                                                && get_fm_number == (`CONV2_KERNERL * `CONV2_KERNERL + 3)) begin

                                                if(weight_line_count < `CONV2_KERNERL) begin
                                                    // multX11
                                                    i = weight_line_count * `CONV2_KERNERL;
                                                    multData = {96'b0, fm[i+4], fm[i+3], fm[i+2], fm[i+1], fm[i]}; // 6*16 = 96
                                                    multWeight = weight_window[weight_line_count]; 
                                                    weight_line_count = weight_line_count + 1;   
                                                end

                                                // wait 10 clk and add
                                                if(mul_clk_count < 11) begin
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                if((mul_clk_count >= 11) && (mul_clk_count < 17)) begin
                                                    addAValid = 1;
                                                    addBValid = 1;
                                                    addA = multResult;
                                                    addB = addResult;
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                else if(mul_clk_count == 17) begin
                                                    addA = conv_temp_result;
                                                    addB = addResult;
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                else if(mul_clk_count == 18) begin
                                                    // save the temp result
                                                    conv_temp_result = addResult;
                                                    multData = 0;
                                                    multWeight = 0;
                                                    addA = 0;
                                                    addB = 0;

                                                    // go to next depth
                                                    depth_count = depth_count + 1;
                                                    get_weight_number = 0;
                                                    get_fm_number = 0;
                                                    weight_line_count = 0;
                                                    mul_clk_count = 0;

                                                    // next depth address
                                                    // the last -1: when read fm data, it will +1
                                                    if(depth_count < `CONV2_FM_DEPTH) begin
                                                        layerReadAddr = inputLayerStartIndex + depth_count * `CONV2_FM * `CONV2_FM + fm_x + fm_y * `CONV2_FM - 1;
                                                    end
                                                end       
                                            end
                                        end
                                        else begin
                                            // finish a kernel conv, add bias, and write to layer ram
                                            addAValid = 1;
                                            addBValid = 1;

                                            addA = bias;
                                            addB = conv_temp_result; 

                                            // write addResult to layer RAM  
                                            if(write_to_layer_ram_count == 0) begin
                                                write_to_layer_ram_count = 1;
                                            end
                                            else if(write_to_layer_ram_count == 1) begin // write data
                                                writeOutputLayerData = addResult;

                                                conv_temp_result = 0;
                                                
                                                addA = 0;
                                                addB = 0;

                                                if(writeOutputLayerAddr == 524287) begin
                                                    writeOutputLayerAddr = outputLayerStartIndex;
                                                end
                                                else begin
                                                    writeOutputLayerAddr = writeOutputLayerAddr + 1;
                                                end

                                                write_to_layer_ram_count = 0;

                                                depth_count = 0;
                                                // go to next feature map part data
                                                fm_x = fm_x + `CONV2_STRIDE;
                                                get_fm_number = 0;
                                                layerReadAddr = inputLayerStartIndex + fm_x + fm_y * `CONV2_FM - 1;

                                                get_weight_number = 0;
                                                
                                                if(current_weight == 0 || current_weight == 1) begin
                                                    current_weight = 0;
                                                end
                                                else if(current_weight == 2 || current_weight == 3) begin
                                                    current_weight = 2;
                                                end
                                                
                                            end
                                        end
                                    end
                                    else begin // go to next fm matrix line
                                        if(current_weight == 0 || current_weight == 1) begin
                                            current_weight = 0;
                                        end
                                        else if(current_weight == 2 || current_weight == 3) begin
                                            current_weight = 2;
                                        end

                                        depth_count = 0;
                                        weight_line_count = 0;

                                        fm_x = 0;
                                        fm_y = fm_y + `CONV2_STRIDE;
                                        layerReadAddr = inputLayerStartIndex + fm_x + fm_y * `CONV2_FM - 1;

                                        get_weight_number = 0;
                                        get_fm_number = 0;

                                        mul_clk_count = 0;
                                        write_to_layer_ram_count = 0;
                                        
                                    end
                                end
                                else begin // go to next kernel
                                    
                                    layerReadAddr = 524287; // the beginning //layerReadAddr = inputLayerStartIndex;

                                    // change to another kernel
                                    if(current_weight == 0 || current_weight == 1) begin
                                        current_weight = 2;
                                    end
                                    else if(current_weight == 2 || current_weight == 3) begin
                                        current_weight = 0;
                                    end

                                    weight_count = weight_count + 1;
                                    depth_count = 0;
                                    weight_line_count = 0;

                                    fm_x = 0;
                                    fm_y = 0;

                                    get_weight_number = 0;
                                    get_bias_number = 0;
                                    get_fm_number = 0;

                                    if(update_kernel_clk_count == 0) begin
                                        // update weight
                                        updateWeight = 1;
                                        if(current_weight == 0) 
                                            updateWeightAddr = `WEIGHT_RAM_START_INDEX_1;
                                        else if(current_weight == 2)
                                            updateWeightAddr = `WEIGHT_RAM_START_INDEX_0;

                                        // update bias
                                        updateBias = 1;
                                        updateBiasAddr = biasReadAddr;

                                        update_kernel_clk_count = 1;
                                    end
                                        
                                end
                            end
                            else begin
                                convStatus = 1;
                            end
                        end
                    end
                POOL2:
                    begin
                        if(currentLayer != runLayer) begin // initial
                            poolStatus = 0;
                            currentLayer = runLayer;

                            inputLayerStartIndex = `LAYER_RAM_START_INDEX_1;
                            outputLayerStartIndex = `LAYER_RAM_START_INDEX_0;
                            layerReadAddr = 524287; // 2^19 max value

                            depth_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            // load data
                            get_fm_number = 0;

                            writeOutputLayerData = 0;
                            writeOutputLayerAddr = 524287; // 2^19 max value

                            pool_clk_count = 0;

                            maxpoolEna = 1;
                            maxpoolRst = 0;
                        end
                        else begin
                            maxpoolEna = 1;
                            maxpoolRst = 1;

                            if(depth_count < `POOL2_DEPTH) begin 
                                if(fm_y < (`POOL2_FM - `POOL2_WINDOW + 1)) begin
                                    if(fm_x < (`POOL2_FM - `POOL2_WINDOW + 1)) begin
                                        // read feature map part data
                                        if(get_fm_number < `POOL2_WINDOW_SIZE) begin
                                            if(layerReadAddr == 524287) begin// the beginning
                                                layerReadAddr = inputLayerStartIndex;
                                            end
                                            else if(get_fm_number > 0 && ((get_fm_number) % `POOL2_WINDOW) == 0) // go to next line
                                                layerReadAddr = layerReadAddr + `POOL2_FM - (`POOL2_WINDOW - 1);
                                            else
                                                layerReadAddr = layerReadAddr + 1;

                                            get_fm_number = get_fm_number + 1;

                                            if (get_fm_number >= 4) begin
                                                fm[get_fm_number - 4] = readFM;
                                            end

                                        end
                                        else if(get_fm_number < (`POOL2_WINDOW_SIZE + 3)) begin
                                            get_fm_number = get_fm_number + 1;
                                            fm[get_fm_number - 4] = readFM;
                                        end

                                        // max pool
                                        if(get_fm_number == (`POOL2_WINDOW_SIZE + 3)) begin
                                            maxpoolIn = {fm[8], fm[7], fm[6], fm[5], fm[4], fm[3], fm[2], fm[1], fm[0]};

                                            // get max pool result
                                            if(pool_clk_count < 6) begin
                                                pool_clk_count = pool_clk_count + 1;
                                            end
                                            else begin
                                                if(writeOutputLayerAddr == 524287) begin
                                                    writeOutputLayerAddr = outputLayerStartIndex;
                                                end
                                                else begin
                                                    writeOutputLayerAddr = writeOutputLayerAddr + 1;
                                                end

                                                writeOutputLayerData = maxpoolOut;

                                                pool_clk_count = 0;

                                                // go to next feature map part data
                                                fm_x = fm_x + `POOL2_STRIDE;
                                                get_fm_number = 0;
                                                layerReadAddr = inputLayerStartIndex + depth_count * `POOL2_FM_DATA + fm_x + fm_y * `POOL2_FM - 1;
                                            end
                                        end
                                    end
                                    else begin
                                        pool_clk_count = 0;

                                        // go to next fm matrix line
                                        fm_x = 0;
                                        fm_y = fm_y + `POOL2_STRIDE;
                                        layerReadAddr = inputLayerStartIndex + depth_count * `POOL2_FM_DATA + fm_y * `POOL2_FM - 1;
                                    end
                                end
                                else begin
                                    // go to next depth
                                    fm_x = 0;
                                    fm_y = 0;
                                    depth_count = depth_count + 1;
                                    layerReadAddr = inputLayerStartIndex + depth_count * `POOL2_FM_DATA - 1;
                                end
                            end
                            else begin
                                poolStatus = 1;
                            end
                        end
                    end
                CONV3:
                    begin
                        if(currentLayer != runLayer) begin
                            convStatus = 0;
                            currentLayer = runLayer;

                            inputLayerStartIndex = `LAYER_RAM_START_INDEX_0;
                            outputLayerStartIndex = `LAYER_RAM_START_INDEX_1;
                            layerReadAddr = 524287; // 2^19 max value
                            weightReadAddr = 1023;  // 2^10 max value
                            biasReadAddr = 0;
                            bias_start_flag = 0;

                            weight_count = 0;
                            depth_count = 0;
                            weight_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            // load data
                            get_weight_number = 0;
                            get_bias_number = 0;
                            get_fm_number = 0;

                            writeOutputLayerData = 0;
                            writeOutputLayerAddr = 524287; // 2^19 max value
                            
                            mul_clk_count = 0;
                            write_to_layer_ram_count = 0;
                            update_kernel_clk_count = 0;

                            current_weight = 0;

                            conv_temp_result = 0;

                            multEna = 1;
                            multRst = 0;
                        end
                        else begin
                            multEna = 1;
                            multRst = 1;

                            if(update_kernel_clk_count == 1) begin
                                if(updateWeightDone == 1) begin
                                    updateWeight = 0;
                                end

                                if(updateBiasDone == 1) begin
                                    updateBias = 0;
                                end

                                if((updateWeight == 0) && (updateBias == 0)) begin
                                    update_kernel_clk_count = 0;    
                                end
                            end

                            if(weight_count < `CONV3_KERNERL_NUMBER) begin             // loop 4
                                if(fm_y < (`CONV3_FM - `CONV3_KERNERL + 1)) begin      // loop 3, fm_y = fm_y + stride
                                    if(fm_x < (`CONV3_FM - `CONV3_KERNERL + 1)) begin  // loop 3, fm_x = fm_x + stride
                                        if(depth_count < `CONV3_FM_DEPTH) begin        // loop 2
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
                                            end
                                            else begin  
                                                get_bias_number = get_bias_number + 1;
                                            end

                                            // read weight data
                                            if(get_weight_number < 1) begin                                                    
                                                if (current_weight == 0) begin      // start to read the first weight
                                                    weightReadAddr = `WEIGHT_RAM_START_INDEX_0;
                                                    current_weight = 1;
                                                end
                                                else if(current_weight == 1) begin  // reading the first weight
                                                    weightReadAddr = weightReadAddr + 1;  
                                                end
                                                else if (current_weight == 2) begin // start to read the second weight
                                                    weightReadAddr = `WEIGHT_RAM_START_INDEX_1;
                                                    current_weight = 3;
                                                end
                                                else if(current_weight == 3) begin // reading the second weight
                                                    weightReadAddr = weightReadAddr + 1;
                                                end

                                                get_weight_number = 1;
                                            end
                                            else if(get_weight_number == 3) begin // get read value 
                                                weight_window[0]  = {128'b0, readWeight[`DATA_WIDTH * `CONV3_KERNERL - 1 :0]};
                                                weight_window[1]  = {128'b0, readWeight[`DATA_WIDTH * `CONV3_KERNERL * 2  - 1:`DATA_WIDTH * `CONV3_KERNERL]};
                                                weight_window[2]  = {128'b0, readWeight[`DATA_WIDTH * `CONV3_KERNERL * 3  - 1:`DATA_WIDTH * `CONV3_KERNERL * 2]};
                                            end
                                            else begin 
                                                get_weight_number = get_weight_number + 1;
                                            end

                                            // read feature map part data
                                            if(get_fm_number < (`CONV3_KERNERL * `CONV3_KERNERL)) begin
                                                if(layerReadAddr == 524287) // the beginning
                                                    layerReadAddr = inputLayerStartIndex;

                                                else if(get_fm_number > 0 && ((get_fm_number) % `CONV3_KERNERL) == 0) // go to next line
                                                    layerReadAddr = layerReadAddr + `CONV3_FM - (`CONV3_KERNERL - 1);
                                                else
                                                    layerReadAddr = layerReadAddr + 1;

                                                get_fm_number = get_fm_number + 1;

                                                if (get_fm_number >= 4) begin
                                                    fm[get_fm_number - 4] = readFM;
                                                end

                                            end
                                            else if(get_fm_number < (`CONV3_KERNERL * `CONV3_KERNERL + 3)) begin
                                                get_fm_number = get_fm_number + 1;
                                                fm[get_fm_number - 4] = readFM;
                                            end

                                            // kernel(weight and bias) is ready and do the conv
                                            if(    get_bias_number == 3 
                                                && get_weight_number == 3
                                                && get_fm_number == (`CONV3_KERNERL * `CONV3_KERNERL + 3)) begin

                                                if(weight_line_count < `CONV3_KERNERL) begin
                                                    // multX11
                                                    i = weight_line_count * `CONV3_KERNERL;
                                                    multData = {128'b0, fm[i+2], fm[i+1], fm[i]}; // 8*16 = 128
                                                    multWeight = weight_window[weight_line_count]; 
                                                    weight_line_count = weight_line_count + 1;   
                                                end

                                                // wait 10 clk and add
                                                if(mul_clk_count < 11) begin
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                if((mul_clk_count >= 11) && (mul_clk_count < 15)) begin
                                                    addAValid = 1;
                                                    addBValid = 1;
                                                    addA = multResult;
                                                    addB = addResult;
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                else if(mul_clk_count == 15) begin
                                                    addA = conv_temp_result;
                                                    addB = addResult;
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                else if(mul_clk_count == 16) begin
                                                    // save the temp result
                                                    conv_temp_result = addResult;
                                                    multData = 0;
                                                    multWeight = 0;
                                                    addA = 0;
                                                    addB = 0;

                                                    // go to next depth
                                                    depth_count = depth_count + 1;
                                                    get_weight_number = 0;
                                                    get_fm_number = 0;
                                                    weight_line_count = 0;
                                                    mul_clk_count = 0;

                                                    // next depth address
                                                    // the last -1: when read fm data, it will +1
                                                    if(depth_count < `CONV3_FM_DEPTH) begin
                                                        layerReadAddr = inputLayerStartIndex + depth_count * `CONV3_FM * `CONV3_FM + fm_x + fm_y * `CONV3_FM - 1;
                                                    end
                                                end       
                                            end
                                        end
                                        else begin
                                            // finish a kernel conv, add bias, and write to layer ram
                                            addAValid = 1;
                                            addBValid = 1;

                                            addA = bias;
                                            addB = conv_temp_result; 

                                            // write addResult to layer RAM  
                                            if(write_to_layer_ram_count == 0) begin
                                                write_to_layer_ram_count = 1;
                                            end
                                            else if(write_to_layer_ram_count == 1) begin // write data
                                                writeOutputLayerData = addResult;

                                                conv_temp_result = 0;
                                                
                                                addA = 0;
                                                addB = 0;

                                                if(writeOutputLayerAddr == 524287) begin
                                                    writeOutputLayerAddr = outputLayerStartIndex;
                                                end
                                                else begin
                                                    writeOutputLayerAddr = writeOutputLayerAddr + 1;
                                                end

                                                write_to_layer_ram_count = 0;

                                                depth_count = 0;
                                                // go to next feature map part data
                                                fm_x = fm_x + `CONV3_STRIDE;
                                                get_fm_number = 0;
                                                layerReadAddr = inputLayerStartIndex + fm_x + fm_y * `CONV3_FM - 1;

                                                get_weight_number = 0;
                                                
                                                if(current_weight == 0 || current_weight == 1) begin
                                                    current_weight = 0;
                                                end
                                                else if(current_weight == 2 || current_weight == 3) begin
                                                    current_weight = 2;
                                                end
                                                
                                            end
                                        end
                                    end
                                    else begin // go to next fm matrix line
                                        if(current_weight == 0 || current_weight == 1) begin
                                            current_weight = 0;
                                        end
                                        else if(current_weight == 2 || current_weight == 3) begin
                                            current_weight = 2;
                                        end

                                        depth_count = 0;
                                        weight_line_count = 0;

                                        fm_x = 0;
                                        fm_y = fm_y + `CONV3_STRIDE;
                                        layerReadAddr = inputLayerStartIndex + fm_x + fm_y * `CONV3_FM - 1;

                                        get_weight_number = 0;
                                        get_fm_number = 0;

                                        mul_clk_count = 0;
                                        write_to_layer_ram_count = 0;
                                        
                                    end
                                end
                                else begin // go to next kernel
                                    
                                    layerReadAddr = 524287; // the beginning //layerReadAddr = inputLayerStartIndex;

                                    // change to another kernel
                                    if(current_weight == 0 || current_weight == 1) begin
                                        current_weight = 2;
                                    end
                                    else if(current_weight == 2 || current_weight == 3) begin
                                        current_weight = 0;
                                    end

                                    weight_count = weight_count + 1;
                                    depth_count = 0;
                                    weight_line_count = 0;

                                    fm_x = 0;
                                    fm_y = 0;

                                    get_weight_number = 0;
                                    get_bias_number = 0;
                                    get_fm_number = 0;

                                    if(update_kernel_clk_count == 0) begin
                                        // update weight
                                        updateWeight = 1;
                                        if(current_weight == 0) 
                                            updateWeightAddr = `WEIGHT_RAM_START_INDEX_1;
                                        else if(current_weight == 2)
                                            updateWeightAddr = `WEIGHT_RAM_START_INDEX_0;

                                        // update bias
                                        updateBias = 1;
                                        updateBiasAddr = biasReadAddr;

                                        update_kernel_clk_count = 1;
                                    end
                                        
                                end
                            end
                            else begin
                                convStatus = 1;
                            end
                        end
                    end
                CONV4:
                    begin
                        if(currentLayer != runLayer) begin
                            convStatus = 0;
                            currentLayer = runLayer;

                            inputLayerStartIndex = `LAYER_RAM_START_INDEX_1;
                            outputLayerStartIndex = `LAYER_RAM_START_INDEX_0;
                            layerReadAddr = 524287; // 2^19 max value
                            weightReadAddr = 1023;  // 2^10 max value
                            biasReadAddr = 0;
                            bias_start_flag = 0;

                            weight_count = 0;
                            depth_count = 0;
                            weight_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            // load data
                            get_weight_number = 0;
                            get_bias_number = 0;
                            get_fm_number = 0;

                            writeOutputLayerData = 0;
                            writeOutputLayerAddr = 524287; // 2^19 max value
                            
                            mul_clk_count = 0;
                            write_to_layer_ram_count = 0;
                            update_kernel_clk_count = 0;

                            current_weight = 0;

                            conv_temp_result = 0;

                            multEna = 1;
                            multRst = 0;
                        end
                        else begin
                            multEna = 1;
                            multRst = 1;

                            if(update_kernel_clk_count == 1) begin
                                if(updateWeightDone == 1) begin
                                    updateWeight = 0;
                                end

                                if(updateBiasDone == 1) begin
                                    updateBias = 0;
                                end

                                if((updateWeight == 0) && (updateBias == 0)) begin
                                    update_kernel_clk_count = 0;    
                                end
                            end

                            if(weight_count < `CONV4_KERNERL_NUMBER) begin             // loop 4
                                if(fm_y < (`CONV4_FM - `CONV4_KERNERL + 1)) begin      // loop 3, fm_y = fm_y + stride
                                    if(fm_x < (`CONV4_FM - `CONV4_KERNERL + 1)) begin  // loop 3, fm_x = fm_x + stride
                                        if(depth_count < `CONV4_FM_DEPTH) begin        // loop 2
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
                                            end
                                            else begin  
                                                get_bias_number = get_bias_number + 1;
                                            end

                                            // read weight data
                                            if(get_weight_number < 1) begin                                                    
                                                if (current_weight == 0) begin      // start to read the first weight
                                                    weightReadAddr = `WEIGHT_RAM_START_INDEX_0;
                                                    current_weight = 1;
                                                end
                                                else if(current_weight == 1) begin  // reading the first weight
                                                    weightReadAddr = weightReadAddr + 1;  
                                                end
                                                else if (current_weight == 2) begin // start to read the second weight
                                                    weightReadAddr = `WEIGHT_RAM_START_INDEX_1;
                                                    current_weight = 3;
                                                end
                                                else if(current_weight == 3) begin // reading the second weight
                                                    weightReadAddr = weightReadAddr + 1;
                                                end

                                                get_weight_number = 1;
                                            end
                                            else if(get_weight_number == 3) begin // get read value 
                                                weight_window[0]  = {128'b0, readWeight[`DATA_WIDTH * `CONV4_KERNERL - 1 :0]};
                                                weight_window[1]  = {128'b0, readWeight[`DATA_WIDTH * `CONV4_KERNERL * 2  - 1:`DATA_WIDTH * `CONV4_KERNERL]};
                                                weight_window[2]  = {128'b0, readWeight[`DATA_WIDTH * `CONV4_KERNERL * 3  - 1:`DATA_WIDTH * `CONV4_KERNERL * 2]};
                                            end
                                            else begin 
                                                get_weight_number = get_weight_number + 1;
                                            end

                                            // read feature map part data
                                            if(get_fm_number < (`CONV4_KERNERL * `CONV4_KERNERL)) begin
                                                if(layerReadAddr == 524287) // the beginning
                                                    layerReadAddr = inputLayerStartIndex;

                                                else if(get_fm_number > 0 && ((get_fm_number) % `CONV4_KERNERL) == 0) // go to next line
                                                    layerReadAddr = layerReadAddr + `CONV4_FM - (`CONV4_KERNERL - 1);
                                                else
                                                    layerReadAddr = layerReadAddr + 1;

                                                get_fm_number = get_fm_number + 1;

                                                if (get_fm_number >= 4) begin
                                                    fm[get_fm_number - 4] = readFM;
                                                end

                                            end
                                            else if(get_fm_number < (`CONV4_KERNERL * `CONV4_KERNERL + 3)) begin
                                                get_fm_number = get_fm_number + 1;
                                                fm[get_fm_number - 4] = readFM;
                                            end

                                            // kernel(weight and bias) is ready and do the conv
                                            if(    get_bias_number == 3 
                                                && get_weight_number == 3
                                                && get_fm_number == (`CONV4_KERNERL * `CONV4_KERNERL + 3)) begin

                                                if(weight_line_count < `CONV4_KERNERL) begin
                                                    // multX11
                                                    i = weight_line_count * `CONV4_KERNERL;
                                                    multData = {128'b0, fm[i+2], fm[i+1], fm[i]}; // 8*16 = 128
                                                    multWeight = weight_window[weight_line_count]; 
                                                    weight_line_count = weight_line_count + 1;   
                                                end

                                                // wait 10 clk and add
                                                if(mul_clk_count < 11) begin
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                if((mul_clk_count >= 11) && (mul_clk_count < 15)) begin
                                                    addAValid = 1;
                                                    addBValid = 1;
                                                    addA = multResult;
                                                    addB = addResult;
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                else if(mul_clk_count == 15) begin
                                                    addA = conv_temp_result;
                                                    addB = addResult;
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                else if(mul_clk_count == 16) begin
                                                    // save the temp result
                                                    conv_temp_result = addResult;
                                                    multData = 0;
                                                    multWeight = 0;
                                                    addA = 0;
                                                    addB = 0;

                                                    // go to next depth
                                                    depth_count = depth_count + 1;
                                                    get_weight_number = 0;
                                                    get_fm_number = 0;
                                                    weight_line_count = 0;
                                                    mul_clk_count = 0;

                                                    // next depth address
                                                    // the last -1: when read fm data, it will +1
                                                    if(depth_count < `CONV4_FM_DEPTH) begin
                                                        layerReadAddr = inputLayerStartIndex + depth_count * `CONV4_FM * `CONV4_FM + fm_x + fm_y * `CONV4_FM - 1;
                                                    end
                                                end       
                                            end
                                        end
                                        else begin
                                            // finish a kernel conv, add bias, and write to layer ram
                                            addAValid = 1;
                                            addBValid = 1;

                                            addA = bias;
                                            addB = conv_temp_result; 

                                            // write addResult to layer RAM  
                                            if(write_to_layer_ram_count == 0) begin
                                                write_to_layer_ram_count = 1;
                                            end
                                            else if(write_to_layer_ram_count == 1) begin // write data
                                                writeOutputLayerData = addResult;

                                                conv_temp_result = 0;
                                                
                                                addA = 0;
                                                addB = 0;

                                                if(writeOutputLayerAddr == 524287) begin
                                                    writeOutputLayerAddr = outputLayerStartIndex;
                                                end
                                                else begin
                                                    writeOutputLayerAddr = writeOutputLayerAddr + 1;
                                                end

                                                write_to_layer_ram_count = 0;

                                                depth_count = 0;
                                                // go to next feature map part data
                                                fm_x = fm_x + `CONV4_STRIDE;
                                                get_fm_number = 0;
                                                layerReadAddr = inputLayerStartIndex + fm_x + fm_y * `CONV4_FM - 1;

                                                get_weight_number = 0;
                                                
                                                if(current_weight == 0 || current_weight == 1) begin
                                                    current_weight = 0;
                                                end
                                                else if(current_weight == 2 || current_weight == 3) begin
                                                    current_weight = 2;
                                                end
                                                
                                            end
                                        end
                                    end
                                    else begin // go to next fm matrix line
                                        if(current_weight == 0 || current_weight == 1) begin
                                            current_weight = 0;
                                        end
                                        else if(current_weight == 2 || current_weight == 3) begin
                                            current_weight = 2;
                                        end

                                        depth_count = 0;
                                        weight_line_count = 0;

                                        fm_x = 0;
                                        fm_y = fm_y + `CONV4_STRIDE;
                                        layerReadAddr = inputLayerStartIndex + fm_x + fm_y * `CONV4_FM - 1;

                                        get_weight_number = 0;
                                        get_fm_number = 0;

                                        mul_clk_count = 0;
                                        write_to_layer_ram_count = 0;
                                        
                                    end
                                end
                                else begin // go to next kernel
                                    
                                    layerReadAddr = 524287; // the beginning //layerReadAddr = inputLayerStartIndex;

                                    // change to another kernel
                                    if(current_weight == 0 || current_weight == 1) begin
                                        current_weight = 2;
                                    end
                                    else if(current_weight == 2 || current_weight == 3) begin
                                        current_weight = 0;
                                    end

                                    weight_count = weight_count + 1;
                                    depth_count = 0;
                                    weight_line_count = 0;

                                    fm_x = 0;
                                    fm_y = 0;

                                    get_weight_number = 0;
                                    get_bias_number = 0;
                                    get_fm_number = 0;

                                    if(update_kernel_clk_count == 0) begin
                                        // update weight
                                        updateWeight = 1;
                                        if(current_weight == 0) 
                                            updateWeightAddr = `WEIGHT_RAM_START_INDEX_1;
                                        else if(current_weight == 2)
                                            updateWeightAddr = `WEIGHT_RAM_START_INDEX_0;

                                        // update bias
                                        updateBias = 1;
                                        updateBiasAddr = biasReadAddr;

                                        update_kernel_clk_count = 1;
                                    end
                                        
                                end
                            end
                            else begin
                                convStatus = 1;
                            end
                        end
                    end
                CONV5:
                    begin
                        if(currentLayer != runLayer) begin
                            convStatus = 0;
                            currentLayer = runLayer;

                            inputLayerStartIndex = `LAYER_RAM_START_INDEX_0;
                            outputLayerStartIndex = `LAYER_RAM_START_INDEX_1;
                            layerReadAddr = 524287; // 2^19 max value
                            weightReadAddr = 1023;  // 2^10 max value
                            biasReadAddr = 0;
                            bias_start_flag = 0;

                            weight_count = 0;
                            depth_count = 0;
                            weight_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            // load data
                            get_weight_number = 0;
                            get_bias_number = 0;
                            get_fm_number = 0;

                            writeOutputLayerData = 0;
                            writeOutputLayerAddr = 524287; // 2^19 max value
                            
                            mul_clk_count = 0;
                            write_to_layer_ram_count = 0;
                            update_kernel_clk_count = 0;

                            current_weight = 0;

                            conv_temp_result = 0;

                            multEna = 1;
                            multRst = 0;
                        end
                        else begin
                            multEna = 1;
                            multRst = 1;

                            if(update_kernel_clk_count == 1) begin
                                if(updateWeightDone == 1) begin
                                    updateWeight = 0;
                                end

                                if(updateBiasDone == 1) begin
                                    updateBias = 0;
                                end

                                if((updateWeight == 0) && (updateBias == 0)) begin
                                    update_kernel_clk_count = 0;    
                                end
                            end

                            if(weight_count < `CONV5_KERNERL_NUMBER) begin             // loop 4
                                if(fm_y < (`CONV5_FM - `CONV5_KERNERL + 1)) begin      // loop 3, fm_y = fm_y + stride
                                    if(fm_x < (`CONV5_FM - `CONV5_KERNERL + 1)) begin  // loop 3, fm_x = fm_x + stride
                                        if(depth_count < `CONV5_FM_DEPTH) begin        // loop 2
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
                                            end
                                            else begin  
                                                get_bias_number = get_bias_number + 1;
                                            end

                                            // read weight data
                                            if(get_weight_number < 1) begin                                                    
                                                if (current_weight == 0) begin      // start to read the first weight
                                                    weightReadAddr = `WEIGHT_RAM_START_INDEX_0;
                                                    current_weight = 1;
                                                end
                                                else if(current_weight == 1) begin  // reading the first weight
                                                    weightReadAddr = weightReadAddr + 1;  
                                                end
                                                else if (current_weight == 2) begin // start to read the second weight
                                                    weightReadAddr = `WEIGHT_RAM_START_INDEX_1;
                                                    current_weight = 3;
                                                end
                                                else if(current_weight == 3) begin // reading the second weight
                                                    weightReadAddr = weightReadAddr + 1;
                                                end

                                                get_weight_number = 1;
                                            end
                                            else if(get_weight_number == 3) begin // get read value 
                                                weight_window[0]  = {128'b0, readWeight[`DATA_WIDTH * `CONV5_KERNERL - 1 :0]};
                                                weight_window[1]  = {128'b0, readWeight[`DATA_WIDTH * `CONV5_KERNERL * 2  - 1:`DATA_WIDTH * `CONV5_KERNERL]};
                                                weight_window[2]  = {128'b0, readWeight[`DATA_WIDTH * `CONV5_KERNERL * 3  - 1:`DATA_WIDTH * `CONV5_KERNERL * 2]};
                                            end
                                            else begin 
                                                get_weight_number = get_weight_number + 1;
                                            end

                                            // read feature map part data
                                            if(get_fm_number < (`CONV5_KERNERL * `CONV5_KERNERL)) begin
                                                if(layerReadAddr == 524287) // the beginning
                                                    layerReadAddr = inputLayerStartIndex;

                                                else if(get_fm_number > 0 && ((get_fm_number) % `CONV5_KERNERL) == 0) // go to next line
                                                    layerReadAddr = layerReadAddr + `CONV5_FM - (`CONV5_KERNERL - 1);
                                                else
                                                    layerReadAddr = layerReadAddr + 1;

                                                get_fm_number = get_fm_number + 1;

                                                if (get_fm_number >= 4) begin
                                                    fm[get_fm_number - 4] = readFM;
                                                end

                                            end
                                            else if(get_fm_number < (`CONV5_KERNERL * `CONV5_KERNERL + 3)) begin
                                                get_fm_number = get_fm_number + 1;
                                                fm[get_fm_number - 4] = readFM;
                                            end

                                            // kernel(weight and bias) is ready and do the conv
                                            if(    get_bias_number == 3 
                                                && get_weight_number == 3
                                                && get_fm_number == (`CONV5_KERNERL * `CONV5_KERNERL + 3)) begin

                                                if(weight_line_count < `CONV5_KERNERL) begin
                                                    // multX11
                                                    i = weight_line_count * `CONV5_KERNERL;
                                                    multData = {128'b0, fm[i+2], fm[i+1], fm[i]}; // 8*16 = 128
                                                    multWeight = weight_window[weight_line_count]; 
                                                    weight_line_count = weight_line_count + 1;   
                                                end

                                                // wait 10 clk and add
                                                if(mul_clk_count < 11) begin
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                if((mul_clk_count >= 11) && (mul_clk_count < 15)) begin
                                                    addAValid = 1;
                                                    addBValid = 1;
                                                    addA = multResult;
                                                    addB = addResult;
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                else if(mul_clk_count == 15) begin
                                                    addA = conv_temp_result;
                                                    addB = addResult;
                                                    mul_clk_count = mul_clk_count + 1;
                                                end
                                                else if(mul_clk_count == 16) begin
                                                    // save the temp result
                                                    conv_temp_result = addResult;
                                                    multData = 0;
                                                    multWeight = 0;
                                                    addA = 0;
                                                    addB = 0;

                                                    // go to next depth
                                                    depth_count = depth_count + 1;
                                                    get_weight_number = 0;
                                                    get_fm_number = 0;
                                                    weight_line_count = 0;
                                                    mul_clk_count = 0;

                                                    // next depth address
                                                    // the last -1: when read fm data, it will +1
                                                    if(depth_count < `CONV5_FM_DEPTH) begin
                                                        layerReadAddr = inputLayerStartIndex + depth_count * `CONV5_FM * `CONV5_FM + fm_x + fm_y * `CONV5_FM - 1;
                                                    end
                                                end       
                                            end
                                        end
                                        else begin
                                            // finish a kernel conv, add bias, and write to layer ram
                                            addAValid = 1;
                                            addBValid = 1;

                                            addA = bias;
                                            addB = conv_temp_result; 

                                            // write addResult to layer RAM  
                                            if(write_to_layer_ram_count == 0) begin
                                                write_to_layer_ram_count = 1;
                                            end
                                            else if(write_to_layer_ram_count == 1) begin // write data
                                                writeOutputLayerData = addResult;

                                                conv_temp_result = 0;
                                                
                                                addA = 0;
                                                addB = 0;

                                                if(writeOutputLayerAddr == 524287) begin
                                                    writeOutputLayerAddr = outputLayerStartIndex;
                                                end
                                                else begin
                                                    writeOutputLayerAddr = writeOutputLayerAddr + 1;
                                                end

                                                write_to_layer_ram_count = 0;

                                                depth_count = 0;
                                                // go to next feature map part data
                                                fm_x = fm_x + `CONV5_STRIDE;
                                                get_fm_number = 0;
                                                layerReadAddr = inputLayerStartIndex + fm_x + fm_y * `CONV5_FM - 1;

                                                get_weight_number = 0;
                                                
                                                if(current_weight == 0 || current_weight == 1) begin
                                                    current_weight = 0;
                                                end
                                                else if(current_weight == 2 || current_weight == 3) begin
                                                    current_weight = 2;
                                                end
                                                
                                            end
                                        end
                                    end
                                    else begin // go to next fm matrix line
                                        if(current_weight == 0 || current_weight == 1) begin
                                            current_weight = 0;
                                        end
                                        else if(current_weight == 2 || current_weight == 3) begin
                                            current_weight = 2;
                                        end

                                        depth_count = 0;
                                        weight_line_count = 0;

                                        fm_x = 0;
                                        fm_y = fm_y + `CONV5_STRIDE;
                                        layerReadAddr = inputLayerStartIndex + fm_x + fm_y * `CONV5_FM - 1;

                                        get_weight_number = 0;
                                        get_fm_number = 0;

                                        mul_clk_count = 0;
                                        write_to_layer_ram_count = 0;
                                        
                                    end
                                end
                                else begin // go to next kernel
                                    
                                    layerReadAddr = 524287; // the beginning //layerReadAddr = inputLayerStartIndex;

                                    // change to another kernel
                                    if(current_weight == 0 || current_weight == 1) begin
                                        current_weight = 2;
                                    end
                                    else if(current_weight == 2 || current_weight == 3) begin
                                        current_weight = 0;
                                    end

                                    weight_count = weight_count + 1;
                                    depth_count = 0;
                                    weight_line_count = 0;

                                    fm_x = 0;
                                    fm_y = 0;

                                    get_weight_number = 0;
                                    get_bias_number = 0;
                                    get_fm_number = 0;

                                    if(update_kernel_clk_count == 0) begin
                                        // update weight
                                        updateWeight = 1;
                                        if(current_weight == 0) 
                                            updateWeightAddr = `WEIGHT_RAM_START_INDEX_1;
                                        else if(current_weight == 2)
                                            updateWeightAddr = `WEIGHT_RAM_START_INDEX_0;

                                        // update bias
                                        updateBias = 1;
                                        updateBiasAddr = biasReadAddr;

                                        update_kernel_clk_count = 1;
                                    end
                                        
                                end
                            end
                            else begin
                                convStatus = 1;
                            end
                        end
                    end
                POOL5:
                    begin
                        if(currentLayer != runLayer) begin // initial
                            poolStatus = 0;
                            currentLayer = runLayer;

                            inputLayerStartIndex = `LAYER_RAM_START_INDEX_1;
                            outputLayerStartIndex = `LAYER_RAM_START_INDEX_0;
                            layerReadAddr = 524287; // 2^19 max value

                            depth_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            // load data
                            get_fm_number = 0;

                            writeOutputLayerData = 0;
                            writeOutputLayerAddr = 524287; // 2^19 max value

                            pool_clk_count = 0;

                            maxpoolEna = 1;
                            maxpoolRst = 0;
                        end
                        else begin
                            maxpoolEna = 1;
                            maxpoolRst = 1;

                            if(depth_count < `POOL5_DEPTH) begin 
                                if(fm_y < (`POOL5_FM - `POOL5_WINDOW + 1)) begin
                                    if(fm_x < (`POOL5_FM - `POOL5_WINDOW + 1)) begin
                                        // read feature map part data
                                        if(get_fm_number < `POOL5_WINDOW_SIZE) begin
                                            if(layerReadAddr == 524287) begin// the beginning
                                                layerReadAddr = inputLayerStartIndex;
                                            end
                                            else if(get_fm_number > 0 && ((get_fm_number) % `POOL5_WINDOW) == 0) // go to next line
                                                layerReadAddr = layerReadAddr + `POOL5_FM - (`POOL5_WINDOW - 1);
                                            else
                                                layerReadAddr = layerReadAddr + 1;

                                            get_fm_number = get_fm_number + 1;

                                            if (get_fm_number >= 4) begin
                                                fm[get_fm_number - 4] = readFM;
                                            end

                                        end
                                        else if(get_fm_number < (`POOL5_WINDOW_SIZE + 3)) begin
                                            get_fm_number = get_fm_number + 1;
                                            fm[get_fm_number - 4] = readFM;
                                        end

                                        // max pool
                                        if(get_fm_number == (`POOL5_WINDOW_SIZE + 3)) begin
                                            maxpoolIn = {fm[8], fm[7], fm[6], fm[5], fm[4], fm[3], fm[2], fm[1], fm[0]};

                                            // get max pool result
                                            if(pool_clk_count < 6) begin
                                                pool_clk_count = pool_clk_count + 1;
                                            end
                                            else begin
                                                if(writeOutputLayerAddr == 524287) begin
                                                    writeOutputLayerAddr = outputLayerStartIndex;
                                                end
                                                else begin
                                                    writeOutputLayerAddr = writeOutputLayerAddr + 1;
                                                end

                                                writeOutputLayerData = maxpoolOut;

                                                pool_clk_count = 0;

                                                // go to next feature map part data
                                                fm_x = fm_x + `POOL5_STRIDE;
                                                get_fm_number = 0;
                                                layerReadAddr = inputLayerStartIndex + depth_count * `POOL5_FM_DATA + fm_x + fm_y * `POOL5_FM - 1;
                                            end
                                        end
                                    end
                                    else begin
                                        pool_clk_count = 0;

                                        // go to next fm matrix line
                                        fm_x = 0;
                                        fm_y = fm_y + `POOL5_STRIDE;
                                        layerReadAddr = inputLayerStartIndex + depth_count * `POOL5_FM_DATA + fm_y * `POOL5_FM - 1;
                                    end
                                end
                                else begin
                                    // go to next depth
                                    fm_x = 0;
                                    fm_y = 0;
                                    depth_count = depth_count + 1;
                                    layerReadAddr = inputLayerStartIndex + depth_count * `POOL5_FM_DATA - 1;
                                end
                            end
                            else begin
                                poolStatus = 1;
                            end
                        end
                    end
                FC6:
                    begin
                        if(currentLayer != runLayer) begin // initial
                            fcStatus = 0;
                            currentLayer = runLayer;

                            inputLayerStartIndex = `LAYER_RAM_START_INDEX_0;
                            outputLayerStartIndex = `LAYER_RAM_START_INDEX_1;

                            layerReadAddr = 524287; // 2^19 max value
                            weightReadAddr = 1023;  // 2^10 max value
                            biasReadAddr = 0;
                            bias_start_flag = 0;

                            weight_count = 0;

                            // load data
                            get_weight_number = 0;
                            get_bias_number = 0;
                            get_fm_number = 0;

                            writeOutputLayerData = 0;
                            writeOutputLayerAddr = 524287; // 2^19 max value  

                            fc_fm_count = 0;
                            update_kernel_clk_count = 0;

                            current_weight = 0;
                        end
                        else begin
                            if(update_kernel_clk_count == 1) begin
                                if(updateWeightDone == 1) begin
                                    updateWeight = 0;
                                end

                                if(updateBiasDone == 1) begin
                                    updateBias = 0;
                                end

                                if((updateWeight == 0) && (updateBias == 0)) begin
                                    update_kernel_clk_count = 0;
                                end
                            end

                            if(weight_count < `FC6_KERNEL_NUMBER) begin
                                if(fc_fm_count < `FC6_FM_SIZE) begin
                                    // todo

                                end
                                else begin
                                    // goto next kernel
                                    layerReadAddr = 524287;

                                    // change to another kernel
                                    if(current_weight == 0 || current_weight == 1) begin
                                        current_weight = 2;
                                    end
                                    else if(current_weight == 2 || current_weight == 3) begin
                                        current_weight = 0;
                                    end

                                    weight_count = weight_count + 1;
                                    fc_fm_count = 0;

                                    get_weight_number = 0;
                                    get_bias_number = 0;
                                    get_fm_number = 0;

                                    if(update_kernel_clk_count == 0) begin
                                        // update weight
                                        updateWeight = 1;
                                        if(current_weight == 0) begin
                                            updateWeightAddr = `WEIGHT_RAM_START_INDEX_1;
                                        end
                                        else if(current_weight == 2) begin
                                            updateWeightAddr = `WEIGHT_RAM_START_INDEX_0;
                                        end

                                        // update bias
                                        updateBias = 1;
                                        updateBiasAddr = biasReadAddr;

                                        update_kernel_clk_count = 1;
                                    end
                                end
                            end
                            else begin
                                fcStatus = 1;
                            end
                        end
                    end 
                FC7:
                    begin
                        currentLayer = runLayer;
                    end 
                FC8:
                    begin
                        currentLayer = runLayer;
                    end     
            endcase
        end
    end
    
endmodule