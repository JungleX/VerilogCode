`timescale 1ns / 1ps
`include "CNN_Parameter.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/23 21:48:21
// Design Name: 
// Module Name: DataTransmission
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


module DataTransmission(
    input clk,
    input rst,
    
    input init,
    output reg start,
    
    input update_weight_ram, // 0: not update; 1: update
    input [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] update_weight_ram_addr,
    
    input init_fm_ram_ready, // 0: not ready; 1: ready
    input init_weight_ram_ready, // 0: not ready; 1: ready
    
    output reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] init_fm_data,
    output reg [`WRITE_ADDR_WIDTH - 1:0] write_fm_data_addr,
    output reg init_fm_data_done = 1'b0,
    
    output reg [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_data,
    output reg [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] write_weight_data_addr,
    output reg weight_data_done // weight data transmission, 0: not ready; 1: ready
    );
    


reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] fm_set_one;
reg [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_set_one;
reg update_ena;
reg [5:0] fm_cnt;
reg [5:0[ wr_cnt;
initial
begin
    fm_set_one <= {`PARA_X*`PARA_Y{16'h3c00}};
    weight_set_one <= {`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL{16'h3c00}};	
    update_ena <= 1'b1;
    fm_cnt <= 6'b0;
    wr_cnt <= 6'b0;
end
//provide all-1 arrays for featuremap and weightram



always @(posedge clk) update_ena <= !init;





always @(posedge clk) begin
    if (rst) begin
        init_fm_data <= 0;
        write_fm_data_addr <= 0;
        init_fm_data_done <= 0;
        weight_data <= 0;
        write_weight_data_addr <= 0;
        weight_data_done <= 0;
        update_ena <= 0;
		fm_cnt <= 0;
		wr_cnt <= 0;
    end
end//reset





reg cnt1 = 1'b1;
reg cnt2 = 1'b1;
always @(posedge clk) if (!cnt1) cnt1 <= 1'b1;
always @(posedge clk) if (!cnt2) cnt2 <= 1'b1;
always @(posedge clk) begin    
    if ((init) && (update_ena)) begin
        init_fm_data <= fm_set_one;
        write_fm_data_addr <= fm_cnt;
		init_fm_data_done <= 1;
		cnt1 <= 0;
		
        weight_data <= weight_set_one;
        write_weight_data_addr <= wr_cnt;
		weight_data_done <= 1;
		cnt2 <= 0;				
	end
end//fm and wr data transmission initializing





always @(posedge clk) begin
    if ((init_fm_ram_ready) && (cnt1) && (!update_ena)) init_fm_data_done <= 0;
end//stop sending fm data to current fm addr

always @(posedge clk) begin
    if ((init) && (!init_fm_data_done) && (!init_fm_ram_ready) && (!update_ena)) begin
	    if (fm_cnt < 17) begin
            fm_cnt <= fm_cnt + 1;	                              //not sure
		    init_fm_data <= fm_set_one;
            write_fm_data_addr <= fm_cnt;
		    init_fm_data_done <= 1;
		    cnt1 <= 0;
		end
		else start <= 1;
	end
end//send data to the next fm addr until addr reaches 17

always @(posedge clk) if (!init) start <= 0;





always @(posedge clk) begin
    if ((init_weight_ram_ready) && (cnt2)) weight_data_done <= 0;
end//stop sending weight data to current weight addr

always @(posedge clk) begin
    if ((init) && (!weight_data_done) && (!init_weight_ram_ready) && (!update_ena)) begin
	    if (wr_cnt < 3) begin
            wr_cnt <= wr_cnt + 1;	                              //not sure
		    weight_data <= weight_set_one;
			case (wr_cnt)
			    0:write_weight_data_addr <= 0;
				1:write_weight_data_addr <= `KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX;
				2:write_weight_data_addr <= `WEIGHT_RAM_HALF;
				3:write_weight_data_addr <= `WEIGHT_RAM_HALF+`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX;
			endcase
		    weight_data_done <= 1;
		    cnt2 <= 0;
		end
	end
end//send (init)data to the next weight addr until addr reaches 3





always @(posedge clk) begin
    if ((update_weight_ram) && (update_ena)) begin
        weight_data <= weight_set_one;
        write_weight_data_addr <= update_weight_ram_addr;
        weight_data_done <= 1;
		cnt2 <= 0;				
    end
end//send (update)data to current update addr

always @(posedge clk) begin
    if((!update_weight_ram) && (update_ena) && (cnt2)) weight_data_done <= 0;
end//stop sending weight data to current update addr



endmodule
