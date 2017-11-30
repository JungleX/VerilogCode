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
    
    input update_weight_ram, // 0: not update; 1: update
    input [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] update_weight_ram_addr,
    
    input init_fm_ram_ready, // 0: not ready; 1: ready
    input init_weight_ram_ready, // 0: not ready; 1: ready
    
    output reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] init_fm_data,
    output reg [`WRITE_ADDR_WIDTH - 1:0] write_fm_data_addr,
    output reg init_fm_data_done,
    
    output reg [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_data,
    output reg [`WEIGHT_WRITE_ADDR_WIDTH*`PARA_KERNEL - 1:0] write_weight_data_addr,
    output reg weight_data_done // weight data transmission, 0: not ready; 1: ready
    
    
    //used for testbench,please set as non-output registers while running
    );
    

reg update_ena;
reg cnt1 = 1'b1;
reg cnt2 = 1'b1;
reg upp;
reg [`PARA_X*`PARA_Y*`DATA_WIDTH - 1:0] fm_set_one;
reg [`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL*`DATA_WIDTH - 1:0] weight_set_one;
reg [5:0] fm_cnt;
reg [5:0] wr_cnt;
initial
begin
    fm_set_one <= {`PARA_X*`PARA_Y{16'h3c00}};
    weight_set_one <= {`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX*`PARA_KERNEL{16'h3c00}};	
    update_ena <= 1;
	init_fm_data_done <= 1'b0;
	weight_data_done <= 1'b0;
    fm_cnt <= 6'b0;
    wr_cnt <= 6'b0;
    upp <= 1'b1;
end//provide all-1 arrays for featuremap and weightram



always @(posedge clk) if(init == 1) update_ena <= 0; else update_ena <= 1;





always @(posedge clk) begin
    if (rst) begin
        init_fm_data <= 0;
        write_fm_data_addr <= 0;
        init_fm_data_done <= 0;
		
        weight_data <= 0;
        write_weight_data_addr <= 0;
        weight_data_done <= 0;
		
        update_ena <= 1;
		fm_cnt <= 0;
		wr_cnt <= 0;
    end
end//reset






always @(posedge clk) if (~cnt1) cnt1 <= 1'b1;
always @(posedge clk) if (~cnt2) cnt2 <= 1'b1;
always @(posedge clk) begin    
    if ((init) && (update_ena)) begin
        init_fm_data <= fm_set_one;
        write_fm_data_addr <= fm_cnt;
        init_fm_data_done <= 0;
		cnt1 <= 0;
		
        weight_data <= weight_set_one;
        write_weight_data_addr <= wr_cnt;
        weight_data_done <= 0;
		cnt2 <= 0;				
	end
end//fm and wr data transmission initializing





reg clk_fm = 1'b0;
always @(posedge clk) begin
    if ((~update_ena) && (~init_fm_data_done)) clk_fm <= ~clk_fm;//double period clk
	else if (init_fm_data_done) clk_fm <= 0;
end

always @(posedge clk) begin
    if (clk_fm == 1) begin
	    if(fm_cnt < 18) begin
		    fm_cnt <= fm_cnt + 1;
		    init_fm_data <= fm_set_one;
            write_fm_data_addr <= fm_cnt;
		end
		else begin
            init_fm_data_done <= 1;
		    cnt1 <= 0;
		    fm_cnt <= 0;
            write_fm_data_addr <= fm_cnt;		
		end
    end
end//send data to the next fm addr until addr reaches 17



reg clk_wr = 1'b0;
always @(posedge clk) begin
    if ((~update_ena) && (~weight_data_done)) clk_wr <= ~clk_wr;//double period clk
	else if (weight_data_done) clk_wr <= 0;
end

always @(posedge clk) begin
    if (clk_wr == 1) begin
	    if(wr_cnt < 4) begin
		    wr_cnt <= wr_cnt + 1;
		    weight_data <= weight_set_one;
			case (wr_cnt)
			    0:write_weight_data_addr <= 0;
				1:write_weight_data_addr <= `KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX;
				2:write_weight_data_addr <= `WEIGHT_RAM_HALF;
				3:write_weight_data_addr <= `WEIGHT_RAM_HALF+`KERNEL_SIZE_MAX*`KERNEL_SIZE_MAX;
			endcase
		end
		else begin
            weight_data_done <= 1;
		    cnt2 <= 0;
		    wr_cnt <= 0;
            write_weight_data_addr <= wr_cnt;		
		end
    end
end//send (init)data to the next weight addr until addr reaches 3




always @(posedge clk) 
if (~update_weight_ram) upp <= 1;
else if (update_weight_ram) upp <= 0;

always @(posedge clk) begin
    if ((update_weight_ram) && (update_ena) && (upp)) begin
	    weight_data_done <= 0;
        weight_data <= weight_set_one;
        write_weight_data_addr <= update_weight_ram_addr;
		cnt2 <= 0;				
    end
end//send (update)data to current update addr

always @(posedge clk) begin
    if((upp == 0)&& (update_ena) && (cnt2)) weight_data_done <= 1;
end//stop sending weight data to current update addr



endmodule
