// data
`define DATA_WIDTH           16       // 16 bits float
`define CONV_MAX             11     
`define CONV_MAX_LINE_SIZE   176      // 11*16=176
`define KERNEL_MAX_DEPTH     384
`define POOL_SIZE            144      // 16*9=144
`define COMPARE_RESULT_WIDTH 7

// conv1 test
`define CONV1_FM             12      
`define CONV1_FM_DEPTH       2              
`define CONV1_FM_DATA_SIZE   288      // 12*12*2     
`define CONV1_KERNERL        11    
`define CONV1_KERNERL_MATRIX 121      // 11*11=121
`define CONV1_KERNEL_SIZE    242      // 11*11*2*1 
`define CONV1_KERNERL_NUMBER 4       
`define CONV1_STRIDE         1

// conv1
//`define CONV1_FM             227
//`define CONV1_FM_DEPTH       3
//`define CONV1_FM_DATA_SIZE   154587 //227*227*3=154587
//`define CONV1_KERNERL        11    
//`define CONV1_KERNERL_MATRIX 121    // 11*11=121
//`define CONV1_KERNEL_SIZE    34848  // 11*11*3*96=34848
//`define CONV1_KERNERL_NUMBER 96
//`define CONV1_STRIDE         4

// pool1 test
`define POOL1_FM             5
`define POOL1_DEPTH          2
`define POOL1_FM_DATA        25       // 5*5
`define POOL1_WINDOW         3      
`define POOL1_WINDOW_SIZE    9        // 3*3
`define POOL1_STRIDE         2

// pool2
`define POOL2_FM             27
`define POOL2_DEPTH          256
`define POOL2_FM_DATA        729    //27*27
`define POOL2_WINDOW         3      
`define POOL2_WINDOW_SIZE    9      // 3*3
`define POOL2_STRIDE         2

// conv2
`define CONV2_FM             27
`define CONV2_FM_DEPTH       96
`define CONV2_FM_DATA_SIZE   69984    // 27*27*96=69984
`define CONV2_KERNERL        5
`define CONV2_KERNERL_MATRIX 25       // 5*5=25
`define CONV2_KERNEL_SIZE    614400   // 5*5*96*256=614400
`define CONV2_KERNERL_NUMBER 256
`define CONV2_STRIDE         1

// pool1
//`define POOL1_FM             55
//`define POOL1_DEPTH          96
//`define POOL1_FM_DATA        3025   //55*55
//`define POOL1_WINDOW         3      
//`define POOL1_WINDOW_SIZE    9      // 3*3
//`define POOL1_STRIDE         2

// conv3
`define CONV3_FM             13
`define CONV3_FM_DEPTH       256
`define CONV3_FM_DATA_SIZE   43264    // 13*13*256=43264
`define CONV3_KERNERL        3 
`define CONV3_KERNERL_MATRIX 9        // 3*3=9
`define CONV3_KERNEL_SIZE    884736   // 3*3*256*384=884736
`define CONV3_KERNERL_NUMBER 384
`define CONV3_STRIDE         1

// conv4
`define CONV4_FM             13
`define CONV4_FM_DEPTH       384
`define CONV4_FM_DATA_SIZE   64896   // 13*13*384=64896
`define CONV4_KERNERL        3
`define CONV4_KERNERL_MATRIX 9       // 3*3=9
`define CONV4_KERNEL_SIZE    1327104 // 3*3*384*384=1327104
`define CONV4_KERNERL_NUMBER 384
`define CONV4_STRIDE         1

// conv5
`define CONV5_FM             13
`define CONV5_FM_DEPTH       384
`define CONV5_FM_DATA_SIZE   64896   // 13*13*384=64896
`define CONV5_KERNERL        3
`define CONV5_KERNERL_MATRIX 9       // 3*3=9
`define CONV5_KERNEL_SIZE    884736  // 3*3*384*256=884736
`define CONV5_KERNERL_NUMBER 256
`define CONV5_STRIDE         1

// pool5
`define POOL5_FM             13
`define POOL5_DEPTH          256
`define POOL5_FM_DATA        169    //13*13
`define POOL5_WINDOW         3      
`define POOL5_WINDOW_SIZE    9      // 3*3
`define POOL5_STRIDE         2

// fc6
`define FC6_FM_SIZE          9216   // 6*6*256=9216  matrix*depth
`define FC6_KERNEL_NUMBER    4096

// fc7
`define FC7_FM_SIZE          4096   // 4096*1*1=4096
`define FC7_KERNEL_NUMBER    4096

//fc8
`define FC8_FM_SIZE          4096   // 4096*1*1=4096
`define FC8_KERNEL_NUMBER    17     // 17 oxford flowers