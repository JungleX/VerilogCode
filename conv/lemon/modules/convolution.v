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

    input [1935:0] readWeight,
    input [15:0] readBias,
    input [15:0] readFM,

    input [15:0] addResult,

    input [15:0] multResult,

    output reg [`CONV_MAX_LINE_SIZE - 1:0] multData,
    output reg [`CONV_MAX_LINE_SIZE - 1:0] multWeight,

    output reg [15:0] addA,
    output reg [15:0] addB,

	output reg [18:0] layerReadAddr,     // read address of layer RAM
    output reg [9:0] weightReadAddr,     // read address of weight RAM
    output reg biasReadAddr,             // read address of bias RAM

    output reg [15:0] writeLayerData,
    output reg [18:0] writeLayerAddr,

   	output reg convStatus                // conv status, 0:idle or running; 1:done, done means the conv finish and output data is ready
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

    reg [3:0] currentLayer;
    reg [18:0] inputStartIndex;
    reg [18:0] outputStartIndex;
    
    reg [8:0] kernel_count;       // max value 384 < 512=2^9
    reg [8:0] kernel_depth_count; // max value 384 < 512=2^9
    reg [3:0] kernel_line_count;  // max value 11 < 16=2^4

    reg [7:0] fm_x;
    reg [7:0] fm_y;

    reg [8:0] get_weight; // max value 384 < 512=2^9
    reg get_bias; 
    reg [11:0] get_fm;     // max value 3*3*384=3456 < 4096=2^12

    reg [175:0] weight[4223:0]; // max line 11*16=176, 11*384 = 4224
    reg [15:0] bias;
    reg [15:0] fm[3455:0]; // 3*3*384=3456 

    reg [11:0]i;

    always @(posedge clk or posedge convRst) begin
        if(!convRst) begin // reset
            convStatus = 0;
            currentLayer = IDLE;

            kernel_count = 0;
            kernel_depth_count = 0;
            kernel_line_count = 0;

            fm_x = 0;
            fm_y = 0;

            get_weight = 0;
            get_bias = 0;
            get_fm = 0;

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

                    		inputStartIndex = `LAYER_RAM_START_INDEX_0;
                            outputStartIndex = `LAYER_RAM_START_INDEX_1;
                    		weightReadAddr = 0;
                    		biasReadAddr = 0;
                            convStatus = 0;

                            kernel_count = 0;
                            kernel_depth_count = 0;
                            kernel_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            get_weight = 0;
                            get_bias = 0;
                            get_fm = 0;

                            layerReadAddr = inputStartIndex;
                            weightReadAddr = 0;
                            biasReadAddr = 0;

                            writeLayerAddr = outputStartIndex;
                    	end
                        else begin
                            if(kernel_count < `CONV2_FM_DEPTH) begin // todo
                                // read bias data
                                if(get_bias < 1) begin
                                    bias = readBias;
                                    get_bias = 1;
                                    if(biasReadAddr == 0)
                                        biasReadAddr = 1;
                                    else
                                        biasReadAddr = 0;
                                end

                                // read weight data
                                if(get_weight<`CONV1_FM_DEPTH) begin
                                    weight[get_weight]        = readWeight[`DATA_WIDTH * `CONV1_KERNERL - 1    :0];
                                    weight[get_weight+1]      = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 2  - 1:`DATA_WIDTH * `CONV1_KERNERL];
                                    weight[get_weight+2]      = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 3  - 1:`DATA_WIDTH * `CONV1_KERNERL * 2];
                                    weight[get_weight+3]      = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 4  - 1:`DATA_WIDTH * `CONV1_KERNERL * 3];
                                    weight[get_weight+4]      = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 5  - 1:`DATA_WIDTH * `CONV1_KERNERL * 4];
                                    weight[get_weight+5]      = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 6  - 1:`DATA_WIDTH * `CONV1_KERNERL * 5];
                                    weight[get_weight+6]      = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 7  - 1:`DATA_WIDTH * `CONV1_KERNERL * 6];
                                    weight[get_weight+7]      = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 8  - 1:`DATA_WIDTH * `CONV1_KERNERL * 7];
                                    weight[get_weight+8]      = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 9  - 1:`DATA_WIDTH * `CONV1_KERNERL * 8];
                                    weight[get_weight+9]      = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 10 - 1:`DATA_WIDTH * `CONV1_KERNERL * 9];
                                    weight[get_weight+10]     = readWeight[`DATA_WIDTH * `CONV1_KERNERL * 11 - 1:`DATA_WIDTH * `CONV1_KERNERL * 10];

                                    get_weight = get_weight + 1;
                                    
                                    weightReadAddr = weightReadAddr + 1;
                                    if(weightReadAddr == `WEIGHT_RAM_START_INDEX_1 + `CONV1_FM_DEPTH) begin
                                        weightReadAddr = `WEIGHT_RAM_START_INDEX_0;
                                    end
                                    else if(weightReadAddr == `CONV1_FM_DEPTH) begin
                                        weightReadAddr = `WEIGHT_RAM_START_INDEX_1;
                                    end
                                        
                                end
                                
                                // read feature map part data
                                if(get_fm<(`CONV1_KERNERL * `CONV1_KERNERL * `CONV1_FM_DEPTH)) begin
                                    fm[get_fm] = readFM;
                                    get_fm = get_fm + 1;

                                    if((get_fm % `CONV1_KERNERL) == 0) begin
                                        layerReadAddr = layerReadAddr + `CONV1_FM;
                                    end
                                    else 
                                        layerReadAddr = layerReadAddr + 1;

                                end

                                // kernel(weight and bias) is ready and do the conv
                                if(    get_bias == 1 
                                    && get_weight == `CONV1_FM_DEPTH
                                    && get_fm == (`CONV1_KERNERL * `CONV1_KERNERL * `CONV1_FM_DEPTH)) begin

                                    // feature map loop
                                    if(fm_y<=(`CONV1_FM - `CONV1_KERNERL)) begin
                                        if(fm_x<=(`CONV1_FM - `CONV1_KERNERL)) begin

                                            if(kernel_depth_count < `CONV1_FM_DEPTH) begin
                                                if(kernel_line_count < `CONV1_KERNERL) begin
                                                    // multX11
                                                    i = kernel_depth_count * `CONV1_KERNERL * `CONV1_KERNERL + kernel_line_count * `CONV1_KERNERL;
                                                    multData = {fm[i+10], fm[i+9], fm[i+8], fm[i+7], fm[i+6], fm[i+5], fm[i+4], fm[i+3], fm[i+2], fm[i+1], fm[i]};
                                                    multWeight = weight[kernel_line_count];
                                                    kernel_line_count = kernel_line_count + 1;

                                                    // wait 10 clk and add
                                                    addA = multResult;
                                                    addB = bias;

                                                end
                                                else begin
                                                    // add 

                                                    // go to next depth
                                                    kernel_line_count = 0;
                                                    kernel_depth_count = kernel_depth_count + 1;
                                                end
                                            
                                            end
                                            else begin
                                                // write addResult to layer RAM  
                                                writeLayerData = addResult;
                                                if () begin
                                                    
                                                end
                                                else begin
                                                    writeLayerAddr = writeLayerAddr + 1;
                                                end

                                                // go to next feature map part data
                                                fm_x = fm_x + `CONV1_STRIDE;
                                                get_fm = 0;

                                                kernel_depth_count = 0;
                                                kernel_count = kernel_count + 1;
                                                layerReadAddr = fm_x + fm_y * `CONV1_FM ;
                                            end
                                        end
                                        else begin
                                            fm_x = 0;
                                            fm_y = fm_y + `CONV1_STRIDE;
                                        end
                                    end
                                    else begin
                                        // conv1 done
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
                        currentLayer = runLayer;
                    end 
                CONV2:
                    begin
                        if(currentLayer != runLayer) begin
                            currentLayer = runLayer;

                            inputStartIndex = `LAYER_RAM_START_INDEX_0;
                            outputStartIndex = `LAYER_RAM_START_INDEX_1;
                            weightReadAddr = 0;
                            biasReadAddr = 0;
                            convStatus = 0;

                            kernel_count = 0;
                            kernel_depth_count = 0;
                            kernel_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;


                            writeLayerAddr = 0;

                            get_weight = 0;
                            get_bias = 0;
                            get_fm = 0;
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

                            inputStartIndex = `LAYER_RAM_START_INDEX_0;
                            outputStartIndex = `LAYER_RAM_START_INDEX_1;
                            weightReadAddr = 0;
                            biasReadAddr = 0;
                            convStatus = 0;

                            kernel_count = 0;
                            kernel_depth_count = 0;
                            kernel_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            writeLayerAddr = 0;

                            get_weight = 0;
                            get_bias = 0;
                            get_fm = 0;
                        end
                    end
                CONV4:
                    begin
                        if(currentLayer != runLayer) begin
                            currentLayer = runLayer;

                            inputStartIndex = `LAYER_RAM_START_INDEX_1;
                            outputStartIndex = `LAYER_RAM_START_INDEX_0;
                            weightReadAddr = 0;
                            biasReadAddr = 0;
                            convStatus = 0;

                            kernel_count = 0;
                            kernel_depth_count = 0;
                            kernel_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            writeLayerAddr = 0;

                            get_weight = 0;
                            get_bias = 0;
                            get_fm = 0;
                        end
                    end
                CONV5:
                    begin
                        if(currentLayer != runLayer) begin
                            currentLayer = runLayer;

                            inputStartIndex = `LAYER_RAM_START_INDEX_0;
                            outputStartIndex = `LAYER_RAM_START_INDEX_1;
                            weightReadAddr = 0;
                            biasReadAddr = 0;
                            convStatus = 0;

                            kernel_count = 0;
                            kernel_depth_count = 0;
                            kernel_line_count = 0;

                            fm_x = 0;
                            fm_y = 0;

                            writeLayerAddr = 0;

                            get_weight = 0;
                            get_bias = 0;
                            get_fm = 0;
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
