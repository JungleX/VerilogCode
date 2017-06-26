module PU #(
	parameter integer OP_WIDTH        = 16,
	parameter integer NUM_PE          = 4
)(
	input wire [ DATA_IN_WIDTH  -1 : 0 ]    vecgen_wr_data
);

localparam integer DATA_IN_WIDTH     = OP_WIDTH * NUM_PE;

genvar i;

generate
for (i=0; i<NUM_PE; i=i+1)
begin : PE_GENBLK

wire [ OP_WIDTH  - 1 : 0 ] pe_read_data_0;

	assign pe_read_data_0 = vecgen_wr_data_d [i*OP_WIDTH+:OP_WIDTH]
end
endgenerate

endmodule
