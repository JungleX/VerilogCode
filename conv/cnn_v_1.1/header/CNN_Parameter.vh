// data
`define DATA_WIDTH			16  // 16 bits float

// kernel
`define PARA_KERNEL			2 // para kernel number
`define KERNEL_NUM_WIDTH	10
`define KERNEL_SIZE_MAX		5

// conv
`define PARA_X				3	// MAC group number
`define PARA_Y				3	// MAC number of each MAC group
`define KERNEL_SIZE_WIDTH	6
`define FM_SIZE_WIDTH		10

// pool
`define PARA_POOL_Y			3	
`define POOL_SIZE_WIDTH		6
`define COM_RET_WIDTH	    8

// feature map ram
`define FM_RAM_MAX			400 
`define READ_ADDR_WIDTH		10 
`define WRITE_ADDR_WIDTH	10
`define RAM_NUM_WIDTH		4

// weight ram
`define WEIGHT_RAM_MAX			400
`define WEIGHT_READ_ADDR_WIDTH	10  
`define WEIGHT_WRITE_ADDR_WIDTH	5

// feature map
`define DEPTH_MAX		4
// clock count
`define CLK_NUM_WIDTH	8
