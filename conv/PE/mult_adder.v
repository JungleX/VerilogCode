`include "../bit_width.vh"

module mult_adder(
	input clock,
	input reset,
	input[`MULT_ADDER_IN_WIDTH-1:0] in,
	input[`MULT_ADDER_IN_WIDTH-1:0] kernel,
	output[`CONV_ADD_WIDTH-1:0] out
	);

//wire declaration
//MA_TREE_SIZE = 3
wire [`CONV_PRODUCT_WIDTH-1:0] in_add_vector_wire0;
wire [`CONV_PRODUCT_WIDTH-1:0] in_add_vector_wire1;
wire [`CONV_PRODUCT_WIDTH-1:0] in_add_vector_wire2;
//3 * 2 - 1
wire [`CONV_ADD_WIDTH-1:0] adder_tree_wire0;
wire [`CONV_ADD_WIDTH-1:0] adder_tree_wire1;
wire [`CONV_ADD_WIDTH-1:0] adder_tree_wire2;
wire [`CONV_ADD_WIDTH-1:0] adder_tree_wire3;
wire [`CONV_ADD_WIDTH-1:0] adder_tree_wire4;

wire [(`MA_TREE_SIZE*2)-1-1:0]carry_wire ;

// assign statments
assign out = adder_tree_wire0;
assign carry_wire [(`MA_TREE_SIZE*2)-1-1:`MA_TREE_SIZE-1] = `MA_TREE_SIZE'd0;

always@(posedge clock) begin
	in_add_vector_wire0 <= in[`CONV_MULT_WIDTH*1-1:0] * kernal[`CONV_MULT_WIDTH*1-1:0];
	in_add_vector_wire1 <= in[`CONV_MULT_WIDTH*2-1:`CONV_MULT_WIDTH] * kernal[`CONV_MULT_WIDTH*2-1:`CONV_MULT_WIDTH];
	in_add_vector_wire2 <= in[`CONV_MULT_WIDTH*3-1:2*`CONV_MULT_WIDTH] * kernal[`CONV_MULT_WIDTH*3-1:2*`CONV_MULT_WIDTH];
end

assign adder_tree_wire2[`CONV_PRODUCT_WIDTH-1:0] = in_add_vector_wire0;
assign adder_tree_wire3[`CONV_PRODUCT_WIDTH-1:0] = in_add_vector_wire0;

endmodule

