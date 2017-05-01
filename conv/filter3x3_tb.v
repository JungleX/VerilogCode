`timescale 1ns/1ns

module filter3x3_tb();
  reg clk, rst, ena;
  reg  [`IMG_DATA_MATRIX_WIDTH -1:0] inMatrix;
  reg [`IMG_DATA_MATRIX_WIDTH -1:0] filterMatrix;
  wire [`IMG_DATA_WIDTH * 2 - 1:0] out;
  
  filter3x3 u0(
    .ena(ena),
    .clk(clk),
    .rst(rst),
    .inMatrix(inMatrix),
    .filterMatrix(filterMatrix),
    .out(out) 
  );
  
initial 
begin
  clk = 1'b1;
  repeat (20) clk = #5 ~clk;
end

initial
begin
  #0
  ena = 1'b1;
  rst = 1'b1;

  #10
  rst = 1'b0;
  inMatrix = {`NUM_1, `NUM_2, `NUM_1, `NUM_2, `NUM_1, `NUM_1, `NUM_1, `NUM_1, `NUM_2};
// 1 2 1
// 2 1 1
// 1 1 2  
  filterMatrix = {`NUM_1, `NUM_1, `NUM_1, `NUM_1, `NUM_1, `NUM_1, `NUM_1, `NUM_1, `NUM_1};
// 1 1 1
// 1 1 1
// 1 1 1 
  
  #10
  rst = 1'b0;
  inMatrix = {`NUM_2, `NUM_2, `NUM_1, `NUM_1, `NUM_1, `NUM_1, `NUM_1, `NUM_2, `NUM_2};
// 2 2 1
// 1 1 1 
// 1 2 2   
  filterMatrix = {`NUM_2, `NUM_1, `NUM_1, `NUM_2, `NUM_2, `NUM_2, `NUM_1, `NUM_1, `NUM_2};
// 2 1 1 
// 2 2 2
// 1 1 2

    #30
    rst = 1'b1;
  
end

endmodule
