`timescale 1ns/1ns
`include "../network_params.vh"

module sub_sample_tb;
    reg clock;
    reg reset;
    reg [`NH_VECTOR_BITWIDTH:0] sub_in;
    wire [`POOL_OUT_BITWIDTH:0] sub_out;
    
    sub_sample dut(
      .clk(clock),
      .reset(reset),
      .nh_vector(sub_in),
      .pool_out(sub_out)
    );
    
    initial 
    begin
      clock = 1'b1;
      repeat (20) clock = #5 ~clock;
    end
    
    initial
    begin
      #0
      reset = 1'b0;
    
      #10
      reset = 1'b1;
      sub_in = {8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8};
    // 0 1 2
    // 3 4 5
    // 6 7 8
    end
endmodule