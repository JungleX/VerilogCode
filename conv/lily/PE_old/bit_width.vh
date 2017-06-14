`ifndef _bit_width_vh
`define _bit_width_vh

`define BASE_WIDTH 16

// 3*3, W
`define WEIGHT_SIZE_1 3
// 7*7, F
`define DATA_SIZE_1    7
// S
`define STRIDE_1 2     
`define PAD 0
// 3*3 (W-F+2P)/S+1 
`define DATA_SIZE_2 3

`define IMG_DATA_WIDTH         16
// `IMG_DATA_WIDTH * 2
`define IMG_DATA_WIDTH_DOUBLE  32
// `IMG_DATA_WIDTH * 3 // just for filter3*3
`define IMG_DATA_LINE_WIDTH    48
// `IMG_DATA_WIDTH * 9 // just for filter3*3
`define IMG_DATA_MATRIX_WIDTH  144

`define ADDRESS_WIDTH 16

`define NUM_1 `IMG_DATA_WIDTH'b1
`define NUM_2 `IMG_DATA_WIDTH'b10

`define CONV_TN 3
`define MULT_ADDER_IN_WIDTH `IMG_DATA_WIDTH*`CONV_TN
`define CONV_ADD_WIDTH 16
`define CONV_PRODUCT_WIDTH 16
`define CONV_MULT_WIDTH `IMG_DATA_WIDTH

`define PCIE_DATA_WIDTH 16

`endif
