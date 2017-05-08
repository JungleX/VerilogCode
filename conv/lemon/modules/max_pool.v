`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/02 19:44:52
// Design Name: 
// Module Name: max_pool
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//     get the max number of 3x3 matrix at 5th negedge clk
//     output the max number at 6th posedge clk
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "cnn_parameters.vh"

module max_pool(
    input clk,
    input ena,
    input reset,
    input [`NH_VECTOR_WIDTH - 1:0] in_vector,
    output [`POOL_OUT_WIDTH - 1:0] pool_out
    );
    reg [`POOL_OUT_WIDTH - 1:0] pool_out;
    
    reg com_a_valid;
    reg com_b_valid;
    
    reg [`NH_VECTOR_WIDTH - 1:0] nh_vector;
    
    reg [`NN_WIDTH - 1:0] com_num_0;
    reg [`NN_WIDTH - 1:0] com_num_1;
    reg [`NN_WIDTH - 1:0] com_num_2;
    reg [`NN_WIDTH - 1:0] com_num_3;
    
    reg [`NN_WIDTH - 1:0] com_num_4;
    reg [`NN_WIDTH - 1:0] com_num_5;
    
    reg [`NN_WIDTH - 1:0] com_num_6;
    
    reg [`NN_WIDTH - 1:0] com_num_7;
    
    wire [`COMPARE_RESULT_WIDTH - 1:0] adder_tree_wire0;
    wire [`COMPARE_RESULT_WIDTH - 1:0] adder_tree_wire1;
    wire [`COMPARE_RESULT_WIDTH - 1:0] adder_tree_wire2;
    wire [`COMPARE_RESULT_WIDTH - 1:0] adder_tree_wire3;
    
    wire [`COMPARE_RESULT_WIDTH - 1:0] adder_tree_wire4;
    wire [`COMPARE_RESULT_WIDTH - 1:0] adder_tree_wire5;
    
    wire [`COMPARE_RESULT_WIDTH - 1:0] adder_tree_wire6;
    
    wire [`COMPARE_RESULT_WIDTH - 1:0] adder_tree_wire7;
    
    floating_point_compare fpc0(
     .s_axis_a_tvalid(com_a_valid),
     .s_axis_a_tdata(nh_vector[`NN_WIDTH - 1:0]),
     .s_axis_b_tvalid(com_b_valid),
     .s_axis_b_tdata(nh_vector[`NN_WIDTH*2-1:`NN_WIDTH]),
     .m_axis_result_tvalid(com_re_valid),
     .m_axis_result_tdata(adder_tree_wire0)
    );
  
    floating_point_compare fpc1(
        .s_axis_a_tvalid(com_a_valid),
        .s_axis_a_tdata(nh_vector[`NN_WIDTH*3 - 1:`NN_WIDTH*2] ),
        .s_axis_b_tvalid(com_b_valid),
        .s_axis_b_tdata(nh_vector[`NN_WIDTH*4 - 1:`NN_WIDTH*3]),
        .m_axis_result_tvalid(com_re_valid),
        .m_axis_result_tdata(adder_tree_wire1)
    );  

    floating_point_compare fpc2(
        .s_axis_a_tvalid(com_a_valid),
        .s_axis_a_tdata(nh_vector[`NN_WIDTH*5 - 1:`NN_WIDTH*4]),
        .s_axis_b_tvalid(com_b_valid),
        .s_axis_b_tdata(nh_vector[`NN_WIDTH*6 - 1:`NN_WIDTH*5]),
        .m_axis_result_tvalid(com_re_valid),
        .m_axis_result_tdata(adder_tree_wire2)
    ); 
 
     floating_point_compare fpc3(
        .s_axis_a_tvalid(com_a_valid),
        .s_axis_a_tdata(nh_vector[`NN_WIDTH*7 - 1:`NN_WIDTH*6]),
        .s_axis_b_tvalid(com_b_valid),
        .s_axis_b_tdata(nh_vector[`NN_WIDTH*8 - 1:`NN_WIDTH*7]),
        .m_axis_result_tvalid(com_re_valid),
        .m_axis_result_tdata(adder_tree_wire3)
    ); 
 
     floating_point_compare fpc4(
       .s_axis_a_tvalid(com_a_valid),
       .s_axis_a_tdata(com_num_0),
       .s_axis_b_tvalid(com_b_valid),
       .s_axis_b_tdata(com_num_1),
       .m_axis_result_tvalid(com_re_valid),
       .m_axis_result_tdata(adder_tree_wire4)
    );

     floating_point_compare fpc5(
        .s_axis_a_tvalid(com_a_valid),
        .s_axis_a_tdata(com_num_2),
        .s_axis_b_tvalid(com_b_valid),
        .s_axis_b_tdata(com_num_3),
        .m_axis_result_tvalid(com_re_valid),
        .m_axis_result_tdata(adder_tree_wire5)
    ); 
 
     floating_point_compare fpc6(
       .s_axis_a_tvalid(com_a_valid),
       .s_axis_a_tdata(com_num_4),
       .s_axis_b_tvalid(com_b_valid),
       .s_axis_b_tdata(com_num_5),
       .m_axis_result_tvalid(com_re_valid),
       .m_axis_result_tdata(adder_tree_wire6)
    );
    
    floating_point_compare fpc7(
           .s_axis_a_tvalid(com_a_valid),
           .s_axis_a_tdata(com_num_6),
           .s_axis_b_tvalid(com_b_valid),
           .s_axis_b_tdata(nh_vector[`NN_WIDTH*9-1:`NN_WIDTH*8]),
           .m_axis_result_tvalid(com_re_valid),
           .m_axis_result_tdata(adder_tree_wire7)
    );
  
  
    //assign pool_out = com_num_7;
    
    always @(posedge clk or posedge reset) begin
            if(!reset) begin
                com_a_valid <= 0;
                com_b_valid <= 0;
            
                com_num_0 <= 0;
                com_num_1 <= 0;
                com_num_2 <= 0;
                com_num_3 <= 0;
               
                com_num_4 <= 0;
                com_num_5 <= 0;
                
                com_num_6 <= 0;
                
                com_num_7 <= 0;
            end    
            else begin
                pool_out <= com_num_7;
            end
    end
    
     always @(negedge clk) begin
       //always @(posedge clk) begin
           if(ena) begin
                com_a_valid <= 1;
                com_b_valid <= 1;
                           
                // clk 1
                nh_vector <= in_vector[`NH_VECTOR_WIDTH - 1:0];
                
                // clk 2
                com_num_0 <= adder_tree_wire0[0] == 1 ? nh_vector[`NN_WIDTH - 1:0]             : nh_vector[`NN_WIDTH*2-1:`NN_WIDTH];
                com_num_1 <= adder_tree_wire1[0] == 1 ? nh_vector[`NN_WIDTH*3 - 1:`NN_WIDTH*2] : nh_vector[`NN_WIDTH*4 - 1:`NN_WIDTH*3];
                com_num_2 <= adder_tree_wire2[0] == 1 ? nh_vector[`NN_WIDTH*5 - 1:`NN_WIDTH*4] : nh_vector[`NN_WIDTH*6 - 1:`NN_WIDTH*5];
                com_num_3 <= adder_tree_wire3[0] == 1 ? nh_vector[`NN_WIDTH*7 - 1:`NN_WIDTH*6] : nh_vector[`NN_WIDTH*8 - 1:`NN_WIDTH*7];
                
                // clk 3
                com_num_4 <= adder_tree_wire4[0] == 1 ? com_num_0 : com_num_1;
                com_num_5 <= adder_tree_wire5[0] == 1 ? com_num_2 : com_num_3;
                
                // clk 4
                com_num_6 <= adder_tree_wire6[0] == 1 ? com_num_4 : com_num_5;
                
                // clk 5
                com_num_7 <= adder_tree_wire7[0] == 1 ? com_num_6 : nh_vector[`NN_WIDTH*9-1:`NN_WIDTH*8];
           end
    end
    
    // integer compare        
