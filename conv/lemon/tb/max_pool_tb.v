`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/02 19:54:33
// Design Name: 
// Module Name: max_pool_tb
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
`include "cnn_parameters.vh"
`define clk_period 10

module max_pool_tb();
    reg clock;
    reg reset;
    reg ena_mp;
    reg [`NH_VECTOR_WIDTH - 1:0] sub_in; 
    wire [`POOL_OUT_WIDTH - 1:0] sub_out;

    integer size = 55;
    integer cur = 0;
    integer i, j, k;
    integer loading_size = 0;
    integer reading_size = 0;
    reg [2:0] get_pool_num; 
    
    //reg i, j, k;
    
    max_pool dut(
        .clk(clock),
        .ena(ena_mp),
        .reset(reset),
        .in_vector(sub_in),
        .pool_out(sub_out)
    );
    
    reg [14:0] pcie_data[0:3025]; // get data from file, 2834095 = 55*55
    reg [31:0] write_data; // write data, two 16 bits floating-point numbers
    wire [15:0] read_data; // read data, a 16 bits floating-point number
    
    reg [17:0] addra;
    reg [18:0] addrb;
    reg ena;
    reg enb;
    reg wea;
    
    layer_ram lr(
        .addra(addra),
        .clka(clock),
        .dina(write_data),
        .ena(ena),
        .wea(wea),
        
        .addrb(addrb),
        .clkb(clock),
        .doutb(read_data),
        .enb(enb)
    );

    initial 
        clock = 1'b0;
    always #(`clk_period/2)clock = ~clock;

    initial begin
        #0
        $readmemb("data.mem", pcie_data);
        reset = 1'b0;
        ena_mp = 1'b0;
    
//        #`clk_period
//        //#5
//        reset = 1'b1;
//        ena_mp = 1'b1;
//        sub_in = {`NN_WIDTH'b0000000000000000, `NN_WIDTH'b0100101001000000, `NN_WIDTH'b1100101001000000, 
//                  `NN_WIDTH'b0100100100010000, `NN_WIDTH'b0100100010100000, `NN_WIDTH'b1100100100010000, 
//                  `NN_WIDTH'b1100100010100000, `NN_WIDTH'b0000000000000000, `NN_WIDTH'b0011110000000000};
        // 0,      12.5, -12.5
        // 10.125, 9.25, -10.125
        // -9.25,  0,    1
        
//        #`clk_period
//        reset = 1'b1;
//        sub_in = {`NN_WIDTH'b0000000000000000, `NN_WIDTH'b0100101001000000, `NN_WIDTH'b1100101001000000, 
//                  `NN_WIDTH'b0100100100010000, `NN_WIDTH'b0100100010100000, `NN_WIDTH'b1100100100010000, 
//                  `NN_WIDTH'b1100100010100000, `NN_WIDTH'b0100110011100000, `NN_WIDTH'b0011110000000000};
         // 0,      12.5, -12.5
         // 10.125, 9.25, -10.125
         // -9.25,  19.5,    1             
        
        // max pool for 55*55 feature map
        #`clk_period
        reset = 1;
        ena = 1;
        wea = 1; // port a for write
        enb = 0;
        loading_size = 0; 
        addra = 0;
        
        // write data
        while(loading_size <= 3025) begin // 3025 = 55*55 
            ena = 1;
            if(loading_size == 3024)
                write_data = {16'b0, 1'b0, pcie_data[loading_size]};
            else
                write_data = {1'b0, pcie_data[loading_size+1], 1'b0, pcie_data[loading_size]};
            #`clk_period
            addra = addra + 1;
            loading_size = loading_size + 2;
        end
         
         // disable write ena; enable read ena
         #`clk_period 
         ena = 0;
         wea = 0;
         reading_size = 0;
         enb = 1;
         addrb = 0;

         // read data
//         while(reading_size <= 3025) begin // 3025 = 55*55
//            #`clk_period
//            addrb = addrb + 1;
//            reading_size = reading_size + 1;
//         end
         
        #`clk_period
        size = 55;
        cur = 0;
        ena_mp = 1;
        get_pool_num = 0; // not ready to get max number of 9 numbers
        for(i = 0; i < size - 4; i=i+3) begin
            for(j = 0; j < size - 4; j=j+3) begin
                // it takes 9 clocks to read 9 numbers
                k = 1;
                while(k <= 9) begin
                    addrb = i + size*(k/3) + k;
                    #`clk_period
                    // range must be bounded by constant expressions
                    case(k)
                        32'd1: begin
                                sub_in[`NN_WIDTH-1:0] = read_data;
                                if(get_pool_num > 0)
                                    get_pool_num = get_pool_num + 1;
                               end
                        32'd2: begin 
                                sub_in[`NN_WIDTH*2-1:`NN_WIDTH]   = read_data;
                                if(get_pool_num > 0)
                                    get_pool_num = get_pool_num + 1;
                               end
                        32'd3: begin
                                sub_in[`NN_WIDTH*3-1:`NN_WIDTH*2] = read_data;
                                if(get_pool_num > 0)
                                    get_pool_num = get_pool_num + 1;
                               end
                        32'd4: begin
                                sub_in[`NN_WIDTH*4-1:`NN_WIDTH*3] = read_data;
                                if(get_pool_num > 0)
                                    get_pool_num = get_pool_num + 1;
                               end
                        32'd5: begin
                                sub_in[`NN_WIDTH*5-1:`NN_WIDTH*4] = read_data;
                                if(get_pool_num > 0)
                                    get_pool_num = get_pool_num + 1;
                               end
                        32'd6: begin
                                sub_in[`NN_WIDTH*6-1:`NN_WIDTH*5] = read_data;
                               end
                        32'd7: begin
                                sub_in[`NN_WIDTH*7-1:`NN_WIDTH*6] = read_data;
                               end
                        32'd8: begin
                                sub_in[`NN_WIDTH*8-1:`NN_WIDTH*7] = read_data;
                               end
                        32'd9: begin
                                sub_in[`NN_WIDTH*9-1:`NN_WIDTH*8] = read_data;
                                get_pool_num = 1; // start to count, the time to get max result
                               end
                        default: sub_in = `NH_VECTOR_WIDTH'bx;
                    endcase
                    if(get_pool_num == 6) begin
                        $display("%h, %b", sub_out, sub_out);
                        get_pool_num = 0;
                    end
                    k = k + 1;
                end
            end
        end
    
        // wait for the last max pool result
        while(get_pool_num > 0 && get_pool_num < 6) begin
            #`clk_period
            get_pool_num = get_pool_num + 1;
        end
        $display("%h, %b", sub_out, sub_out);
        
    end

endmodule
