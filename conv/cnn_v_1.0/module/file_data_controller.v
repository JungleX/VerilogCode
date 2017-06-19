`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/06/16 09:52:53
// Design Name: 
// Module Name: file_data_controller
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

module file_data_controller(
	input clk,
	input rst,

	input [31:0] sig_1, 
	input [31:0] sig_2, 
	input [31:0] sig_3,

	output reg [31:0] sig,

	output reg FMWea,
	output reg FMWriteEn,
    output reg [15:0] FMWriteData,       // write data to layer data RAM
    output reg [18:0] FMWriteAddr,       // layer data addreses
    
    output reg weightWea,
    output reg weightWriteEn,
    output reg [15:0] weightWriteData, // write data to weight RAM
    output reg [12:0] weightWriteAddr,
    
    output reg biasWea,
    output reg biasWriteEn,
    output reg [15:0] biasWriteData,     // write data to bias RAM
    output reg biasWriteAddr
    );

	reg write_init_data;
	reg write_init_done;

	reg write_FM;
	reg [15:0] write_FM_data;
	reg [31:0] write_FM_addr;

	reg update_kernel;
	reg update_kernel_number;

	reg [17:0] fm_write_count;        // 18 bits, max value 262144 > 227*227*3=154587, count the init feature map data
    reg [12:0] weight_write_count;         
    reg [2:0]  bias_write_count;

    reg [8:0] weight_count;           // 9  bits, max value 512 > 384 > 256 > 96
    reg [8:0] bias_count;             // 9  bits, max value 512 > 384 > 256 > 96
    
    reg [8:0] update_kernel_wait_clk; // 9  bits, max value 512 > 384

    reg file_data_done;
    reg [15:0] fm_data    [0:(`CONV1_FM_SIZE * `CONV1_FM_SIZE * `CONV1_KERNEL_NUMBER - 1)]; // get layer data from conv1 file
    reg [15:0] weight_data[0:(`CONV1_WEIGHT_MATRIX_NUMBER * `CONV1_DEPTH_NUMBER * `CONV1_KERNEL_NUMBER) - 1];  // get weight data from file
    reg [15:0] bias_data  [0:(`CONV1_KERNEL_NUMBER - 1)]; // get bias from file

	always @(posedge clk or posedge rst) begin
		if(!rst) begin // reset
			sig <= 0;

			write_init_data <= 0;
			write_init_done <= 0;

			fm_write_count     <= 0;
			weight_write_count <= 0;
			bias_write_count   <= 0;

			update_kernel_wait_clk <= 0;

			FMWea     <= 0;
			weightWea <= 0;
			biasWea   <= 0;

			FMWriteEn     <= 0;
			weightWriteEn <= 0;
			biasWriteEn   <= 0;

			file_data_done <= 0;

			weight_count <= 0;
			bias_count   <= 0;
		end
	end

	always @(posedge clk) begin
		if(rst) begin 
			// get signal from sig_1, sig_2, sig_3
			write_init_data      = sig_1[0:0];
			write_FM             = sig_1[1:1];
			update_kernel        = sig_1[2:2];
			update_kernel_number = sig_1[3:3];

			write_FM_data        = sig_2[15:0];
			write_FM_addr        = sig_3;

			FMWea     <= 1;
			weightWea <= 1;
			biasWea   <= 1;

			if (write_init_done == 0) begin
				if (file_data_done == 0) begin
					$readmemb("fm.mem", fm_data); 
                    $readmemb("weight.mem", weight_data); 
                    $readmemb("bias.mem", bias_data); 
                    file_data_done = 1;

                    fm_write_count     = 0;
                    weight_write_count = 0;
                    bias_write_count   = 0;
				end
				else begin // write fm data and 2 kernel data to ram
					// write fm data
					if(fm_write_count < (`CONV1_FM_SIZE * `CONV1_FM_SIZE * `CONV1_DEPTH_NUMBER)) begin 
						sig[0:0] = 0;

                        FMWriteEn = 1;
                        if(fm_write_count == 0)
                            FMWriteAddr = 0;
                        else begin
                        	FMWriteAddr = FMWriteAddr + 1;
                        end

                            FMWriteData = fm_data[fm_write_count];

                            fm_write_count = fm_write_count + 1;
                        end
                    else begin
                        FMWriteEn = 0;
                    end

                    // write weight data
                    if(weight_write_count < (`CONV1_WEIGHT_MATRIX_NUMBER * `CONV1_DEPTH_NUMBER * 2) ) begin
                    	sig[0:0] = 0;

                        weightWriteEn = 1;
                                        
                        if(weight_write_count == 0) begin
                            weightWriteAddr = `WEIGHT_RAM_START_INDEX_0;

                            weight_count = 1;
                        end
                        else if(weight_write_count == (`CONV1_WEIGHT_MATRIX_NUMBER * `CONV1_DEPTH_NUMBER)) begin
                            weightWriteAddr = `WEIGHT_RAM_START_INDEX_1;

                            weight_count = 2;
                        end
                        else begin
                        	weightWriteAddr = weightWriteAddr + 1; 
                        end

							weightWriteData = weight_data[weight_write_count]; 
                            
                            weight_write_count = weight_write_count + 1;
                    end
                    else begin
                        weightWriteEn = 0;
                    end

                    // load bias data
                    if(bias_write_count < 2) begin
                    	sig[0:0] = 0;

                        biasWriteEn = 1;
                        
                        if(bias_write_count == 0) begin
                            biasWriteAddr = 0;

                            bias_count = 1;
                        end
                        else begin
                            biasWriteAddr = 1;

                            bias_count = 2;
                        end

                        biasWriteData = bias_data[bias_write_count];

                        bias_write_count = bias_write_count + 1;
                    end
                    else begin
                        biasWriteEn = 0;
                    end

                    // write init data done
					if (   FMWriteEn     == 0
                    	&& weightWriteEn ==0
                    	&& biasWriteEn   == 0) begin
                    	sig[0:0]        = 1; // write init data done
                    	write_init_done = 1;

						fm_write_count     = 0;
						weight_write_count = 0;
						bias_write_count   = 0;
                    end

				end
			end
			else if (write_init_done == 1) begin 
				// update kernel data
				if (update_kernel == 1 && update_kernel_wait_clk == 0) begin
					// write weight data
                    if(weight_write_count < (`CONV1_WEIGHT_MATRIX_NUMBER * `CONV1_DEPTH_NUMBER) ) begin
                    	sig[2:2]  = 0;

                        weightWriteEn = 1;
                          
                        weightWriteData = weight_data[weight_write_count + weight_count * `CONV1_WEIGHT_MATRIX_NUMBER * `CONV1_DEPTH_NUMBER];

                        if(weight_write_count == 0) begin
                        	if (update_kernel_number == 0) begin
                        		weightWriteAddr = `WEIGHT_RAM_START_INDEX_0;
                        	end
                        	else begin
                        		weightWriteAddr = `WEIGHT_RAM_START_INDEX_1;
                        	end
                        end
                        else begin
                        	weightWriteAddr = weightWriteAddr + 1; 
                        end

						weight_write_count = weight_write_count + 1;
                    end
                    else if (weightWriteEn == 1) begin
                        weightWriteEn = 0;
                        weight_count = weight_count + 1;
                    end

                    // load bias data
                    if(bias_write_count < 1) begin
                    	sig[2:2]  = 0;

                        biasWriteEn = 1;
                        
                        biasWriteData = bias_data[bias_write_count + bias_count];

                        if(bias_write_count == 0) begin
                        	if (update_kernel_number == 0) begin
                        		biasWriteAddr = 0;
                        	end
                        	else begin
                        		biasWriteAddr = 1;
                        	end
                        end

                        bias_write_count = bias_write_count + 1;
                    end
                    else if (biasWriteEn == 1) begin
                        biasWriteEn = 0;
                        bias_count = bias_count + 1;
                    end

                    // update kernel done
					if (weightWriteEn == 0 && biasWriteEn == 0) begin
                    	sig[2:2] = 1; // update kernel done

                    	update_kernel_wait_clk = update_kernel_wait_clk + 1;
                    end
				end
				else if (update_kernel == 1 && update_kernel_wait_clk < 3) begin
					update_kernel_wait_clk = update_kernel_wait_clk + 1;
				end
				else if (update_kernel == 1 && update_kernel_wait_clk >= 3)  begin
					weight_write_count = 0;
                    bias_write_count   = 0;
                    update_kernel_wait_clk = 0;
				end

				// write fm data
				if (write_FM == 1) begin
					FMWriteEn = 1;
                    
                    FMWriteData = write_FM_data;

                    FMWriteAddr = write_FM_addr;

                    sig[1:1]    = 1; // write fm done
				end
			end
		end
	end
endmodule
