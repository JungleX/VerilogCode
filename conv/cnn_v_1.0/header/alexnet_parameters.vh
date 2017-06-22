// data
`define DATA_WIDTH                  16       // 16 bits float
`define COMPARE_RESULT_WIDTH        7
`define CONV_MAX                    11

// ram
// feature map data index
`define LAYER_RAM_START_INDEX_0     0
`define LAYER_RAM_START_INDEX_1     154587 // 227*227*3=154587

// weight data index
`define WEIGHT_RAM_START_INDEX_0    0    
`define WEIGHT_RAM_START_INDEX_1    3456   // 3*3*384=3456

// cnn
`define CONV_MAX_LINE_SIZE          176   // 11*16=176
`define POOL_MAX_MATRIX_SIZE        144   // 3*3*16=144

// conv1 test
`define CONV1_FM_SIZE               12   
`define CONV1_FM_PADDING_UP         1
`define CONV1_FM_PADDING_DOWN       2 // 1+2=3
`define CONV1_FM_PADDING_LEFT       2
`define CONV1_FM_PADDING_RIGHT      1 // 1+2=3
`define CONV1_STRIDE                1
`define CONV1_KERNEL_NUMBER         4
`define CONV1_DEPTH_NUMBER          2
`define CONV1_WEIGHT_MATRIX_SIZE    11
`define CONV1_WEIGHT_MATRIX_NUMBER  121 // 11*11=121

// pool1 test
`define POOL1_FM_SIZE               5
`define POOL1_FM_PADDING_UP         0
`define POOL1_FM_PADDING_DOWN       0
`define POOL1_FM_PADDING_LEFT       0
`define POOL1_FM_PADDING_RIGHT      0
`define POOL1_STRIDE                1
`define POOL1_DEPTH_NUMBER          4
`define POOL1_POOL_MATRIX_SIZE      3
`define POOL1_POOL_MATRIX_NUMBER    9 // 3*3=9

// conv1
//`define CONV1_FM_SIZE               224
//`define CONV1_FM_PADDING_UP         1
//`define CONV1_FM_PADDING_DOWN       2 // 1+2=3
//`define CONV1_FM_PADDING_LEFT       1
//`define CONV1_FM_PADDING_RIGHT      2 // 1+2=3
//`define CONV1_STRIDE                4
//`define CONV1_KERNEL_NUMBER         96
//`define CONV1_DEPTH_NUMBER          3
//`define CONV1_WEIGHT_MATRIX_SIZE    11
//`define CONV1_WEIGHT_MATRIX_NUMBER  121 // 11*11=121

// conv2
`define CONV2_FM_SIZE               27
`define CONV2_FM_PADDING_UP         2
`define CONV2_FM_PADDING_DOWN       2 // 2+2=4
`define CONV2_FM_PADDING_LEFT       2
`define CONV2_FM_PADDING_RIGHT      2 // 2+2=4
`define CONV2_STRIDE                1
`define CONV2_KERNEL_NUMBER         256
`define CONV2_DEPTH_NUMBER          96
`define CONV2_WEIGHT_MATRIX_SIZE    5
`define CONV2_WEIGHT_MATRIX_NUMBER  25 // 5*5=25

// conv3
`define CONV3_FM_SIZE               13
`define CONV3_FM_PADDING_UP         1
`define CONV3_FM_PADDING_DOWN       1 // 1+1=2
`define CONV3_FM_PADDING_LEFT       1
`define CONV3_FM_PADDING_RIGHT      1 // 1+1=2
`define CONV3_STRIDE                1
`define CONV3_KERNEL_NUMBER         384
`define CONV3_DEPTH_NUMBER          256
`define CONV3_WEIGHT_MATRIX_SIZE    3
`define CONV3_WEIGHT_MATRIX_NUMBER  9 // 3*3=9

// conv4
`define CONV4_FM_SIZE               13
`define CONV4_FM_PADDING_UP         1
`define CONV4_FM_PADDING_DOWN       1 // 1+1=2
`define CONV4_FM_PADDING_LEFT       1
`define CONV4_FM_PADDING_RIGHT      1 // 1+1=2
`define CONV4_STRIDE                1
`define CONV4_KERNEL_NUMBER         384
`define CONV4_DEPTH_NUMBER          384
`define CONV4_WEIGHT_MATRIX_SIZE    3
`define CONV4_WEIGHT_MATRIX_NUMBER  9 // 3*3=9

// conv5
`define CONV5_FM_SIZE               13
`define CONV5_FM_PADDING_UP         1
`define CONV5_FM_PADDING_DOWN       1 // 1+1=2
`define CONV5_FM_PADDING_LEFT       1
`define CONV5_FM_PADDING_RIGHT      1 // 1+1=2
`define CONV5_STRIDE                1
`define CONV5_KERNEL_NUMBER         256
`define CONV5_DEPTH_NUMBER          384
`define CONV5_WEIGHT_MATRIX_SIZE    3
`define CONV5_WEIGHT_MATRIX_NUMBER  9 // 3*3=9

// pool1
//`define POOL1_FM_SIZE               55
//`define POOL1_FM_PADDING_UP         0
//`define POOL1_FM_PADDING_DOWN       0
//`define POOL1_FM_PADDING_LEFT       0
//`define POOL1_FM_PADDING_RIGHT      0
////`define POOL1_STRIDE                2
//`define POOL1_DEPTH_NUMBER          96
//`define POOL1_POOL_MATRIX_SIZE      3
//`define POOL1_POOL_MATRIX_NUMBER    9 // 3*3=9

// pool2
`define POOL2_FM_SIZE               27
`define POOL2_FM_PADDING_UP         0
`define POOL2_FM_PADDING_DOWN       0
`define POOL2_FM_PADDING_LEFT       0
`define POOL2_FM_PADDING_RIGHT      0
`define POOL2_STRIDE                2
`define POOL2_DEPTH_NUMBER          256
`define POOL2_POOL_MATRIX_SIZE      3
`define POOL2_POOL_MATRIX_NUMBER    9 // 3*3=9

// pool5
`define POOL5_FM_SIZE               13
`define POOL5_FM_PADDING_UP         0
`define POOL5_FM_PADDING_DOWN       0
`define POOL5_FM_PADDING_LEFT       0
`define POOL5_FM_PADDING_RIGHT      0
`define POOL5_STRIDE                2
`define POOL5_DEPTH_NUMBER          256
`define POOL5_POOL_MATRIX_SIZE      3
`define POOL5_POOL_MATRIX_NUMBER    9 // 3*3=9

// fc6
`define FC6_FM_MATRIX_SIZE          9216 // 6*6*256=9216
`define FC6_KERNEL_NUMBER           4096

// fc7
`define FC7_FM_MATRIX_SIZE          4096 // 1*4096=4096
`define FC7_KERNEL_NUMBER           4096

// fc8
`define FC8_FM_MATRIX_SIZE          4096 // 1*4096=4096
`define FC8_KERNEL_NUMBER           17   // 17 oxford flowers
