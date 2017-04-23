`include "network_params.vh"

module sub_sample( // Max pooling
    input clk,
    input reset,
    input [`NH_VECTOR_BITWIDTH:0] nh_vector,
    output reg[`POOL_OUT_BITWIDTH:0] pool_out
);

//NEIGHBORHOOD_SIZE ^ 2              
wire [`POOL_OUT_BITWIDTH:0] adder_tree_wire0;
wire [`POOL_OUT_BITWIDTH:0] adder_tree_wire1;
wire [`POOL_OUT_BITWIDTH:0] adder_tree_wire2;
wire [`POOL_OUT_BITWIDTH:0] adder_tree_wire3;

reg [`POOL_OUT_BITWIDTH:0] adder_tree_reg0;
reg [`POOL_OUT_BITWIDTH:0] adder_tree_reg1;
reg [`POOL_OUT_BITWIDTH:0] adder_tree_reg2;
reg [`POOL_OUT_BITWIDTH:0] adder_tree_reg3;
reg [`POOL_OUT_BITWIDTH:0] adder_tree_reg4;

pool_cmp2 pool_cmp2_inst0(
    .clock(clk),
    .reset(reset),
    .operand_a(nh_vector[`NN_BITWIDTH:0]),
    .operand_b(nh_vector[`NN_WIDTH*2-1:`NN_WIDTH]),
    .out(adder_tree_wire0)
);
pool_cmp2 pool_cmp2_inst1(
    .clock(clk),
    .reset(reset),
    .operand_a(nh_vector[`NN_WIDTH*3-1:`NN_WIDTH*2]),
    .operand_b(nh_vector[`NN_WIDTH*4-1:`NN_WIDTH*3]),
    .out(adder_tree_wire1)
);
pool_cmp2 pool_cmp2_inst2(
    .clock(clk),
    .reset(reset),
    .operand_a(nh_vector[`NN_WIDTH*5-1:`NN_WIDTH*4]),
    .operand_b(nh_vector[`NN_WIDTH*6-1:`NN_WIDTH*5]),
    .out(adder_tree_wire2)
);

pool_cmp2 pool_cmp2_inst3(
    .clock(clk),
    .reset(reset),
    .operand_a(nh_vector[`NN_WIDTH*7-1:`NN_WIDTH*6]),
    .operand_b(nh_vector[`NN_WIDTH*8-1:`NN_WIDTH*7]),
    .out(adder_tree_wire3)
);

/*assign adder_tree_wire1 = {nh_vector[`NN_BITWIDTH:0] };
assign adder_tree_wire2 = {nh_vector[`NN_WIDTH*2-1:`NN_WIDTH] };
assign adder_tree_wire3 = {nh_vector[`NN_WIDTH*3-1:`NN_WIDTH*2] };
assign adder_tree_wire4 = {nh_vector[`NN_WIDTH*4-1:`NN_WIDTH*3] };
assign adder_tree_wire5 = {nh_vector[`NN_WIDTH*5-1:`NN_WIDTH*4] };
assign adder_tree_wire6 = {nh_vector[`NN_WIDTH*6-1:`NN_WIDTH*5] };
assign adder_tree_wire7 = {nh_vector[`NN_WIDTH*7-1:`NN_WIDTH*6] };
assign adder_tree_wire8 = {nh_vector[`NN_WIDTH*8-1:`NN_WIDTH*7] };
assign adder_tree_wire9 = {nh_vector[`NN_WIDTH*9-1:`NN_WIDTH*8] };*/

always@(posedge clk or negedge reset) begin
    if(reset == 1'b0) 
        pool_out <= `POOL_OUT_WIDTH'd0;
    else begin
        adder_tree_reg0 = (adder_tree_wire0 >= adder_tree_wire1)?adder_tree_wire0:adder_tree_wire1;
        adder_tree_reg1 = (adder_tree_wire2 >= adder_tree_wire3)?adder_tree_wire2:adder_tree_wire3;
        adder_tree_reg3 = (adder_tree_reg0 >= adder_tree_reg1)?adder_tree_reg0:adder_tree_reg1;
        pool_out = (adder_tree_reg3 >= nh_vector[`NN_WIDTH*9-1:`NN_WIDTH*8])?adder_tree_reg3:nh_vector[`NN_WIDTH*9-1:`NN_WIDTH*8];
    end
end

endmodule

//进行两两比较
module pool_cmp2(
    input clock,
    input reset,
    
    input [`POOL_OUT_BITWIDTH:0] operand_a,
    input [`POOL_OUT_BITWIDTH:0] operand_b,
    output reg[`POOL_OUT_BITWIDTH:0] out 
);

always@(posedge clock or negedge reset) begin
    if(reset == 1'b0) 
        out <= `POOL_OUT_WIDTH'd0;
    else
        out <= (operand_a >= operand_b)?operand_a:operand_b;
end
endmodule