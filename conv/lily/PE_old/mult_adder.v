`include "bit_width.vh"

module mult_adder(
	input clock,
	input reset,
	input[`MULT_ADDER_IN_WIDTH-1:0] in,
	input[`MULT_ADDER_IN_WIDTH-1:0] kernel,
	output[`CONV_ADD_WIDTH-1:0] out
	);

//wire declaration
//CONV_TN = 3
wire [`CONV_PRODUCT_WIDTH-1:0] in_add_wire0;
wire [`CONV_PRODUCT_WIDTH-1:0] in_add_wire1;
wire [`CONV_PRODUCT_WIDTH-1:0] in_add_wire2;

// assign statment s
assign out = in_add_wire0 + in_add_wire1 + in_add_wire2;

mult_two ma1(.clock(clock),.reset(reset),
.op_a(in[`CONV_MULT_WIDTH-1:0]),
.op_b(kernel[`CONV_MULT_WIDTH-1:0]),
.out(in_add_wire0));

mult_two ma2(.clock(clock),.reset(reset),
.op_a(in[`CONV_MULT_WIDTH*2-1:`CONV_MULT_WIDTH]),
.op_b(kernel[`CONV_MULT_WIDTH*2-1:`CONV_MULT_WIDTH]),
.out(in_add_wire1));

mult_two ma3(.clock(clock),.reset(reset),
.op_a(in[`CONV_MULT_WIDTH*3-1:`CONV_MULT_WIDTH*2]),
.op_b(kernel[`CONV_MULT_WIDTH*3-1:`CONV_MULT_WIDTH*2]),
.out(in_add_wire2));

endmodule

module mult_two(
    input clock,
    input reset,
    input [`CONV_MULT_WIDTH-1:0] op_a,
    input [`CONV_MULT_WIDTH-1:0] op_b,
    output [`CONV_PRODUCT_WIDTH-1:0] out
    );
    reg [`CONV_PRODUCT_WIDTH-1:0] product;
    assign out = product;
    
    always@(posedge clock or negedge reset)
    begin
        if(reset == 1'b0)
            product <= `CONV_PRODUCT_WIDTH'd0;
        else
            product <= op_a * op_b;
    end
endmodule
