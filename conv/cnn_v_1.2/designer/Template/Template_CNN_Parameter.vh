// data
`define DATA_WIDTH				16	// 16 bits float

// kernel
`define PARA_KERNEL				SET_PARA_KERNEL	// para kernel number
`define KERNEL_SIZE_MAX			3	// kernel size, max value: 3
`define KERNEL_SIZE_WIDTH		13	// kernel size width, conv max value: 3, fc max value: 4096
`define KERNEL_NUM_WIDTH		13	// kernel num width, max value: 4096

// conv
`define PARA_X					SET_PARA_X	// Para X
`define PARA_Y					SET_PARA_Y	// Para Y

// pool
`define	POOL_SIZE				2	// only one pool size in VGG
`define POOL_SIZE_WIDTH			2	// pool size width, pool size max value: 2	
`define COM_RET_WIDTH			8	// compare unit result width, input: 16 bits float, output: 8 bits float

// feature map ram
// not use, delete later
`define READ_ADDR_WIDTH			22	// fm ram read address width, max value: 2140844
`define WRITE_ADDR_WIDTH		22	// fm ram write address width, max value: 2140844

`define RAM_NUM_WIDTH			10	// fm ram num width, max value: 890

// weight ram
// not use, delete later
`define WEIGHT_READ_ADDR_WIDTH	15	// weight ram read address, max value: 24576
`define WEIGHT_WRITE_ADDR_WIDTH	15	// weight ram write address, max value: 24576

// feature map
`define FM_SIZE_MAX				224
`define FM_SIZE_WIDTH			8	// fm size width, fm size max value: 224
`define PADDING_NUM_WIDTH		2	// padding num width, max value: 1

// feature map ram, block ram
`define FM_ADDRA_WIDTH			SET_FM_ADDRA_WIDTH
`define FM_ADDRB_WIDTH			SET_FM_ADDRB_WIDTH
`define FM_RAM_MAX				SET_FM_RAM_MAX
`define FM_RAM_HALF				SET_FM_RAM_HALF

// weight ram, block ram
`define WEIGHT_ADDRA_WIDTH		SET_WEIGHT_ADDRA_WIDTH
`define WEIGHT_ADDRB_WIDTH		SET_WEIGHT_ADDRB_WIDTH
`define WEIGHT_RAM_MAX			SET_WEIGHT_RAM_MAX
`define WEIGHT_RAM_HALF			SET_WEIGHT_RAM_HALF

// clock count
`define CLK_NUM_WIDTH			13	// clock number width, max value: 4096

// layer count
`define LAYER_NUM_WIDTH			5	// layer number width, max value: 16