`timescale 1ns/1ns

module filter3x3_tb();
  reg clk, rst;
  
  reg [23:0] inLine1;
  reg [23:0] inLine2;
  reg [23:0] inLine3;
  
  reg [23:0] filterLine1;
  reg [23:0] filterLine2;
  reg [23:0] filterLine3;
  
  wire [23:0] out;
  
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
  clk = 1'b0;
  repeat (20) clk = #5 ~clk;
end


always @(negedge clk ) 
begin
  $display("data:");
  $display("%d %d %d", inLine1[23:16], inLine1[15:8], inLine1[7:0]);
  $display("%d %d %d", inLine2[23:16], inLine2[15:8], inLine2[7:0]);
  $display("%d %d %d", inLine3[23:16], inLine3[15:8], inLine3[7:0]);
  
  $display("filter:");
  $display("%d %d %d", filterLine1[23:16], filterLine1[15:8], filterLine1[7:0]);
  $display("%d %d %d", filterLine2[23:16], filterLine2[15:8], filterLine2[7:0]);
  $display("%d %d %d", filterLine3[23:16], filterLine3[15:8], filterLine3[7:0]);
  
  $display("out: %d", out);
end


initial
begin
/*
  inLine1 = 24'b0;
  inLine2 = 24'b0;
  inLine3 = 24'b0;  
  filterLine1 = 24'b0;
  filterLine2 = 24'b0;
  filterLine3 = 24'b0;
  */
  
//  #10
  inLine1 = {8'b0, 8'b1, 8'b10};
  inLine2 = {8'b1, 8'b1, 8'b10};
  inLine3 = {8'b10, 8'b0, 8'b10};
  filterLine1 = {8'b1, 8'b1, 8'b1};
  filterLine2 = {8'b1, 8'b1, 8'b1};
  filterLine3 = {8'b1, 8'b1, 8'b1};
  
  #10
  inLine1 = {8'b0, 8'b1, 8'b10};
  inLine2 = {8'b1, 8'b1, 8'b10};
  inLine3 = {8'b10, 8'b0, 8'b10};
  filterLine1 = {8'b1, 8'b10, 8'b1};
  filterLine2 = {8'b1, 8'b10, 8'b1};
  filterLine3 = {8'b1, 8'b10, 8'b1};
  
end

endmodule
