`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/25 16:32:58
// Design Name: 
// Module Name: multX11
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// get resulet at 10th posedge clk
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "alexnet_parameters.vh"

module multX11(
	input clk,
    input rst,
    input ena,
 
    input [`CONV_MAX_LINE_SIZE - 1:0] data,     
    
    input [`CONV_MAX_LINE_SIZE - 1:0] weight,    

    output reg [`DATA_WIDTH - 1:0] out
    );

	reg [`CONV_MAX_LINE_SIZE - 1:0] loadData;
	reg [`CONV_MAX_LINE_SIZE - 1:0] loadWeight;
    reg [`DATA_WIDTH - 1:0] mulResult[0:`CONV_MAX - 1];

	wire [`DATA_WIDTH - 1:0] mult[0:`CONV_MAX - 1]; 

    reg mul_a_valid;
    reg mul_b_valid;
    wire mul_re_valid;

    reg [`DATA_WIDTH - 1:0] addDataA1[0:4];
    reg [`DATA_WIDTH - 1:0] addDataB1[0:4];
    wire [`DATA_WIDTH - 1:0] addResult1[0:4];

    reg [`DATA_WIDTH - 1:0] addDataA2[0:2];
    reg [`DATA_WIDTH - 1:0] addDataB2[0:2];
    wire [`DATA_WIDTH - 1:0] addResult2[0:2];

    reg [`DATA_WIDTH - 1:0] addDataA3;
    reg [`DATA_WIDTH - 1:0] addDataB3;
    wire [`DATA_WIDTH - 1:0] addResult3;

    reg [`DATA_WIDTH - 1:0] addDataA4;
    reg [`DATA_WIDTH - 1:0] addDataB4;
    wire [`DATA_WIDTH - 1:0] addResult4;

    reg [`DATA_WIDTH - 1:0] addResultTemp1[0:5];
    reg [`DATA_WIDTH - 1:0] addResultTemp2[0:2];
    reg [`DATA_WIDTH - 1:0] addResultTemp3[0:1];
 
    reg [`DATA_WIDTH - 1:0] temp1;
    reg [`DATA_WIDTH - 1:0] temp2;

    reg add_a_valid;
    reg add_b_valid;
    wire add_re_valid;

    // multiply
    floating_point_multiply mult_0(
        .s_axis_a_tvalid(mul_a_valid),
        .s_axis_a_tdata(loadData[`DATA_WIDTH - 1 :0]),

        .s_axis_b_tvalid(mul_b_valid),
        .s_axis_b_tdata(loadWeight[`DATA_WIDTH - 1 :0]),

        .m_axis_result_tvalid(mul_re_valid),
        .m_axis_result_tdata(mult[0])
        );

    floating_point_multiply mult_1(
        .s_axis_a_tvalid(mul_a_valid),
        .s_axis_a_tdata(loadData[`DATA_WIDTH*2 - 1 :`DATA_WIDTH]),

        .s_axis_b_tvalid(mul_b_valid),
        .s_axis_b_tdata(loadWeight[`DATA_WIDTH*2 - 1 :`DATA_WIDTH]),

        .m_axis_result_tvalid(mul_re_valid),
        .m_axis_result_tdata(mult[1])
        );

    floating_point_multiply mult_2(
        .s_axis_a_tvalid(mul_a_valid),
        .s_axis_a_tdata(loadData[`DATA_WIDTH*3 - 1 :`DATA_WIDTH*2]),

        .s_axis_b_tvalid(mul_b_valid),
        .s_axis_b_tdata(loadWeight[`DATA_WIDTH*3 - 1 :`DATA_WIDTH*2]),

        .m_axis_result_tvalid(mul_re_valid),
        .m_axis_result_tdata(mult[2])
        );

    floating_point_multiply mult_3(
        .s_axis_a_tvalid(mul_a_valid),
        .s_axis_a_tdata(loadData[`DATA_WIDTH*4 - 1 :`DATA_WIDTH*3]),

        .s_axis_b_tvalid(mul_b_valid),
        .s_axis_b_tdata(loadWeight[`DATA_WIDTH*4 - 1 :`DATA_WIDTH*3]),

        .m_axis_result_tvalid(mul_re_valid),
        .m_axis_result_tdata(mult[3])
        );

    floating_point_multiply mult_4(
        .s_axis_a_tvalid(mul_a_valid),
        .s_axis_a_tdata(loadData[`DATA_WIDTH*5 - 1 :`DATA_WIDTH*4]),

        .s_axis_b_tvalid(mul_b_valid),
        .s_axis_b_tdata(loadWeight[`DATA_WIDTH*5 - 1 :`DATA_WIDTH*4]),

        .m_axis_result_tvalid(mul_re_valid),
        .m_axis_result_tdata(mult[4])
        );

    floating_point_multiply mult_5(
        .s_axis_a_tvalid(mul_a_valid),
        .s_axis_a_tdata(loadData[`DATA_WIDTH*6 - 1 :`DATA_WIDTH*5]),

        .s_axis_b_tvalid(mul_b_valid),
        .s_axis_b_tdata(loadWeight[`DATA_WIDTH*6 - 1 :`DATA_WIDTH*5]),

        .m_axis_result_tvalid(mul_re_valid),
        .m_axis_result_tdata(mult[5])
        );

    floating_point_multiply mult_6(
        .s_axis_a_tvalid(mul_a_valid),
        .s_axis_a_tdata(loadData[`DATA_WIDTH*7 - 1 :`DATA_WIDTH*6]),

        .s_axis_b_tvalid(mul_b_valid),
        .s_axis_b_tdata(loadWeight[`DATA_WIDTH*7 - 1 :`DATA_WIDTH*6]),

        .m_axis_result_tvalid(mul_re_valid),
        .m_axis_result_tdata(mult[6])
        );

    floating_point_multiply mult_7(
        .s_axis_a_tvalid(mul_a_valid),
        .s_axis_a_tdata(loadData[`DATA_WIDTH*8 - 1 :`DATA_WIDTH*7]),

        .s_axis_b_tvalid(mul_b_valid),
        .s_axis_b_tdata(loadWeight[`DATA_WIDTH*8 - 1 :`DATA_WIDTH*7]),

        .m_axis_result_tvalid(mul_re_valid),
        .m_axis_result_tdata(mult[7])
        );

    floating_point_multiply mult_8(
        .s_axis_a_tvalid(mul_a_valid),
        .s_axis_a_tdata(loadData[`DATA_WIDTH*9 - 1 :`DATA_WIDTH*8]),

        .s_axis_b_tvalid(mul_b_valid),
        .s_axis_b_tdata(loadWeight[`DATA_WIDTH*9 - 1 :`DATA_WIDTH*8]),

        .m_axis_result_tvalid(mul_re_valid),
        .m_axis_result_tdata(mult[8])
        );

    floating_point_multiply mult_9(
        .s_axis_a_tvalid(mul_a_valid),
        .s_axis_a_tdata(loadData[`DATA_WIDTH*10 - 1 :`DATA_WIDTH*9]),

        .s_axis_b_tvalid(mul_b_valid),
        .s_axis_b_tdata(loadWeight[`DATA_WIDTH*10 - 1 :`DATA_WIDTH*9]),

        .m_axis_result_tvalid(mul_re_valid),
        .m_axis_result_tdata(mult[9])
        );

    floating_point_multiply mult_10(
        .s_axis_a_tvalid(mul_a_valid),
        .s_axis_a_tdata(loadData[`DATA_WIDTH*11 - 1 :`DATA_WIDTH*10]),

        .s_axis_b_tvalid(mul_b_valid),
        .s_axis_b_tdata(loadWeight[`DATA_WIDTH*11 - 1 :`DATA_WIDTH*10]),

        .m_axis_result_tvalid(mul_re_valid),
        .m_axis_result_tdata(mult[10])
        );

    // addition
    floating_point_add add_0(
        .s_axis_a_tvalid(add_a_valid),
        .s_axis_a_tdata(addDataA1[0]),

        .s_axis_b_tvalid(add_b_valid),
        .s_axis_b_tdata(addDataB1[0]),

        .m_axis_result_tvalid(add_re_valid),
        .m_axis_result_tdata(addResult1[0])
        );

    floating_point_add add_1(
        .s_axis_a_tvalid(add_a_valid),
        .s_axis_a_tdata(addDataA1[1]),

        .s_axis_b_tvalid(add_b_valid),
        .s_axis_b_tdata(addDataB1[1]),

        .m_axis_result_tvalid(add_re_valid),
        .m_axis_result_tdata(addResult1[1])
        );

    floating_point_add add_2(
        .s_axis_a_tvalid(add_a_valid),
        .s_axis_a_tdata(addDataA1[2]),

        .s_axis_b_tvalid(add_b_valid),
        .s_axis_b_tdata(addDataB1[2]),

        .m_axis_result_tvalid(add_re_valid),
        .m_axis_result_tdata(addResult1[2])
        );

    floating_point_add add_3(
        .s_axis_a_tvalid(add_a_valid),
        .s_axis_a_tdata(addDataA1[3]),

        .s_axis_b_tvalid(add_b_valid),
        .s_axis_b_tdata(addDataB1[3]),

        .m_axis_result_tvalid(add_re_valid),
        .m_axis_result_tdata(addResult1[3])
        );

    floating_point_add add_4(
        .s_axis_a_tvalid(add_a_valid),
        .s_axis_a_tdata(addDataA1[4]),

        .s_axis_b_tvalid(add_b_valid),
        .s_axis_b_tdata(addDataB1[4]),

        .m_axis_result_tvalid(add_re_valid),
        .m_axis_result_tdata(addResult1[4])
        );

    floating_point_add add_5(
        .s_axis_a_tvalid(add_a_valid),
        .s_axis_a_tdata(addDataA2[0]),

        .s_axis_b_tvalid(add_b_valid),
        .s_axis_b_tdata(addDataB2[0]),

        .m_axis_result_tvalid(add_re_valid),
        .m_axis_result_tdata(addResult2[0])
        );

    floating_point_add add_6(
        .s_axis_a_tvalid(add_a_valid),
        .s_axis_a_tdata(addDataA2[1]),

        .s_axis_b_tvalid(add_b_valid),
        .s_axis_b_tdata(addDataB2[1]),

        .m_axis_result_tvalid(add_re_valid),
        .m_axis_result_tdata(addResult2[1])
        );

    floating_point_add add_7(
        .s_axis_a_tvalid(add_a_valid),
        .s_axis_a_tdata(addDataA2[2]),

        .s_axis_b_tvalid(add_b_valid),
        .s_axis_b_tdata(addDataB2[2]),

        .m_axis_result_tvalid(add_re_valid),
        .m_axis_result_tdata(addResult2[2])
        );

    floating_point_add add_8(
        .s_axis_a_tvalid(add_a_valid),
        .s_axis_a_tdata(addDataA3),

        .s_axis_b_tvalid(add_b_valid),
        .s_axis_b_tdata(addDataB3),

        .m_axis_result_tvalid(add_re_valid),
        .m_axis_result_tdata(addResult3)
        );

    floating_point_add add_9(
        .s_axis_a_tvalid(add_a_valid),
        .s_axis_a_tdata(addDataA4),

        .s_axis_b_tvalid(add_b_valid),
        .s_axis_b_tdata(addDataB4),

        .m_axis_result_tvalid(add_re_valid),
        .m_axis_result_tdata(addResult4)
        );


	always @(posedge clk or posedge rst) begin
        if(!rst) begin
            //reset registers
            loadData = 0;
            loadWeight = 0;
            //mulResult = 0;

            mul_a_valid = 0;
            mul_b_valid = 0;

            out = 0;
        end
    end

    always @(posedge clk) begin
    	if(ena && rst) begin
            // clk1
            // load data matrix and filter data
            loadData   <= data;
            loadWeight <= weight;
            mul_a_valid <= 1;
            mul_b_valid <= 1;
            add_a_valid <= 1;
            add_b_valid <= 1;

           	// clk2
            //  multiplication
            mulResult[0]  <= mult[0];
            mulResult[1]  <= mult[1];
            mulResult[2]  <= mult[2];
            mulResult[3]  <= mult[3];
            mulResult[4]  <= mult[4];
            mulResult[5]  <= mult[5];
            mulResult[6]  <= mult[6];
            mulResult[7]  <= mult[7];
            mulResult[8]  <= mult[8];
            mulResult[9]  <= mult[9];
            mulResult[10] <= mult[10];

            // clk3
            // addition 0+1, 2+3, 4+5, 6+7, 8+9, 10
            addDataA1[0]  <= mulResult[0];
            addDataB1[0]  <= mulResult[1];
            addDataA1[1]  <= mulResult[2];
            addDataB1[1]  <= mulResult[3];
            addDataA1[2]  <= mulResult[4];
            addDataB1[2]  <= mulResult[5];
            addDataA1[3]  <= mulResult[6];
            addDataB1[3]  <= mulResult[7];
            addDataA1[4]  <= mulResult[8];
            addDataB1[4]  <= mulResult[9];
            temp1         <= mulResult[10];
            
            // clk4
            addResultTemp1[0] <= addResult1[0];
            addResultTemp1[1] <= addResult1[1];
            addResultTemp1[2] <= addResult1[2];
            addResultTemp1[3] <= addResult1[3];
            addResultTemp1[4] <= addResult1[4];
            addResultTemp1[5] <= temp1;

            // clk5
            // addition (0+1)+(2+3), (4+5)+(6+7), (8+9)+(10)
            addDataA2[0]  <= addResultTemp1[0];
            addDataB2[0]  <= addResultTemp1[1];
            addDataA2[1]  <= addResultTemp1[2];
            addDataB2[1]  <= addResultTemp1[3];
            addDataA2[2]  <= addResultTemp1[4];
            addDataB2[2]  <= addResultTemp1[5];

            // clk6
            addResultTemp2[0] <= addResult2[0];
            addResultTemp2[1] <= addResult2[1];
            addResultTemp2[2] <= addResult2[2];

            // clk7
            // addition ((0+1)+(2+3))+((4+5)+(6+7)), (8+9)+(10)
            addDataA3  <= addResultTemp2[0];
            addDataB3  <= addResultTemp2[1];
            temp2      <= addResultTemp2[2];

            // clk8
            addResultTemp3[0] <= addResult3;
            addResultTemp3[1] <= temp2; 

            // clk9
            // addition (((0+1)+(2+3))+((4+5)+(6+7)))+((8+9)+(10)) 
            addDataA4  <= addResultTemp3[0];
            addDataB4  <= addResultTemp3[1];

            // clk10
            out <= addResult4;
            
        end
    end
endmodule
