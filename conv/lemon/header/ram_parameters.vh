// conv1
`define CONV1_FM_START_INDEX 0

// pool1
`define POOL1_FM_START_INDEX 154587 // conv1: 227*227*3=154587

// conv2
`define CONV2_FM_START_INDEX 0

// pool2
`define POOL2_FM_START_INDEX 69984  // conv2: 27*27*96=69984

// conv3
`define CONV3_FM_START_INDEX 0

// conv4
`define CONV4_FM_START_INDEX 43264  // conv3: 13*13*256=43264

// conv5
`define CONV5_FM_START_INDEX 0

// layer data index
`define LAYER_RAM_START_INDEX_0 0
`define LAYER_RAM_START_INDEX_1 154587 // 227*227*3=154587

// weight index
`define WEIGHT_RAM_START_INDEX_0 0
`define WEIGHT_RAM_START_INDEX_1 384  // 384

// weight width
`define WEIGHT_RAM_WIDTH 1936         // 11*11*16=1936