//    assign adder_tree_wire0 = (nh_vector[`NN_WIDTH - 1:0] >= nh_vector[`NN_WIDTH*2-1:`NN_WIDTH])?nh_vector[`NN_WIDTH - 1:0]:nh_vector[`NN_WIDTH*2-1:`NN_WIDTH];
//    assign adder_tree_wire1 = (nh_vector[`NN_WIDTH*3 - 1:`NN_WIDTH*2] >= nh_vector[`NN_WIDTH*4 - 1:`NN_WIDTH*3])?nh_vector[`NN_WIDTH*3 - 1:`NN_WIDTH*2]:nh_vector[`NN_WIDTH*4 - 1:`NN_WIDTH*3];
//    assign adder_tree_wire2 = (nh_vector[`NN_WIDTH*5 - 1:`NN_WIDTH*4] >= nh_vector[`NN_WIDTH*6 - 1:`NN_WIDTH*5])?nh_vector[`NN_WIDTH*5 - 1:`NN_WIDTH*4]:nh_vector[`NN_WIDTH*6 - 1:`NN_WIDTH*5];
//    assign adder_tree_wire3 = (nh_vector[`NN_WIDTH*7 - 1:`NN_WIDTH*6] >= nh_vector[`NN_WIDTH*8 - 1:`NN_WIDTH*7])?nh_vector[`NN_WIDTH*7 - 1:`NN_WIDTH*6]:nh_vector[`NN_WIDTH*8 - 1:`NN_WIDTH*7];
    
//    assign adder_tree_wire4 = (adder_tree_wire0 >= adder_tree_wire1)?adder_tree_wire0:adder_tree_wire1;
//    assign adder_tree_wire5 = (adder_tree_wire2 >= adder_tree_wire3)?adder_tree_wire2:adder_tree_wire3;
    
//    assign adder_tree_wire6 = (adder_tree_wire4 >= adder_tree_wire5)?adder_tree_wire4:adder_tree_wire5;
             
//    assign pool_out = (adder_tree_wire6 >= nh_vector[`NN_WIDTH*9-1:`NN_WIDTH*8])?adder_tree_wire6:nh_vector[`NN_WIDTH*9-1:`NN_WIDTH*8];
    
endmodule
