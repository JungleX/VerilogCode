

module PU 
#(
	parameter integer PU_ID             = 0,
	parameter integer OP_WIDTH          = 16,
	
	parameter integer NUM_PE            = 4,






    parameter integer WR_ADDR_WIDTH     = 5,





    parameter integer AXI_DATA_WIDTH    = 64,

    parameter integer D_TYPE_W          = 2,
	parameter integer RD_LOOP_W         = 10




)(
	input wire                               clk,
	input wire                               reset,
	
	input wire                               lrn_enable,
	
	
	
	
	input wire                               bias_read_req,
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	input wire [ DATA_IN_WIDTH  -1 : 0 ]    vecgen_wr_data,
	
	
	
	
	input wire [ AXI_DATA_WIDTH -1 : 0 ]     read_data,
	input wire [ RD_LOOP_W      -1 : 0 ]     read_id,
	input wire [ D_TYPE_W       -1 : 0 ]     read_d_type,
	input wire                               buffer_read_data_valid,
	output wire                              read_req
	
	
	
	
);




localparam integer DATA_IN_WIDTH     = OP_WIDTH * NUM_PE;









genvar i;







wire [ 1024              -1 : 0 ]      GND;







wire                                    wb_weight_read_req;

reg [ WR_ADDR_WIDTH        -1 : 0]      wb_write_addr;











wire pu_bias_read_req;







assign GND = 1024'd0;

assign read_req = wb_weight_read_req || pu_bias_read_req;




































































reg [ OP_WIDTH           -1 : 0 ]       bias;
reg bias_v;
reg [ D_TYPE_W           -1 : 0 ]       read_d_type_d;

wire weight_reset;
assign weight_reset = bias_read_req;

always @(posedge clk)
	if (reset)
		bias <= 0;
	else if (pu_bias_read_req)
		bias <= read_data[OP_WIDTH-1:0];

always @(posedge clk)
begin
	if (reset)
		bias_v <= 1'b0;
	else if (weight_reset)
		bias_v <= 1'b0;
	else if (pu_bias_read_req)
		bias_v <= 1'b1;
end	

assign pu_bias_read_req = buffer_read_data_valid && !bias_v && read_id == PU_ID;    //bias_v=1 -> pu_bias_read_req=0
reg pu_bias_read_req_d;
always @(posedge clk)
    pu_bias_read_req_d <= pu_bias_read_req;

assign wb_weight_read_req = buffer_read_data_valid && bias_v && read_id == PU_ID;

assign wb_write_req = wb_weight_read_req;

always @(posedge clk)
    read_d_type_d <= read_d_type;


always @(posedge clk)
begin: WB_WRITE
    if (reset)
        wb_write_addr <= GND[WR_ADDR_WIDTH-1:0];
end

endmodule
