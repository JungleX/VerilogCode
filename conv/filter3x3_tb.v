`timescale 1ns/1ns

module filter3x3_tb();
  reg clk, rst;
  
  reg [`IMG_DATA_LINE_WIDTH - 1:0] inLine1;
  reg [`IMG_DATA_LINE_WIDTH - 1:0] inLine2;
  reg [`IMG_DATA_LINE_WIDTH - 1:0] inLine3;
  
  reg [`IMG_DATA_LINE_WIDTH - 1:0] filterLine1;
  reg [`IMG_DATA_LINE_WIDTH - 1:0] filterLine2;
  reg [`IMG_DATA_LINE_WIDTH - 1:0] filterLine3;
  
  wire [`IMG_DATA_WIDTH * 2 - 1:0] out;
  
  filter3x3 u0(
    .inLine1(inLine1),
    .inLine2(inLine2),
    .inLine3(inLine3),
  
    .filterLine1(filterLine1),
    .filterLine2(filterLine2),
    .filterLine3(filterLine3),
  
    .clk(clk),
    .rst(rst),
    .out(out)
  );
  
initial 
begin
  clk = 1'b1;
  repeat (20) clk = #5 ~clk;
end
/*
always @(posedge clk ) 
begin
  $display("data:");
  $display("%d %d %d", inLine1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2], inLine1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH], inLine1[`IMG_DATA_WIDTH - 1:0]);
  $display("%d %d %d", inLine2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2], inLine2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH], inLine2[`IMG_DATA_WIDTH - 1:0]);
  $display("%d %d %d", inLine3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2], inLine3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH], inLine3[`IMG_DATA_WIDTH - 1:0]);
  
  $display("filter:");
  $display("%d %d %d", filterLine1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2], filterLine1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH], filterLine1[`IMG_DATA_WIDTH - 1:0]);
  $display("%d %d %d", filterLine2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2], filterLine2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH], filterLine2[`IMG_DATA_WIDTH - 1:0]);
  $display("%d %d %d", filterLine3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2], filterLine3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH], filterLine3[`IMG_DATA_WIDTH - 1:0]);
  
  $display("out: %d", out);

end
*/
initial
begin
  #0
  rst = 1'b1;

  #10
  rst = 1'b0;

  inLine1 = {`NUM_1, `NUM_2, `NUM_1}; // 1 2 1
  inLine2 = {`NUM_2, `NUM_1, `NUM_1}; // 2 1 1
  inLine3 = {`NUM_1, `NUM_1, `NUM_2}; // 1 1 2
  filterLine1 = {`NUM_1, `NUM_1, `NUM_1};  // 1 1 1
  filterLine2 = {`NUM_1, `NUM_1, `NUM_1};  // 1 1 1 
  filterLine3 = {`NUM_1, `NUM_1, `NUM_1};  // 1 1 1
  
  #10
  inLine1 = {`NUM_1, `NUM_2, `NUM_1}; // 1 2 1
  inLine2 = {`NUM_2, `NUM_1, `NUM_1}; // 2 1 1
  inLine3 = {`NUM_1, `NUM_1, `NUM_2}; // 1 1 2
  filterLine1 = {`NUM_2, `NUM_2, `NUM_2};  // 2 2 2 
  filterLine2 = {`NUM_2, `NUM_2, `NUM_2};  // 2 2 2 
  filterLine3 = {`NUM_2, `NUM_2, `NUM_2};  // 2 2 2
  
end

endmodule
