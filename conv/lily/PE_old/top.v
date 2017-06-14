`timescale 10ns/1ns
`include "bit_width.vh"

module top(
    input clk,
    input enable,
    input [`PCIE_DATA_WIDTH-1:0] pcie_data,
    output ready,
    output finish
);

reg ena0;
reg wea0;
reg[15:0] dina0;
reg enb0;
reg[15:0] addrb0;
wire[15:0] doutb0;
wire load_complete;

RamBlock bigram0(.clka(clk),
            .ena(ena0),      // input wire ena
            .wea(wea0),      // input wire [0 : 0] wea
            .dina(dina0),    // input wire [15 : 0] dina
            .clkb(clk),    // input wire clkb
            .enb(enb0),      // input wire enb
            .addrb(addrb0),  // input wire [15 : 0] addrb
            .doutb(doutb0),
            .ready(ready),
            .complete(load_complete));
            
reg[3:0] layer;
reg[15:0] weight;
reg[127:0] infm;                 //16*8
wire[127:0] outfm;
wire[135:0] infm_addr;
            
conv convcal(.layer(layer),
              .pcie_data(weight),
               .infm(infm),
               .outfm(outfm),
               .addr(infm_addr));

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
FINISHI = 4'b1100,
IDLE = 4'b1101;

//状态参数
reg[3:0] current_state;
reg[3:0] next_state;

//状态赋初值
always @(posedge clk or posedge enable) 
begin
    if(!enable) begin
        current_state <= IDLE;
    end
    else
        current_state <= next_state;
end

//根据敏感变量执行状态转换
always @(current_state) begin
    case(current_state)
        START: 
            begin
                ena0=1;
                wea0=1;
            end
        CONV1:
            begin
            end
    endcase
end

always @(posedge clk) 
begin
    case(current_state)
        IDLE:
            if(enable == 1)
                next_state = START;
            else
                next_state = IDLE;
        START:
            begin
                if(load_complete == 1)
                    next_state = CONV1; 
            end
        CONV1:
            begin
            end
    endcase
end

always @(posedge clk) 
begin
    case(current_state)
        START: begin
            if(ready == 1)
                dina0 = pcie_data;
            end
        CONV1:
            begin
            end
    endcase
end

endmodule
