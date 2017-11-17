// data
`define DATA_WIDTH			16  // 16 bits float

// kernel
`define PARA_KERNEL			2 	// para kernel number
`define KERNEL_NUM_WIDTH	10
`define KERNEL_SIZE_MAX		5

// conv
`define PARA_X				3	// MAC group number
`define PARA_Y				3	// MAC number of each MAC group
`define KERNEL_SIZE_WIDTH	6
`define FM_SIZE_WIDTH		10

// pool
`define	POOL_SIZE			2	
`define POOL_SIZE_WIDTH		2
`define COM_RET_WIDTH	    8 	// compare unit result width

// feature map ram
`define FM_RAM_MAX			480 // 10*[10/3]*6*2=480 // FM_SIZE_MAX * (FM_SIZE_MAX / PARA_X)  * DEPTH_MAX * 2
`define FM_RAM_HALF			240	// FM_SIZE_MAX * (FM_SIZE_MAX / PARA_X) * DEPTH_MAX
`define READ_ADDR_WIDTH		10  
`define WRITE_ADDR_WIDTH	10
`define RAM_NUM_WIDTH		4

// weight ram
`define WEIGHT_RAM_MAX			300 // KERNEL_SIZE_MAX * KERNEL_SIZE_MAX * DEPTH_MAX * 2
`define WEIGHT_READ_ADDR_WIDTH	10  
`define WEIGHT_WRITE_ADDR_WIDTH	5

// feature map
`define FM_SIZE_MAX			10
`define DEPTH_MAX			6
`define PADDING_NUM_WIDTH	3

// clock count
`define CLK_NUM_WIDTH		8

// layer count
`define LAYER_NUM_WIDTH		6