

module PU 
#(
	parameter integer PU_ID           = 0,
	parameter integer OP_WIDTH        = 16,
	
	parameter integer NUM_PE          = 4,















	parameter integer RD_LOOP_W         = 10




)(
	input wire                               clk,
	input wire                               reset,
	
	input wire                               lrn_enable,
	
	
	
	
	input wire                               bias_read_req,
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	input wire [ DATA_IN_WIDTH  -1 : 0 ]    vecgen_wr_data
	
	
	
	
	
	input wire [ RD_LOOP_W      -1 : 0 ]     read_id;
	
	input wire                               buffer_read_data_valid;
	output wire                              read_req
	
	
	
	
);




localparam integer DATA_IN_WIDTH     = OP_WIDTH * NUM_PE;









genvar i;















wire                                wb_weight_read_req;













wire pu_bias_read_req;







assign GND = 1024'd0;

assign read_req = wb_weight_read_req || pu_bias_read_req;




































































reg [ OP_WIDTH           -1 : 0 ]       bias;
reg bias_v;


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

assign pu_bias_read_req = buffer_read_data_valid && !bias_v && read_id == PU_ID;




assign wb_weight_read_req = buffer_read_data_valid && bias_v && read_id == PU_ID;

assign wb_write_req = wb_weight_read_req;

endmodule
