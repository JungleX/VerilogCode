`timescale 10ns/1ns
`include "bit_width.vh"

module top(
    input clk,
    input rst,
    input enable,
    input [`PCIE_DATA_WIDTH-1:0] pcie_data,
    output finish
);

reg ena0;
reg wea0;
reg[15:0] addra0 = 16'b0;
reg[15:0] dina0;
reg enb0;
reg[15:0] addrb0;
wire[15:0] doutb0;

RamBlock bigram0(.clka(clk),
            .ena(ena0),      // input wire ena
            .wea(wea0),      // input wire [0 : 0] wea
            .addra(addra0),  // input wire [15 : 0] addra
            .dina(dina0),    // input wire [15 : 0] dina
            .clkb(clk),    // input wire clkb
            .enb(enb0),      // input wire enb
            .addrb(addrb0),  // input wire [15 : 0] addrb
            .doutb(doutb0));

//状态机参数
parameter START = 4'b0000,
CONV1 = 4'b0001,
POOL1 = 4'b0010,
CONV2 = 4'b0011,
POOL2 = 4'b0100,
CONV3 = 4'b0101,
CONV4 = 4'b0110,
CONV5 = 4'b0111,
POOL5 = 4'b1000,
FC6 = 4'b1001,
FC7 = 4'b1010,
FC8= 4'b1011,
FINISHI = 4'b1100;

//状态参数
reg[3:0] current_state;
reg[3:0] next_state;

//状态赋初值
always @(posedge enable)
    current_state = START;

//状态跳转环
always @(posedge clk or negedge rst)
begin 
    //current_state <= next_state;
end

//状态机内部逻辑
always @(current_state or next_state) begin
    case(current_state)
        START: 
            begin
                ena0<=1;
                wea0<=1;
            end
    endcase
end

//状态机外部逻辑
always @(posedge clk) begin
    case(current_state)
        START:
        begin
            addra0 = addra0 + 1;
            dina0 = pcie_data;
        end
    endcase
end

endmodule
