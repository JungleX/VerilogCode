`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/06/14 10:33:26
// Design Name: 
// Module Name: alexnet_model
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

module alexnet_model(
	input clk,
	input modelRst,

	output reg [9:0] runLayer,

	input writeInitDone,

	output reg writeFM,
	output reg [`DATA_WIDTH - 1:0] writeFMData,
	output reg [31:0] writeFMAddr,
	input writeFMDone,
	
	output reg updateKernel,
	output reg updateKernelNumber,
	input updateKernelDone,

	output reg FMReadEn,
	input [`DATA_WIDTH - 1:0] FMReadData,
	output reg [31:0] FMReadAddr,

	output reg weightReadEn,
	input [`DATA_WIDTH - 1:0] weightReadData,
	output reg [31:0] weightReadAddr,

	output reg biasReadEn,
	input [`DATA_WIDTH - 1:0] biasReadData,
	output reg biasReadAddr
    );

	parameter   IDLE  = 10'd0,

                CONV1 = 10'd1,  
                CONV2 = 10'd2, 
                CONV3 = 10'd3,  
                CONV4 = 10'd4,  
                CONV5 = 10'd5,

                POOL1 = 10'd6,
                POOL2 = 10'd7,
                POOL5 = 10'd8,

                FC6   = 10'd9,
                FC7   = 10'd10,
                FC8   = 10'd11; 

    reg [9:0] currentLayer;

    reg [31:0] input_fm_start_index;
    reg [31:0] output_fm_start_index;
        
    reg [8:0] kernel_count;       // loop 4, max value 384 < 512=2^9, the kernel number
    reg [8:0] depth_count;        // loop 2, max value 384 < 512=2^9, count the input feature map depth
    reg [3:0] weight_matrix_count;  // loop 1, max value 11 < 16=2^4, the kernel matrix line
    reg [13:0] fm_matrix_count;

    reg [5:0] padding_up;
    reg [5:0] padding_down;
    reg [5:0] padding_left;
    reg [5:0] padding_right;

    reg [5:0] padding_up_count;
    reg [5:0] padding_down_count;
    reg [5:0] padding_left_count;
    reg [5:0] padding_right_count;

    reg [8:0] kernel_number;
    reg [8:0] depth_number;
    reg [6:0] weight_matrix_number;
    reg [3:0] pool_matrix_number;
    reg [13:0] fm_matrix_number;

    reg [7:0] fm_x;               // loop 3, max value 227 < 256=2^8, the fm matrix start location
    reg [7:0] fm_y;  

    reg [7:0] fm_x_max;
    reg [7:0] fm_y_max;

    reg [7:0] fm_size;
    reg [3:0] weight_size;
    reg [2:0] stride;
    reg [2:0] pool_size;

    reg [11:0] get_weight_number; 
    reg [1:0]  get_bias_number;         // count the bias number, get only one bias each time
    reg [11:0] get_fm_number;           // max value 3*3*384=3456 < 4096=2^12, count the fm matrix number

    reg [11:0] set_fm_count;

    reg [`DATA_WIDTH - 1:0] bias;
    reg [`DATA_WIDTH - 1:0] fm[120:0];               // 11*11=121 max value
    reg [`DATA_WIDTH - 1:0] weight[120:0];    
 
 	reg read_fm_start;
 	reg read_weight_start;
 	reg read_bias_start;

 	reg write_fm_start;

    reg [4:0] mult_clk_count;
    reg bias_add_clk_count;

    reg [1:0] current_weight; // 0: 1 weight start; 1: 1 weight running; 2: 2 weight start; 3: 2 weight running

    reg [4:0] pool_clk_count;

    reg [13:0] fc_clk_count; // 2^14=16384

    reg [`DATA_WIDTH - 1:0] conv_temp_result;
    reg [`DATA_WIDTH - 1:0] fc_temp_result;
    
    reg [11:0] i;
    reg [11:0] j;
    reg [11:0] k;

    reg [3:0] update_kernel_clk_count;

	reg conv_status;
	reg pool_status;
	reg fc_status;

	// mult 11*11
	reg multRst;
    reg multEna;
    reg [`CONV_MAX_LINE_SIZE - 1:0] multData;
    reg [`CONV_MAX_LINE_SIZE - 1:0] multWeight;
    wire [`DATA_WIDTH - 1:0] multResult;

	multX11 mult(
        .clk(clk),
        .rst(multRst),
        .ena(multEna),

        .data(multData),
        .weight(multWeight),

        .out(multResult)
    );

	// adder
	wire addResultValid;
    reg addAValid;
    reg addBValid;

    reg [`DATA_WIDTH - 1:0] addA;
    reg [`DATA_WIDTH - 1:0] addB;
    wire [`DATA_WIDTH - 1:0] addResult;

    floating_point_add adder(
        .s_axis_a_tvalid(addAValid),
        .s_axis_a_tdata(addA),

        .s_axis_b_tvalid(addBValid),
        .s_axis_b_tdata(addB),

        .m_axis_result_tvalid(addResultValid),
        .m_axis_result_tdata(addResult)
    );

    // max pool 3*3
    reg maxpoolRst;
    reg maxpoolEna;
    reg [`POOL_MAX_MATRIX_SIZE - 1:0] maxpoolIn;
    wire [`DATA_WIDTH - 1:0] maxpoolOut;

    max_pool maxPool(
        .clk(clk),
        .ena(maxpoolEna),
        .reset(maxpoolRst),
        
        .in_vector(maxpoolIn),
        .pool_out(maxpoolOut)
    );

    // multiply and addition
    reg multAddRst;
    reg [`DATA_WIDTH - 1:0] multAddData;
	reg [`DATA_WIDTH - 1:0] multAddWeight;
	reg [`DATA_WIDTH - 1:0] multAddSum;
	wire [`DATA_WIDTH - 1:0] multAddResult;

    mult_add ma(
		.clk(clk),
		.multAddRst(multAddRst),

		.data(multAddData),
		.weight(multAddWeight),
		.sum(multAddSum),

		.multAddResult(multAddResult)
	);

   always @(posedge clk or posedge modelRst) begin
        if(!modelRst) begin // reset
            runLayer <= IDLE;

            FMReadEn     <= 0;
            weightReadEn <= 0;
            biasReadEn   <= 0;

            input_fm_start_index  <= `LAYER_RAM_START_INDEX_0;
    		output_fm_start_index <= `LAYER_RAM_START_INDEX_1;

            kernel_count        <= 0;
            depth_count         <= 0;
            weight_matrix_count <= 0;

            padding_up_count    <= 0;
            padding_down_count  <= 0;
            padding_left_count  <= 0;
            padding_right_count <= 0;

            fm_x <= 0;
            fm_y <= 0;

            get_weight_number <= 0;
            get_bias_number   <= 0;
            get_fm_number     <= 0;

            set_fm_count      <= 0;

            read_fm_start     <= 0;
            read_weight_start <= 0;
            read_bias_start   <= 0;

            write_fm_start    <= 0;

            mult_clk_count           <= 0;
            bias_add_clk_count <= 0;

            update_kernel_clk_count <= 0;

            conv_status <= 0;
            pool_status <= 0;
            fc_status   <= 0;
        end
    end    

    always @(posedge clk) begin
    	if(modelRst) begin
    		if (runLayer == IDLE) begin
    			currentLayer <= runLayer;
    			updateKernel = 0;

    			if (writeInitDone == 0) begin      // fm of conv1 is not ready, wait to write or is writing
    				
    			end
    			else if (writeInitDone == 1) begin // fm of conv1 is ready, change to conv1
    				runLayer <= CONV1;
    			end
    		end
    		else if ((runLayer >= CONV1) && (runLayer <= CONV5)) begin      // convolution
    			FMReadEn     <= 1;
            	weightReadEn <= 1;
            	biasReadEn   <= 1;

    			if (currentLayer != runLayer) begin // reset conv
    				currentLayer <= runLayer;

    				conv_status <= 0;

    				kernel_count        <= 0;
		            depth_count         <= 0;
		            weight_matrix_count <= 0;

		            padding_up_count    <= 0;
		            padding_down_count  <= 0;
		            padding_left_count  <= 0;
		            padding_right_count <= 0;

		            fm_x <= 0;
		            fm_y <= 0;

		            get_weight_number <= 0;
		            get_bias_number   <= 0;
		            get_fm_number     <= 0;

		            set_fm_count      <= 0;

		            read_fm_start     <= 0;
		            read_weight_start <= 0;
		            read_bias_start   <= 0;

		            write_fm_start    <= 0;

                    mult_clk_count           <= 0;
            		bias_add_clk_count <= 0;
                    // update_kernel_status = 0;

                    current_weight <= 0;

                    conv_temp_result <= 0;

                    multEna <= 1;
                    multRst <= 0;

                    writeFM <=0;

    				// set parameters
	    			case(runLayer)
	                	CONV1: 
	                		begin
	                			input_fm_start_index  <= `LAYER_RAM_START_INDEX_0;
                            	output_fm_start_index <= `LAYER_RAM_START_INDEX_1;

                            	padding_up            <= `CONV1_FM_PADDING_UP;
                            	padding_down          <= `CONV1_FM_PADDING_DOWN;
                            	padding_left          <= `CONV1_FM_PADDING_LEFT;
                            	padding_right         <= `CONV1_FM_PADDING_RIGHT;

                            	kernel_number         <= `CONV1_KERNEL_NUMBER;
    							depth_number          <= `CONV1_DEPTH_NUMBER;
    							weight_matrix_number  <= `CONV1_WEIGHT_MATRIX_NUMBER;

    							fm_x_max              <= `CONV1_FM_SIZE + `CONV1_FM_PADDING_LEFT + `CONV1_FM_PADDING_RIGHT - `CONV1_WEIGHT_MATRIX_SIZE + 1;
    							fm_y_max              <= `CONV1_FM_SIZE + `CONV1_FM_PADDING_UP + `CONV1_FM_PADDING_DOWN - `CONV1_WEIGHT_MATRIX_SIZE + 1;

    							fm_size               <= `CONV1_FM_SIZE;
    							weight_size           <= `CONV1_WEIGHT_MATRIX_SIZE;
    							stride                <= `CONV1_STRIDE;
	                		end
	                	CONV2:
	                		begin
	                			input_fm_start_index  <= `LAYER_RAM_START_INDEX_0;
                            	output_fm_start_index <= `LAYER_RAM_START_INDEX_1;

                            	padding_up            <= `CONV2_FM_PADDING_UP;
                            	padding_down          <= `CONV2_FM_PADDING_DOWN;
                            	padding_left          <= `CONV2_FM_PADDING_LEFT;
                            	padding_right         <= `CONV2_FM_PADDING_RIGHT;

                            	kernel_number         <= `CONV2_KERNEL_NUMBER;
    							depth_number          <= `CONV2_DEPTH_NUMBER;
    							weight_matrix_number  <= `CONV2_WEIGHT_MATRIX_NUMBER;

    							fm_x_max              <= `CONV2_FM_SIZE + `CONV2_FM_PADDING_LEFT + `CONV2_FM_PADDING_RIGHT - `CONV2_WEIGHT_MATRIX_SIZE + 1;
    							fm_y_max              <= `CONV2_FM_SIZE + `CONV2_FM_PADDING_UP + `CONV2_FM_PADDING_DOWN - `CONV2_WEIGHT_MATRIX_SIZE + 1;

    							fm_size               <= `CONV2_FM_SIZE;
    							weight_size           <= `CONV2_WEIGHT_MATRIX_SIZE;
    							stride                <= `CONV2_STRIDE;
	                		end
	                	CONV3:
	                		begin
	                			input_fm_start_index  <= `LAYER_RAM_START_INDEX_0;
                            	output_fm_start_index <= `LAYER_RAM_START_INDEX_1;

                            	padding_up            <= `CONV3_FM_PADDING_UP;
                            	padding_down          <= `CONV3_FM_PADDING_DOWN;
                            	padding_left          <= `CONV3_FM_PADDING_LEFT;
                            	padding_right         <= `CONV3_FM_PADDING_RIGHT;

                            	kernel_number         <= `CONV3_KERNEL_NUMBER;
    							depth_number          <= `CONV3_DEPTH_NUMBER;
    							weight_matrix_number  <= `CONV3_WEIGHT_MATRIX_NUMBER;

    							fm_x_max              <= `CONV3_FM_SIZE + `CONV3_FM_PADDING_LEFT + `CONV3_FM_PADDING_RIGHT - `CONV3_WEIGHT_MATRIX_SIZE + 1;
    							fm_y_max              <= `CONV3_FM_SIZE + `CONV3_FM_PADDING_UP + `CONV3_FM_PADDING_DOWN - `CONV3_WEIGHT_MATRIX_SIZE + 1;

    							fm_size               <= `CONV3_FM_SIZE;
    							weight_size           <= `CONV3_WEIGHT_MATRIX_SIZE;
    							stride                <= `CONV3_STRIDE;
	                		end
	                	CONV4:
	                		begin
	                			input_fm_start_index  <= `LAYER_RAM_START_INDEX_1;
                            	output_fm_start_index <= `LAYER_RAM_START_INDEX_0;

                            	padding_up            <= `CONV4_FM_PADDING_UP;
                            	padding_down          <= `CONV4_FM_PADDING_DOWN;
                            	padding_left          <= `CONV4_FM_PADDING_LEFT;
                            	padding_right         <= `CONV4_FM_PADDING_RIGHT;

                            	kernel_number         <= `CONV4_KERNEL_NUMBER;
    							depth_number          <= `CONV4_DEPTH_NUMBER;
    							weight_matrix_number  <= `CONV4_WEIGHT_MATRIX_NUMBER;
	                		
	                			fm_x_max              <= `CONV4_FM_SIZE + `CONV4_FM_PADDING_LEFT + `CONV4_FM_PADDING_RIGHT - `CONV4_WEIGHT_MATRIX_SIZE + 1;
    							fm_y_max              <= `CONV4_FM_SIZE + `CONV4_FM_PADDING_UP + `CONV4_FM_PADDING_DOWN - `CONV4_WEIGHT_MATRIX_SIZE + 1;

    							fm_size               <= `CONV4_FM_SIZE;
    							weight_size           <= `CONV4_WEIGHT_MATRIX_SIZE;
    							stride                <= `CONV4_STRIDE;
	                		end
	                	CONV5:
	                		begin
	                			input_fm_start_index  <= `LAYER_RAM_START_INDEX_0;
                            	output_fm_start_index <= `LAYER_RAM_START_INDEX_1;

                            	padding_up            <= `CONV5_FM_PADDING_UP;
                            	padding_down          <= `CONV5_FM_PADDING_DOWN;
                            	padding_left          <= `CONV5_FM_PADDING_LEFT;
                            	padding_right         <= `CONV5_FM_PADDING_RIGHT;

                            	kernel_number         <= `CONV5_KERNEL_NUMBER;
    							depth_number          <= `CONV5_DEPTH_NUMBER;
    							weight_matrix_number  <= `CONV5_WEIGHT_MATRIX_NUMBER;

    							fm_x_max              <= `CONV5_FM_SIZE + `CONV5_FM_PADDING_LEFT + `CONV5_FM_PADDING_RIGHT - `CONV5_WEIGHT_MATRIX_SIZE + 1;
    							fm_y_max              <= `CONV5_FM_SIZE + `CONV5_FM_PADDING_UP + `CONV5_FM_PADDING_DOWN - `CONV5_WEIGHT_MATRIX_SIZE + 1;

    							fm_size               <= `CONV5_FM_SIZE;
    							weight_size           <= `CONV5_WEIGHT_MATRIX_SIZE;
    							stride                <= `CONV5_STRIDE;
	                		end
	                endcase
    			end
    			else begin
    				if (conv_status == 0) begin      // conv is running
    					multEna = 1;
                        multRst = 1;

                        if(updateKernel == 1) begin
                        	update_kernel_clk_count = update_kernel_clk_count + 1;
                        	if (update_kernel_clk_count >= 4) begin
                        		if(updateKernelDone == 1) begin
                                	updateKernel = 0;  
                                	update_kernel_clk_count = 0;
                            	end
                        	end
                        end

    					if(kernel_count < kernel_number) begin           // loop 4
                            if(fm_y < fm_y_max) begin                    // loop 3, fm_y = fm_y + stride
                                if(fm_x < fm_x_max) begin                // loop 3, fm_x = fm_x + stride
                                    if(depth_count < depth_number) begin // loop 2
                                        // read bias data
                                        if(get_bias_number < 1) begin
                                            if(read_bias_start == 0) begin
                                                biasReadAddr = 0;
                                                read_bias_start = 1;
                                            end
                                            else if(biasReadAddr == 0)
                                                biasReadAddr = 1;
                                            else if(biasReadAddr == 1)
                                                biasReadAddr = 0;

                                            get_bias_number = 1;
                                        end
                                        else if(get_bias_number == 3) begin // get read value
                                            bias = biasReadData;
                                        end
                                        else begin  
                                            get_bias_number = get_bias_number + 1;
                                        end

                                        // read weight data
                                        if(get_weight_number < weight_matrix_number) begin                                                    
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

                                            get_weight_number = get_weight_number + 1;

                                            if (get_weight_number >= 4) begin
                                                weight[get_weight_number - 4] = weightReadData;
                                            end

                                        end
                                        else if(get_weight_number < (weight_matrix_number + 3)) begin // get read value 
                                       		// read weight, each depth
                                       		get_weight_number = get_weight_number + 1;
                                            weight[get_weight_number - 4] = weightReadData;
                                        end

                                        // read feature map part data
                                        if (get_fm_number == 0) begin
                                        	// up
		                                    padding_up_count = 0;
		                                    if (fm_y < padding_up) begin
		                                        padding_up_count = padding_up - fm_y;
		                                        set_fm_count = 0;
		                                        i = 0;
		                                        while (i < (weight_size * padding_up_count)) begin
		                                        	fm[set_fm_count + i] = 0;
		                                        	i = i + 1;
		                                        end
		                                    end

		                                    // down
		                                    padding_down_count = 0;
		                                    if ((fm_y + weight_size) > (padding_up + fm_size)) begin
		                                        padding_down_count = (fm_y + weight_size) - (padding_up + fm_size);
		                                        set_fm_count = ((fm_size + padding_up) - fm_y) * weight_size;
		                                        i = 0;
		                                        while (i < (weight_size * padding_down_count)) begin
		                                        	fm[set_fm_count + i] = 0;
		                                        	i = i + 1;
		                                        end
		                                    end

		                                    // left
		                                    padding_left_count = 0;
		                                    if (fm_x < padding_left) begin
		                                        padding_left_count = padding_left - fm_x;
		                                        set_fm_count = padding_up_count * weight_size;
		                                        i = 0;
		                                        j = 0;
		                                        k = weight_size - padding_up_count - padding_down_count;
		                                        while (i < k) begin
		                                        	while (j < padding_left_count) begin
		                                        		fm[set_fm_count + j] = 0;
		                                        		j = j + 1;
		                                        	end
		                                        	j = 0;
		                                        	i = i + 1;
		                                        	set_fm_count = set_fm_count + weight_size;
		                                        end
		                                    end

		                                    // right
		                                    padding_right_count = 0;
		                                    if ((fm_x + weight_size) > (padding_left + fm_size)) begin
		                                        padding_right_count = (fm_x + weight_size) - (padding_left + fm_size);
		                                        set_fm_count = padding_up_count * weight_size + (weight_size - padding_right_count);
		                                        i = 0;
		                                        j = 0;
		                                        k = weight_size - padding_up_count - padding_down_count;
		                                        while (i < k) begin
		                                        	while (j < padding_right_count) begin
		                                        		fm[set_fm_count + j] = 0;
		                                        		j = j + 1;
		                                        	end
		                                        	j = 0;
		                                        	i = i + 1;
		                                        	set_fm_count = set_fm_count + weight_size;
		                                        end
		                                    end

		                                    // for others
		                                    set_fm_count = padding_up_count * weight_size + padding_left_count - 1;
		                                    j = weight_size - padding_left_count - padding_right_count; // a line of weight matrix others
		                                    k =  (weight_size - padding_up_count   - padding_down_count) * j;
                                        end

                                        // others
                                        if(get_fm_number < k) begin
                                            if(read_fm_start == 0) begin // the beginning
                                                FMReadAddr = input_fm_start_index;
                                                read_fm_start = 1;
                                            end
                                            //else if(get_fm_number > 0 && ((get_fm_number) % weight_size) == 0) // go to next line
                                            else if(get_fm_number > 0 && ((get_fm_number) % j) == 0) begin// go to next line
                                                FMReadAddr = FMReadAddr + fm_size - (j - 1);
                                            end
                                            else begin
                                                FMReadAddr = FMReadAddr + 1;
                                            end

                                            get_fm_number = get_fm_number + 1;
                                        end

                                        if (   (get_fm_number >= 4) 
                                        	&& (get_fm_number < (k + 4))) begin

                                            get_fm_number = get_fm_number - 4;
                                            if ((get_fm_number) > 0 && ((get_fm_number) % j) == 0) begin
                                            	set_fm_count = set_fm_count + weight_size - (j - 1);
                                            end
                                            else
                                            	set_fm_count = set_fm_count + 1;

                                            fm[set_fm_count] = FMReadData;
                                                
                                            get_fm_number = get_fm_number + 4;

                                            if (get_fm_number >= k) begin
	                                        	get_fm_number = get_fm_number + 1;
	                                        end
                                        end

                                        // kernel(weight and bias) is ready and do the conv
                                        if(    get_bias_number   == 3 
                                            && get_weight_number == (weight_matrix_number + 3)
                                            && get_fm_number     == (k + 4)) begin

                                            if(weight_matrix_count < weight_size) begin // each line
                                                // multX11
                                                i = weight_matrix_count * weight_size;

                                                case(currentLayer)
						    						CONV1:
						    							begin
						    								multData   = {fm[i+10], fm[i+9], fm[i+8], fm[i+7], fm[i+6], fm[i+5], fm[i+4], fm[i+3], fm[i+2], fm[i+1], fm[i]};
                                                			multWeight = {weight[i+10], weight[i+9], weight[i+8], weight[i+7], weight[i+6], weight[i+5], weight[i+4], weight[i+3], weight[i+2], weight[i+1], weight[i]};
						    							end
						    						CONV2:
						    							begin
						    								multData   = {96'b0, fm[i+4], fm[i+3], fm[i+2], fm[i+1], fm[i]}; // 6*16=96
						    								multWeight = {96'b0, weight[i+4], weight[i+3], weight[i+2], weight[i+1], weight[i]};
						    							end
						    						CONV3:
						    							begin
						    								multData   = {128'b0, fm[i+2], fm[i+1], fm[i]}; // 8*16 = 128
                                                   			multWeight = {128'b0, weight[i+2], weight[i+1], weight[i]};
						    							end
						    						CONV4:
						    							begin
						    								multData   = {128'b0, fm[i+2], fm[i+1], fm[i]}; // 8*16 = 128
                                                   	    	multWeight = {128'b0, weight[i+2], weight[i+1], weight[i]};
						    							end
						    						CONV5:
						    							begin
						    								multData   = {128'b0, fm[i+2], fm[i+1], fm[i]}; // 8*16 = 128
                                                   			multWeight = {128'b0, weight[i+2], weight[i+1], weight[i]};
                                                   		end
						    					endcase

                                                weight_matrix_count = weight_matrix_count + 1;   
                                            end

                                            // wait 10 clk and add
                                            if(mult_clk_count < 11) begin
                                                mult_clk_count = mult_clk_count + 1;
                                            end
                                            else if((mult_clk_count >= 11) && (mult_clk_count < 22)) begin
                                                addAValid = 1;
                                                addBValid = 1;
                                                addA = multResult;
                                                addB = addResult;
                                                mult_clk_count = mult_clk_count + 1;
                                            end
                                            else if(mult_clk_count == 22) begin
                                                addA = conv_temp_result;
                                                addB = addResult;
                                                mult_clk_count = mult_clk_count + 1;
                                            end
                                            else if(mult_clk_count == 23) begin
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
                                                weight_matrix_count = 0;
                                                mult_clk_count = 0;

                                                // next depth address
                                                // the last -1: when read fm data, it will +1
                                                if(depth_count < depth_number) begin
                                                    FMReadAddr = input_fm_start_index + depth_count * fm_size * fm_size 
                                                    			+ (fm_x < padding_left ? 0: fm_x - padding_left) 
                                                    			+ (fm_y < padding_up   ? 0: fm_y - padding_up) * fm_size - 1;
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
                                        if(bias_add_clk_count == 0) begin
                                            bias_add_clk_count = 1;
                                        end
                                        else if(bias_add_clk_count == 1) begin // write data
                                        	writeFM = 1;

                                            writeFMData = addResult;

                                            conv_temp_result = 0;
                                                
                                            addA = 0;
                                            addB = 0;

                                            if(write_fm_start == 0) begin
                                            	writeFMAddr = output_fm_start_index;
                                            	write_fm_start = 1;
                                        	end
                                        	else begin
                                            	writeFMAddr = writeFMAddr + 1;
                                       		end

                                            bias_add_clk_count = 0;

                                            depth_count = 0;
                                            // go to next feature map part data
                                            fm_x = fm_x + stride;
                                            get_fm_number = 0;
                                            FMReadAddr = input_fm_start_index 
                                            			+ (fm_x < padding_left ? 0: fm_x - padding_left) 
                                            			+ (fm_y < padding_up   ? 0: fm_y - padding_up) * fm_size - 1;

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
                                    weight_matrix_count = 0;

                                    fm_x = 0;
                                    fm_y = fm_y + stride;
                                    FMReadAddr = input_fm_start_index 
                                    			+ (fm_x < padding_left ? 0: fm_x - padding_left) 
                                    			+ (fm_y < padding_up   ? 0: fm_y - padding_up) * fm_size - 1;

                                    get_weight_number = 0;
                                    get_fm_number = 0;

                                    mult_clk_count = 0;
                                    bias_add_clk_count = 0;  
                                end
                            end
                            else begin // go to next kernel
                                    
                                read_fm_start = 0; // the beginning

                                // change to another kernel
                                if(current_weight == 0 || current_weight == 1) begin
                                    current_weight = 2;
                                end
                                else if(current_weight == 2 || current_weight == 3) begin
                                    current_weight = 0;
                                end

                                kernel_count = kernel_count + 1;
                                depth_count = 0;
                                weight_matrix_count = 0;

                                fm_x = 0;
                                fm_y = 0;

                                get_weight_number = 0;
                                get_bias_number = 0;
                                get_fm_number = 0;

                                if(updateKernel == 0) begin
                                    // update weight
                                    updateKernel = 1;
                                    if(current_weight == 0) 
                                    	updateKernelNumber = 1;
                                    else if(current_weight == 2)
                                    	updateKernelNumber = 0;
                                end   
                            end
                        end
                        else begin
                            conv_status = 1;
                        end
    				end
    				else if (conv_status == 1) begin // conv is done
    					// change to next layer
    					case(currentLayer)
    						CONV1:
    							runLayer <= POOL1;
    						CONV2:
    							runLayer <= POOL2;
    						CONV3:
    							runLayer <= CONV4;
    						CONV4:
    							runLayer <= CONV5;
    						CONV5:
    							runLayer <= POOL5;
    					endcase
    				end
    			end

    		end
    		else if ((runLayer >= POOL1) && (runLayer <= POOL5)) begin // pool
    			FMReadEn     <= 1;
            	weightReadEn <= 0;
            	biasReadEn   <= 0;

    			if (currentLayer != runLayer) begin
    				currentLayer <= runLayer;

    				pool_status <= 0;

                    depth_count <= 0;

                    fm_x <= 0;
                    fm_y <= 0;

                    get_fm_number <= 0;

                    read_fm_start  <= 0;

                    write_fm_start <= 0;

                    pool_clk_count = 0;

                    maxpoolEna <= 1;
                    maxpoolRst <= 0;

    				// set parameters
	    			case(runLayer)
	                	POOL1: 
	                		begin
	                			input_fm_start_index  <= `LAYER_RAM_START_INDEX_1;
                            	output_fm_start_index <= `LAYER_RAM_START_INDEX_0;

    							depth_number          <= `POOL1_DEPTH_NUMBER;
    							pool_matrix_number    <= `POOL1_POOL_MATRIX_NUMBER;

    							fm_x_max              <= `POOL1_FM_SIZE - `POOL1_POOL_MATRIX_SIZE + 1;
    							fm_y_max              <= `POOL1_FM_SIZE - `POOL1_POOL_MATRIX_SIZE + 1;

    							fm_size               <= `POOL1_FM_SIZE;
    							pool_size             <= `POOL1_POOL_MATRIX_SIZE;
    							stride                <= `POOL1_STRIDE;
	                		end
	                	POOL2:
	                		begin
	                			input_fm_start_index  <= `LAYER_RAM_START_INDEX_1;
                            	output_fm_start_index <= `LAYER_RAM_START_INDEX_0;

    							depth_number          <= `POOL2_DEPTH_NUMBER;
    							pool_matrix_number    <= `POOL2_POOL_MATRIX_NUMBER;

    							fm_x_max              <= `POOL2_FM_SIZE - `POOL2_POOL_MATRIX_SIZE + 1;
    							fm_y_max              <= `POOL2_FM_SIZE - `POOL2_POOL_MATRIX_SIZE + 1;

    							fm_size               <= `POOL2_FM_SIZE;
    							pool_size             <= `POOL2_POOL_MATRIX_SIZE;
    							stride                <= `POOL2_STRIDE;
	                		end
	                	POOL5:
	                		begin
	                			input_fm_start_index  <= `LAYER_RAM_START_INDEX_1;
                            	output_fm_start_index <= `LAYER_RAM_START_INDEX_0;

    							depth_number          <= `POOL5_DEPTH_NUMBER;
    							pool_matrix_number    <= `POOL5_POOL_MATRIX_NUMBER;

    							fm_x_max              <= `POOL5_FM_SIZE - `POOL5_POOL_MATRIX_SIZE + 1;
    							fm_y_max              <= `POOL5_FM_SIZE - `POOL5_POOL_MATRIX_SIZE + 1;

    							fm_size               <= `POOL5_FM_SIZE;
    							pool_size             <= `POOL5_POOL_MATRIX_SIZE;
    							stride                <= `POOL5_STRIDE;
	                		end
	                endcase
    			end
    			else begin
    				if (pool_status == 0) begin      // pool is running
    					maxpoolEna = 1;
                        maxpoolRst = 1;

                        if(depth_count < depth_number) begin 
                            if(fm_y < fm_y_max) begin
                                if(fm_x < fm_x_max) begin
                                    // read feature map part data
                                    if(get_fm_number < pool_matrix_number) begin
                                        if(read_fm_start == 0) begin// the beginning
                                            FMReadAddr = input_fm_start_index;
                                            read_fm_start = 1;
                                        end
                                        else if(get_fm_number > 0 && ((get_fm_number) % pool_size) == 0) // go to next line
                                            FMReadAddr = FMReadAddr + fm_size - (pool_size - 1);
                                        else
                                            FMReadAddr =  FMReadAddr + 1;

                                        get_fm_number = get_fm_number + 1;

                                        if (get_fm_number >= 4) begin
                                            fm[get_fm_number - 4] = FMReadData;
                                        end
                                    end
                                    else if(get_fm_number < (pool_matrix_number + 3)) begin
                                            get_fm_number = get_fm_number + 1;
                                            fm[get_fm_number - 4] = FMReadData;
                                    end

                                    // max pool
                                    if(get_fm_number == (pool_matrix_number + 3)) begin
                                        maxpoolIn = {fm[8], fm[7], fm[6], fm[5], fm[4], fm[3], fm[2], fm[1], fm[0]};

                                        // get max pool result
                                        if(pool_clk_count < 6) begin
                                            pool_clk_count = pool_clk_count + 1;
                                        end
                                        else begin // write max pool result to ram
                                        	writeFMData = maxpoolOut;

                                            if(write_fm_start == 0) begin
                                                writeFMAddr = output_fm_start_index;
                                                write_fm_start = 1;
                                            end
                                            else begin
                                                writeFMAddr = writeFMAddr + 1;
                                            end

                                            pool_clk_count = 0;

                                            // go to next feature map part data
                                            fm_x = fm_x + stride;
                                            get_fm_number = 0;
                                            FMReadAddr = input_fm_start_index + depth_count * fm_size * fm_size + fm_x + fm_y * fm_size - 1;
                                        end
                                    end
                                end
                                else begin
                                    pool_clk_count = 0;

                                    // go to next fm matrix line
                                    fm_x = 0;
                                    fm_y = fm_y + stride;
                                    FMReadAddr = input_fm_start_index + depth_count * fm_size * fm_size + fm_y * fm_size - 1;
                                end
                            end
                            else begin
                                // go to next depth
                                fm_x = 0;
                                fm_y = 0;
                                depth_count = depth_count + 1;
                                FMReadAddr = input_fm_start_index + depth_count * fm_size * fm_size - 1;
                            end
                        end
                        else begin
                            pool_status = 1;
                        end
    				end
    				else if (pool_status == 1) begin // pool is done
    					// change to next layer
    					case(currentLayer)
    						POOL1:
    							runLayer <= CONV2;
    						POOL2:
    							runLayer <= CONV3;
    						POOL5:
    							runLayer <= FC6;
    					endcase
    				end
    			end
    		end
    		else if ((runLayer >= FC6) && (runLayer <= FC8)) begin     // fc
    			FMReadEn     <= 1;
            	weightReadEn <= 1;
            	biasReadEn   <= 1;

    			if (currentLayer != runLayer) begin
    				currentLayer <= runLayer;

    				fc_status <= 0;

    				kernel_count    <= 0;
    				fm_matrix_count <= 0;

    				get_weight_number <= 0;
                    get_bias_number   <= 0;
                    get_fm_number     <= 0;

    				read_fm_start     <= 0;
    				read_weight_start <= 0;
    				read_bias_start   <= 0;

    				write_fm_start    <= 0;

    				fc_clk_count   <= 0;

    				current_weight <= 0;

    				fc_temp_result <= 0;

    				multAddRst <= 0;

    				// set parameters
	    			case(runLayer)
	                	FC6: 
	                		begin
	                			input_fm_start_index  <= `LAYER_RAM_START_INDEX_0;
                            	output_fm_start_index <= `LAYER_RAM_START_INDEX_1;

                            	kernel_number    <= `FC6_KERNEL_NUMBER;
                            	fm_matrix_number <= `FC6_FM_MATRIX_SIZE;

	                		end
	                	FC7:
	                		begin
	                			input_fm_start_index  <= `LAYER_RAM_START_INDEX_1;
                            	output_fm_start_index <= `LAYER_RAM_START_INDEX_0;

                            	kernel_number    <= `FC7_KERNEL_NUMBER;
                            	fm_matrix_number <= `FC7_FM_MATRIX_SIZE;
	                		end
	                	FC8:
	                		begin
	                			input_fm_start_index  <= `LAYER_RAM_START_INDEX_0;
                            	output_fm_start_index <= `LAYER_RAM_START_INDEX_1;

                            	kernel_number    <= `FC8_KERNEL_NUMBER;
                            	fm_matrix_number <= `FC8_FM_MATRIX_SIZE;
	                		end
	                endcase
    			end
    			else begin
    				if (fc_status == 0) begin      // fc is running
    					multAddRst = 1;

    					if (updateKernel == 1) begin
    						if (updateKernelDone == 1) begin
    							updateKernel = 0;
    						end
    					end

    					if (kernel_count < kernel_number) begin
    						if (fm_matrix_count < fm_matrix_number) begin
    							// read bias data
    							if(get_bias_number < 1) begin
                                    if(read_bias_start == 0) begin
                                        biasReadAddr = 0;
                                        read_bias_start = 1;
                                    end
                                    else if(biasReadAddr == 0)
                                        biasReadAddr = 1;
                                    else if(biasReadAddr == 1)
                                        biasReadAddr = 0;

                                    get_bias_number = 1;
                                end
                                else if(get_bias_number == 3) begin // get read value
                                    bias = biasReadData;
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
                                    weight[0] = weightReadData;
                                end
                                else begin
                                	get_weight_number = get_weight_number + 1;
                                end

    							// read feature map data
                                if(get_fm_number < 1) begin
                                    if(read_fm_start == 0) begin // the beginning
                                        FMReadAddr = input_fm_start_index;
                                        read_fm_start = 1;
                                    end
                                    else begin
                                    	FMReadAddr = FMReadAddr + 1;
                                    end

                                    get_fm_number = 1;
                                end
                                else if(get_fm_number == 3) begin // get read value
                                    fm[0] = FMReadData;
                                end
                                else begin
                                	get_fm_number = get_fm_number + 1;
                                end

                                // fc
                                if (	get_bias_number   == 3
                                	 &&	get_weight_number == 3
                                	 && get_fm_number     == 3) begin

                                	multAddData   = fm[0];
                                	multAddWeight = weight[0];
                                	multAddSum    = fc_temp_result;

                                	if (fc_clk_count < 3) begin // todo test
                                		fc_clk_count = fc_clk_count + 1;
                                	end
                                	else if (fc_clk_count == 3) begin
                                		fc_temp_result = multAddResult;

                                		get_weight_number = 0;
                                		get_fm_number     = 0;
                                	end 
                                end
    						end
    						else begin // go to next kernel
    							addAValid = 1;
                                addBValid = 1;

                                addA = bias;
                                addB = fc_temp_result; 

                                if(bias_add_clk_count == 0) begin
                                    bias_add_clk_count = 1;
                                end
                                else if(bias_add_clk_count == 1) begin // write data
                                	read_fm_start = 0; // the beginning

	    							// write fc result to ram
	    							writeFMData = multAddResult;

	                                if(write_fm_start == 0) begin
	                                    writeFMAddr = output_fm_start_index;
	                                    write_fm_start = 1;
	                                end
	                                else begin
	                                    writeFMAddr = writeFMAddr + 1;
	                                end

	    							// change to another kernel
	                                if(current_weight == 0 || current_weight == 1) begin
	                                    current_weight = 2;
	                                end
	                                else if(current_weight == 2 || current_weight == 3) begin
	                                    current_weight = 0;
	                                end

	                                kernel_count    = kernel_count + 1;
	                                fm_matrix_count = 0;

	                                get_weight_number = 0;
	                                get_bias_number   = 0;
	                                get_fm_number     = 0;

	                                if(updateKernel == 0) begin
	                                    // update weight
	                                    updateKernel = 1;
	                                    if(current_weight == 0) 
	                                    	updateKernelNumber = 1;
	                                    else if(current_weight == 2)
	                                    	updateKernelNumber = 0;
	                                end
                                end
    						end
    					end
    					else begin
    						fc_status = 1;
    					end
    				end
    				else if (fc_status == 1) begin // fc is done
    					// change to next layer
    					case(currentLayer)
    						FC6:
    							runLayer <= FC7;
    						FC7:
    							runLayer <= FC8;
    						FC8:
    							runLayer <= IDLE;
    					endcase
    				end
    			end
    		end

    	end
    end     
endmodule
