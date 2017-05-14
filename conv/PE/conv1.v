`timescale 1ns/1ps

module conv1(input clka, input ena, input wea, input addra, input dina, input clkb, input enb, input addrb, output doutb);
wire clka;
wire ena;
wire wea;
wire [15:0] addra;
wire [15:0] dina; 
wire clkb;
wire enb;
wire [15 : 0] addrb;
wire [15:0] doutb;

blk_mem_16 inram0 (
  .clka(clka),    // input wire clka
  .ena(ena),      // input wire ena
  .wea(wea),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [15 : 0] addra
  .dina(dina),    // input wire [15 : 0] dina
  .clkb(clkb),    // input wire clkb
  .enb(enb),      // input wire enb
  .addrb(addrb),  // input wire [15 : 0] addrb
  .doutb(doutb)  // output wire [15 : 0] doutb
);
endmodule
