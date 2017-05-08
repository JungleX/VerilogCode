`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/08 11:10:12
// Design Name: 
// Module Name: floating_point_compare_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module floating_point_compare_tb();
    reg clock;
    
    reg[15:0] com_a_data;
    wire com_a_ready;
    reg com_a_valid;
    
    reg[15:0] com_b_data;
    wire com_b_ready;
    reg com_b_valid;
    
    wire[7:0] com_re_data;
    reg com_re_ready;
    wire com_re_valid;
   
   // if non-blocking mode is selected, there is no tready
   // if latency is 0, there is no aclk
   // when a>b, com_re_data[0] = 1; otherwise com_re_data[0] = 0
    floating_point_compare fpc(
//        .aclk(clock),
        .s_axis_a_tvalid(com_a_valid),
//        .s_axis_a_tready(com_a_ready),
        .s_axis_a_tdata(com_a_data),
        .s_axis_b_tvalid(com_b_valid),
//        .s_axis_b_tready(com_b_ready),
        .s_axis_b_tdata(com_b_data),
        .m_axis_result_tvalid(com_re_valid),
//        .m_axis_result_tready(com_re_ready),
        .m_axis_result_tdata(com_re_data)
    );      

    initial 
    begin
        clock = 1'b1;
        repeat (20) clock = #5 ~clock;
    end

 initial 
    begin
    #0
    com_a_valid = 1;
    com_a_data = 16'b0000000000000000; // 0
    com_b_valid = 1;
    com_b_data = 16'b1100101001000000; //-12.5
    com_re_ready = 1;

    #10
    com_a_valid = 1;
    com_a_data = 16'b1100101001000000; //-12.5
    com_b_valid = 1;
    com_b_data = 16'b0000000000000000; // 0

    #10
    com_a_valid = 1;
    com_a_data = 16'b0100101001000000; // 12.5
    com_b_valid = 1;
    com_b_data = 16'b0000000000000000; // 0
    
    #10
    com_a_valid = 1;
    com_a_data = 16'b0100100100010000; // 10.125
    com_b_valid = 1;
    com_b_data = 16'b0100101001000000; // 12.5
    
end
      
endmodule
