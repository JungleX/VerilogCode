`ifndef _bit_width_vh
`define _bit_width_vh

`define BASE_WIDTH 8

`define WEIGHT_SIZE_1 3 // 3*3, W
`define DATA_SIZE_1    7 // 7*7, F
`define STRIDE_1 2       // S
`define PAD 0
`define DATA_SIZE_2 3 // 3*3 (W-F+2P)/S+1 

`define IMG_DATA_WIDTH 8
`define IMG_DATA_LINE_WIDTH `IMG_DATA_WIDTH * 3 // just for filter3*3
`define IMG_DATA_MATRIX_WIDTH `IMG_DATA_WIDTH * 9 // just for filter3*3

`define ADDRESS_WIDTH 8

`define NUM_1 8'b1 //32'b00111111100000000000000000000000
`define NUM_2 8'b10 //32'b01000000000000000000000000000000

`endif
