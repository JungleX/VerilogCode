`define plus 3'd0;
`define minus 3'd1;
`define band 3'd2
`define bor 3'd3;
`define unegate 3'd4

module alu(out,opcode,a,b);
output[7:0] out;
reg[7:0] out;
input[2:0] opcode;
input[7:0] a,b;

