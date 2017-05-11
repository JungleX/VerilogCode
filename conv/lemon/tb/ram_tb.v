`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/05/10 21:36:23
// Design Name: 
// Module Name: ram_tb
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
`include "bit_width.vh"
`define clk_period 10

module ram_tb();
    reg clk;
    
    reg [14:0] pcie_data[0:2834094]; // get data from file, 2834095 = 227*227*55
    reg [31:0] write_data; // write data, two 16 bits floating-point numbers
    wire [15:0] read_data; // read data, a 16 bits floating-point number
    
    reg [17:0] addra;
    reg [18:0] addrb;
    reg ena;
    reg enb;
    reg wea;
    
    layer_ram lr(
        .addra(addra),
        .clka(clk),
        .dina(write_data),
        .ena(ena),
        .wea(wea),
        
        .addrb(addrb),
        .clkb(clk),
        .doutb(read_data),
        .enb(enb)
    );
    
    initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;
    
    integer loading_size = 0;
    integer reading_size = 0;
    initial begin
        $readmemb("data.mem", pcie_data);
    
        wea = 1; // port a for write
        enb = 0;
        loading_size = 0; 
        addra = 0;
        
        // write data simple test
//        #`clk_period 
//        write_data = {1'b0, pcie_data[1], 1'b0, pcie_data[0]};
//        addra = 0;
 
//        #`clk_period 
//        write_data = {1'b0, pcie_data[3], 1'b0, pcie_data[2]};
//        addra = 1;       
                  
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
         while(reading_size <= 3025) begin // 3025 = 55*55
            #`clk_period
            addrb = addrb + 1;
            reading_size = reading_size + 1;
         end
         
         enb = 0;
         
         // stop the simulation
         #`clk_period
         $finish;
    end
endmodule