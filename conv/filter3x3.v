module filter3x3(
  //data matrix
  input [23:0] inLine1,
  input [23:0] inLine2,
  input [23:0] inLine3,
  
  //filter
  input [23:0] filterLine1,
  input [23:0] filterLine2,
  input [23:0] filterLine3,

  input clk,
  input rst,
  output [15:0] out
  );
  
  reg [15:0] fout;

  reg [23:0] DataLine1;
  reg [23:0] DataLine2;
  reg [23:0] DataLine3;
  
  reg  [23:0] fLine1;
  reg  [23:0] fLine2;
  reg  [23:0] fLine3;
  
  reg [23:0] mulLine1;
  reg [23:0] mulLine2;
  reg [23:0] mulLine3;
  
  wire [23:0] mult_1;  
  wire [23:0] mult_2;
  wire [23:0] mult_3;
  
  mult_gen_signed_8 mult11(.CLK(clk), .A(DataLine1[7:0]),   .B(fLine1[7:0]),   .P(mult_1[7:0]));
  mult_gen_signed_8 mult12(.CLK(clk), .A(DataLine1[15:8]),  .B(fLine1[15:8]),  .P(mult_1[15:8]));
  mult_gen_signed_8 mult13(.CLK(clk), .A(DataLine1[23:16]), .B(fLine1[23:16]), .P(mult_1[23:16]));
  
  mult_gen_signed_8 mult21(.CLK(clk), .A(DataLine2[7:0]),   .B(fLine2[7:0]),   .P(mult_2[7:0]));
  mult_gen_signed_8 mult22(.CLK(clk), .A(DataLine2[15:8]),  .B(fLine2[15:8]),  .P(mult_2[15:8]));                                                                                          
  mult_gen_signed_8 mult23(.CLK(clk), .A(DataLine2[23:16]), .B(fLine2[23:16]), .P(mult_2[23:16]));
  
  mult_gen_signed_8 mult31(.CLK(clk), .A(DataLine3[7:0]),   .B(fLine3[7:0]),   .P(mult_3[7:0]));
  mult_gen_signed_8 mult32(.CLK(clk), .A(DataLine3[15:8]),  .B(fLine3[15:8]),  .P(mult_3[15:8]));
  mult_gen_signed_8 mult33(.CLK(clk), .A(DataLine3[23:16]), .B(fLine3[23:16]), .P(mult_3[23:16]));
  
 always @(posedge clk or posedge rst) begin
  if(rst) begin
    //reset registers
    DataLine1 = 24'b0;
    DataLine2 = 24'b0;
    DataLine3 = 24'b0;
    
    fLine1 = 24'b0;
    fLine2 = 24'b0;
    fLine3 = 24'b0;
       
    mulLine1 = 24'b0;
    mulLine2 = 24'b0;
    mulLine3 = 24'b0;

    fout = 0;
    
  end
end
 
assign out = fout;
  
always @(negedge clk) begin
//always @(clk) begin
  // clk1
  // load input matrix and filter data to DataLine and fLine
  DataLine1 <= inLine1;
  DataLine2 <= inLine2;
  DataLine3 <= inLine3;
  fLine1 <= filterLine1;
  fLine2 <= filterLine2;
  fLine3 <= filterLine3;

  // clk2
  //  multiplication
//  mulLine1[7:0]   <= DataLine1[7:0]   * fLine1[7:0];
  mulLine1[7:0]   <= mult_1[7:0];
  mulLine1[15:8]  <= mult_1[15:8];
  mulLine1[23:16] <= mult_1[23:16];
    
  mulLine2[7:0]   <= mult_2[7:0];
  mulLine2[15:8]  <= mult_2[15:8];
  mulLine2[23:16] <= mult_2[23:16];
    
  mulLine3[7:0]   <= mult_3[7:0];
  mulLine3[15:8]  <= mult_3[15:8];
  mulLine3[23:16] <= mult_3[23:16];
  
  // clk3
  // addition
  fout <= mulLine1[7:0] + mulLine1[15:8] + mulLine1[23:16]
        + mulLine2[7:0] + mulLine2[15:8] + mulLine2[23:16]
        + mulLine3[7:0] + mulLine3[15:8] + mulLine3[23:16];
    
end

endmodule
