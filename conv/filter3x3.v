`include "bit_width.vh"

module filter3x3(
  //data matrix
  input [`IMG_DATA_LINE_WIDTH - 1:0] inLine1,
  input [`IMG_DATA_LINE_WIDTH - 1:0] inLine2,
  input [`IMG_DATA_LINE_WIDTH - 1:0] inLine3,
   
  //filter
  input [`IMG_DATA_LINE_WIDTH - 1:0] filterLine1,
  input [`IMG_DATA_LINE_WIDTH - 1:0] filterLine2,
  input [`IMG_DATA_LINE_WIDTH - 1:0] filterLine3,

  input clk,
  input rst,
  output [`IMG_DATA_WIDTH * 2- 1:0] out
  );
  
  reg [`IMG_DATA_WIDTH * 2 - 1:0] fout;

  reg [`IMG_DATA_LINE_WIDTH - 1:0] DataLine1;
  reg [`IMG_DATA_LINE_WIDTH - 1:0] DataLine2;
  reg [`IMG_DATA_LINE_WIDTH - 1:0] DataLine3;
  
  reg  [`IMG_DATA_LINE_WIDTH - 1:0] fLine1;
  reg  [`IMG_DATA_LINE_WIDTH - 1:0] fLine2;
  reg  [`IMG_DATA_LINE_WIDTH - 1:0] fLine3;
  
  reg [`IMG_DATA_LINE_WIDTH - 1:0] mulLine1;
  reg [`IMG_DATA_LINE_WIDTH - 1:0] mulLine2;
  reg [`IMG_DATA_LINE_WIDTH - 1:0] mulLine3;
  
  wire [`IMG_DATA_LINE_WIDTH - 1:0] mult_1;  
  wire [`IMG_DATA_LINE_WIDTH - 1:0] mult_2;
  wire [`IMG_DATA_LINE_WIDTH - 1:0] mult_3;
  
  // 8 bits, signed integer
  mult_gen_signed_8 mult11(.CLK(clk), .A(DataLine1[`IMG_DATA_WIDTH - 1:0]),   .B(fLine1[`IMG_DATA_WIDTH - 1:0]),   .P(mult_1[`IMG_DATA_WIDTH - 1:0]));
  mult_gen_signed_8 mult12(.CLK(clk), .A(DataLine1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),  .B(fLine1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),  .P(mult_1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]));
  mult_gen_signed_8 mult13(.CLK(clk), .A(DataLine1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]), .B(fLine1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]), .P(mult_1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]));
  
  mult_gen_signed_8 mult21(.CLK(clk), .A(DataLine2[`IMG_DATA_WIDTH - 1:0]),   .B(fLine2[`IMG_DATA_WIDTH - 1:0]),   .P(mult_2[`IMG_DATA_WIDTH - 1:0]));
  mult_gen_signed_8 mult22(.CLK(clk), .A(DataLine2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),  .B(fLine2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),  .P(mult_2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]));                                                                                          
  mult_gen_signed_8 mult23(.CLK(clk), .A(DataLine2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]), .B(fLine2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]), .P(mult_2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]));
  
  mult_gen_signed_8 mult31(.CLK(clk), .A(DataLine3[`IMG_DATA_WIDTH - 1:0]),   .B(fLine3[`IMG_DATA_WIDTH - 1:0]),   .P(mult_3[`IMG_DATA_WIDTH - 1:0]));
  mult_gen_signed_8 mult32(.CLK(clk), .A(DataLine3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),  .B(fLine3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),  .P(mult_3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]));
  mult_gen_signed_8 mult33(.CLK(clk), .A(DataLine3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]), .B(fLine3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]), .P(mult_3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]));
  
  // 16 bits, float  
  /*
  floating_point_multiply mult11(.aclk(clk), 
                          .s_axis_a_tdata(DataLine1[`IMG_DATA_WIDTH - 1:0]), 
                          .s_axis_a_tvalid(clk),
                          .s_axis_a_tready(clk),
                          .s_axis_b_tdata(fLine1[`IMG_DATA_WIDTH - 1:0]), 
                          .s_axis_b_tvalid(clk),
                          .s_axis_b_tready(clk),
                          .m_axis_result_tdata(mult_1[`IMG_DATA_WIDTH - 1:0]),
                          .m_axis_result_tvalid(clk),
                          .m_axis_result_tready(clk));
 
 floating_point_multiply mult11(.aclk(clk), 
                           .s_axis_a_tdata(DataLine1[`IMG_DATA_WIDTH - 1:0]),
                           .s_axis_b_tdata(fLine1[`IMG_DATA_WIDTH - 1:0]),
                           .m_axis_result_tdata(mult_1[`IMG_DATA_WIDTH - 1:0]));
                       
  floating_point_multiply mult12(.aclk(clk), 
                          .s_axis_a_tdata(DataLine1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),
                          .s_axis_b_tdata(fLine1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),
                          .m_axis_result_tdata(mult_1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]));
  floating_point_multiply mult13(.aclk(clk), 
                          .s_axis_a_tdata(DataLine1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]),
                          .s_axis_b_tdata(fLine1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]),
                          .m_axis_result_tdata(mult_1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]));

  floating_point_multiply mult21(.aclk(clk), 
                          .s_axis_a_tdata(DataLine2[`IMG_DATA_WIDTH - 1:0]), 
                          .s_axis_b_tdata(fLine2[`IMG_DATA_WIDTH - 1:0]), 
                          .m_axis_result_tdata(mult_2[`IMG_DATA_WIDTH - 1:0]));
  floating_point_multiply mult22(.aclk(clk), 
                          .s_axis_a_tdata(DataLine2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),
                          .s_axis_b_tdata(fLine2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),
                          .m_axis_result_tdata(mult_2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]));
  floating_point_multiply mult23(.aclk(clk), 
                          .s_axis_a_tdata(DataLine2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]),
                          .s_axis_b_tdata(fLine2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]),
                          .m_axis_result_tdata(mult_2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]));

  floating_point_multiply mult31(.aclk(clk), 
                          .s_axis_a_tdata(DataLine3[`IMG_DATA_WIDTH - 1:0]), 
                          .s_axis_b_tdata(fLine3[`IMG_DATA_WIDTH - 1:0]), 
                          .m_axis_result_tdata(mult_3[`IMG_DATA_WIDTH - 1:0]));
  floating_point_multiply mult32(.aclk(clk), 
                          .s_axis_a_tdata(DataLine3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),
                          .s_axis_b_tdata(fLine3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]),
                          .m_axis_result_tdata(mult_3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]));
  floating_point_multiply mult33(.aclk(clk), 
                          .s_axis_a_tdata(DataLine3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]),
                          .s_axis_b_tdata(fLine3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]),
                          .m_axis_result_tdata(mult_3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2])); 
 */
 
 always @(posedge clk or posedge rst) begin
  if(rst) begin
    //reset registers
    DataLine1 = `IMG_DATA_LINE_WIDTH'b0;
    DataLine2 = `IMG_DATA_LINE_WIDTH'b0;
    DataLine3 = `IMG_DATA_LINE_WIDTH'b0;
    
    fLine1 = `IMG_DATA_LINE_WIDTH'b0;
    fLine2 = `IMG_DATA_LINE_WIDTH'b0;
    fLine3 = `IMG_DATA_LINE_WIDTH'b0;
       
    mulLine1 = `IMG_DATA_LINE_WIDTH'b0;
    mulLine2 = `IMG_DATA_LINE_WIDTH'b0;
    mulLine3 = `IMG_DATA_LINE_WIDTH'b0;

    fout = `IMG_DATA_WIDTH * 2'b0;
    
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
//  mulLine1[`IMG_DATA_WIDTH - 1:0]   <= DataLine1[`IMG_DATA_WIDTH - 1:0]   * fLine1[`IMG_DATA_WIDTH - 1:0];
  mulLine1[`IMG_DATA_WIDTH - 1:0]                        <= mult_1[`IMG_DATA_WIDTH - 1:0];
  mulLine1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]      <= mult_1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH];
  mulLine1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2] <= mult_1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2];
    
  mulLine2[`IMG_DATA_WIDTH - 1:0]                        <= mult_2[`IMG_DATA_WIDTH - 1:0];
  mulLine2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]      <= mult_2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH];
  mulLine2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2] <= mult_2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2];
    
  mulLine3[`IMG_DATA_WIDTH - 1:0]                        <= mult_3[`IMG_DATA_WIDTH - 1:0];
  mulLine3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH]      <= mult_3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH];
  mulLine3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2] <= mult_3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2];
  
  // clk3
  // addition
  fout <= mulLine1[`IMG_DATA_WIDTH - 1:0] + mulLine1[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH] + mulLine1[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]
        + mulLine2[`IMG_DATA_WIDTH - 1:0] + mulLine2[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH] + mulLine2[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2]
        + mulLine3[`IMG_DATA_WIDTH - 1:0] + mulLine3[`IMG_DATA_WIDTH * 2 - 1:`IMG_DATA_WIDTH] + mulLine3[`IMG_DATA_LINE_WIDTH - 1:`IMG_DATA_WIDTH * 2];
    
 end

endmodule
