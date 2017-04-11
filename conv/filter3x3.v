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
  output [23:0] out
  );
  
  reg [23:0] fout;

  reg [23:0] DataLine1;
  reg [23:0] DataLine2;
  reg [23:0] DataLine3;
  
  reg  [23:0] fLine1;
  reg  [23:0] fLine2;
  reg  [23:0] fLine3;
  
  reg [23:0] mulLine1;
  reg [23:0] mulLine2;
  reg [23:0] mulLine3;
 
 always @(posedge clk or posedge rst) begin
  if(rst) begin
    //reset registers
    DataLine1 <= 24'b0;
    DataLine2 <= 24'b0;
    DataLine3 <= 24'b0;
    
    fLine1 <= 24'b0;
    fLine2 <= 24'b0;
    fLine3 <= 24'b0;
       
    mulLine1 <= 24'b0;
    mulLine2 <= 24'b0;
    mulLine3 <= 24'b0;

    fout = 0;
    
  end
end
 
assign out = fout;
  
always @(posedge clk) begin
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
  mulLine1[7:0]   <= DataLine1[7:0]   * fLine1[7:0];
  mulLine1[15:8]  <= DataLine1[15:8]  * fLine1[15:8];
  mulLine1[23:16] <= DataLine1[23:16] * fLine1[23:16];
    
  mulLine2[7:0]   <= DataLine2[7:0]   * fLine2[7:0];
  mulLine2[15:8]  <= DataLine2[15:8]  * fLine2[15:8];
  mulLine2[23:16] <= DataLine2[23:16] * fLine2[23:16];
    
  mulLine3[7:0]   <= DataLine3[7:0]   * fLine3[7:0];
  mulLine3[15:8]  <= DataLine3[15:8]  * fLine3[15:8];
  mulLine3[23:16] <= DataLine3[23:16] * fLine3[23:16];
    
  // clk3
  // addition
  fout <= mulLine1[7:0] + mulLine1[15:8] + mulLine1[23:16]
        + mulLine2[7:0] + mulLine2[15:8] + mulLine2[23:16]
        + mulLine3[7:0] + mulLine3[15:8] + mulLine3[23:16];
    
end

endmodule
