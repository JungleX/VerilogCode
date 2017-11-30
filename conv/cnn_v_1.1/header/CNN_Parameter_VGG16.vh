// data
`define DATA_WIDTH			16	// 16 bits float

// kernel
`define PARA_KERNEL			2	// para kernel number
`define KERNEL_SIZE_MAX		3	// kernel size, max value: 3
`define KERNEL_SIZE_WIDTH	2	// kernel size width, max value: 3
`define KERNEL_NUM_WIDTH	13	// kernel num width, max value: 4096

// conv
`define PARA_X				3	// Para X
`define PARA_Y				3	// Para Y

// pool
`define	POOL_SIZE			2	// only one pool size in VGG
`define POOL_SIZE_WIDTH		2	// pool size width, pool size max value: 2
`define COM_RET_WIDTH	    8 	// compare unit result width, input: 16 bits float, output: 8 bits float

// feature map ram
`define FM_RAM_MAX			2140844 // FM_RAM_HALF * 2, 1070422 * 2 =
`define FM_RAM_HALF			1070422	// the first layer, 224*224*64	= 3211264, 3211264 / PARA_X, PARA_X, 3211264 / 3 = 1070422
`define READ_ADDR_WIDTH		22	// fm ram read address width, max value: 2140844
`define WRITE_ADDR_WIDTH	22	// fm ram write address width, max value: 2140844
`define RAM_NUM_WIDTH		4	// fm ram num width, max value: PARA_X, 3

// weight ram
`define WEIGHT_RAM_MAX			24576 // WEIGHT_RAM_HALF * 2, 12288 * 2 = 24576
`define WEIGHT_RAM_HALF			12288 // 4096 * PARA_Y, 4096 * 3 = 12288
`define WEIGHT_READ_ADDR_WIDTH	15	// weight ram read address, max value: 24576
`define WEIGHT_WRITE_ADDR_WIDTH	15	// weight ram write address, max value: 24576

// feature map
`define FM_SIZE_MAX			224 // fm size, max value: 224
`define FM_SIZE_WIDTH		8	// fm size width, fm size max value: 224
`define DEPTH_MAX			512	// fm depth, max value: 512
`define PADDING_NUM_WIDTH	2	// padding num width, max value: 1

// clock count
`define CLK_NUM_WIDTH		13	// clock number width, max value: 4096

// layer count
`define LAYER_NUM_WIDTH		5	// layer number width, max value: 16