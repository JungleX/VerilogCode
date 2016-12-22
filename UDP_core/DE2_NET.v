// --------------------------------------------------------------------
// Copyright (c) 2005 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:	DE2 NIOS Reference Design
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V2.0 :| Johnny Chen       :| 06/07/19  :|      Initial Revision
// --------------------------------------------------------------------

module DE2_NET
	(
		////////////////////	Clock Input	 	////////////////////	 
		CLOCK_27,						//	On Board 27 MHz
		CLOCK_50,						//	On Board 50 MHz
		EXT_CLOCK,						//	External Clock
		////////////////////	Push Button		////////////////////
		KEY,							//	Pushbutton[3:0]
		////////////////////	DPDT Switch		////////////////////
		SW,								//	Toggle Switch[17:0]
		////////////////////	7-SEG Dispaly	////////////////////
		HEX0,							//	Seven Segment Digit 0
		HEX1,							//	Seven Segment Digit 1
		HEX2,							//	Seven Segment Digit 2
		HEX3,							//	Seven Segment Digit 3
		HEX4,							//	Seven Segment Digit 4
		HEX5,							//	Seven Segment Digit 5
		HEX6,							//	Seven Segment Digit 6
		HEX7,							//	Seven Segment Digit 7
		////////////////////////	LED		////////////////////////
		LEDG,							//	LED Green[8:0]
		LEDR,							//	LED Red[17:0]
		////////////////////////	UART	////////////////////////
		UART_TXD,						//	UART Transmitter
		UART_RXD,						//	UART Receiver
		////////////////////////	IRDA	////////////////////////
		IRDA_TXD,						//	IRDA Transmitter
		IRDA_RXD,						//	IRDA Receiver
		/////////////////////	SDRAM Interface		////////////////
		DRAM_DQ,						//	SDRAM Data bus 16 Bits
		DRAM_ADDR,						//	SDRAM Address bus 12 Bits
		DRAM_LDQM,						//	SDRAM Low-byte Data Mask 
		DRAM_UDQM,						//	SDRAM High-byte Data Mask
		DRAM_WE_N,						//	SDRAM Write Enable
		DRAM_CAS_N,						//	SDRAM Column Address Strobe
		DRAM_RAS_N,						//	SDRAM Row Address Strobe
		DRAM_CS_N,						//	SDRAM Chip Select
		DRAM_BA_0,						//	SDRAM Bank Address 0
		DRAM_BA_1,						//	SDRAM Bank Address 1
		DRAM_CLK,						//	SDRAM Clock
		DRAM_CKE,						//	SDRAM Clock Enable
		////////////////////	Flash Interface		////////////////
		FL_DQ,							//	FLASH Data bus 8 Bits
		FL_ADDR,						//	FLASH Address bus 20 Bits
		FL_WE_N,						//	FLASH Write Enable
		FL_RST_N,						//	FLASH Reset
		FL_OE_N,						//	FLASH Output Enable
		FL_CE_N,						//	FLASH Chip Enable
		////////////////////	SRAM Interface		////////////////
		SRAM_DQ,						//	SRAM Data bus 16 Bits
		SRAM_ADDR,						//	SRAM Address bus 18 Bits
		SRAM_UB_N,						//	SRAM High-byte Data Mask
		SRAM_LB_N,						//	SRAM Low-byte Data Mask  
		SRAM_WE_N,						//	SRAM Write Enable
		SRAM_CE_N,						//	SRAM Chip Enable
		SRAM_OE_N,						//	SRAM Output Enable
		////////////////////	ISP1362 Interface	////////////////
		OTG_DATA,						//	ISP1362 Data bus 16 Bits
		OTG_ADDR,						//	ISP1362 Address 2 Bits
		OTG_CS_N,						//	ISP1362 Chip Select
		OTG_RD_N,						//	ISP1362 Write
		OTG_WR_N,						//	ISP1362 Read
		OTG_RST_N,						//	ISP1362 Reset
		OTG_FSPEED,						//	USB Full Speed,	0 = Enable, Z = Disable
		OTG_LSPEED,						//	USB Low Speed, 	0 = Enable, Z = Disable
		OTG_INT0,						//	ISP1362 Interrupt 0
		OTG_INT1,						//	ISP1362 Interrupt 1
		OTG_DREQ0,						//	ISP1362 DMA Request 0
		OTG_DREQ1,						//	ISP1362 DMA Request 1
		OTG_DACK0_N,					//	ISP1362 DMA Acknowledge 0
		OTG_DACK1_N,					//	ISP1362 DMA Acknowledge 1
		////////////////////	LCD Module 16X2		////////////////
		LCD_ON,							//	LCD Power ON/OFF
		LCD_BLON,						//	LCD Back Light ON/OFF
		LCD_RW,							//	LCD Read/Write Select, 0 = Write, 1 = Read
		LCD_EN,							//	LCD Enable
		LCD_RS,							//	LCD Command/Data Select, 0 = Command, 1 = Data
		LCD_DATA,						//	LCD Data bus 8 bits
		////////////////////	SD_Card Interface	////////////////
		SD_DAT,							//	SD Card Data
		SD_DAT3,						//	SD Card Data 3
		SD_CMD,							//	SD Card Command Signal
		SD_CLK,							//	SD Card Clock
		////////////////////	USB JTAG link	////////////////////
		TDI,  							//	CPLD -> FPGA (Data in)
		TCK,  							//	CPLD -> FPGA (Clock)
		TCS,  							//	CPLD -> FPGA (CS)
	    TDO,  							//	FPGA -> CPLD (Data out)
		////////////////////	I2C		////////////////////////////
		I2C_SDAT,						//	I2C Data
		I2C_SCLK,						//	I2C Clock
		////////////////////	PS2		////////////////////////////
		PS2_DAT,						//	PS2 Data
		PS2_CLK,						//	PS2 Clock
		////////////////////	VGA		////////////////////////////
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK,						//	VGA BLANK
		VGA_SYNC,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,  						//	VGA Blue[9:0]
		////////////	Ethernet Interface	////////////////////////
		ENET_DATA,						//	DM9000A DATA bus 16Bits
		ENET_CMD,						//	DM9000A Command/Data Select, 0 = Command, 1 = Data
		ENET_CS_N,						//	DM9000A Chip Select
		ENET_WR_N,						//	DM9000A Write
		ENET_RD_N,						//	DM9000A Read
		ENET_RST_N,						//	DM9000A Reset
		ENET_INT,						//	DM9000A Interrupt
		ENET_CLK,						//	DM9000A Clock 25 MHz
		////////////////	Audio CODEC		////////////////////////
		AUD_ADCLRCK,					//	Audio CODEC ADC LR Clock
		AUD_ADCDAT,						//	Audio CODEC ADC Data
		AUD_DACLRCK,					//	Audio CODEC DAC LR Clock
		AUD_DACDAT,						//	Audio CODEC DAC Data
		AUD_BCLK,						//	Audio CODEC Bit-Stream Clock
		AUD_XCK,						//	Audio CODEC Chip Clock
		////////////////	TV Decoder		////////////////////////
		TD_DATA,    					//	TV Decoder Data bus 8 bits
		TD_HS,							//	TV Decoder H_SYNC
		TD_VS,							//	TV Decoder V_SYNC
		TD_RESET,						//	TV Decoder Reset
		////////////////////	GPIO	////////////////////////////
		GPIO_0,							//	GPIO Connection 0
		GPIO_1							//	GPIO Connection 1
	);

////////////////////////	Clock Input	 	////////////////////////
input			CLOCK_27;				//	On Board 27 MHz
input			CLOCK_50;				//	On Board 50 MHz
input			EXT_CLOCK;				//	External Clock
////////////////////////	Push Button		////////////////////////
input	[3:0]	KEY;					//	Pushbutton[3:0]
////////////////////////	DPDT Switch		////////////////////////
input	[17:0]	SW;						//	Toggle Switch[17:0]
////////////////////////	7-SEG Display	////////////////////////
output	[6:0]	HEX0;					//	Seven Segment Digit 0
output	[6:0]	HEX1;					//	Seven Segment Digit 1
output	[6:0]	HEX2;					//	Seven Segment Digit 2
output	[6:0]	HEX3;					//	Seven Segment Digit 3
output	[6:0]	HEX4;					//	Seven Segment Digit 4
output	[6:0]	HEX5;					//	Seven Segment Digit 5
output	[6:0]	HEX6;					//	Seven Segment Digit 6
output	[6:0]	HEX7;					//	Seven Segment Digit 7
////////////////////////////	LED		////////////////////////////
output	[8:0]	LEDG;					//	LED Green[8:0]
output	[17:0]	LEDR;					//	LED Red[17:0]
////////////////////////////	UART	////////////////////////////
output			UART_TXD;				//	UART Transmitter
input			UART_RXD;				//	UART Receiver
////////////////////////////	IRDA	////////////////////////////
output			IRDA_TXD;				//	IRDA Transmitter
input			IRDA_RXD;				//	IRDA Receiver
///////////////////////		SDRAM Interface	////////////////////////
inout	[15:0]	DRAM_DQ;				//	SDRAM Data bus 16 Bits
output	[11:0]	DRAM_ADDR;				//	SDRAM Address bus 12 Bits
output			DRAM_LDQM;				//	SDRAM Low-byte Data Mask 
output			DRAM_UDQM;				//	SDRAM High-byte Data Mask
output			DRAM_WE_N;				//	SDRAM Write Enable
output			DRAM_CAS_N;				//	SDRAM Column Address Strobe
output			DRAM_RAS_N;				//	SDRAM Row Address Strobe
output			DRAM_CS_N;				//	SDRAM Chip Select
output			DRAM_BA_0;				//	SDRAM Bank Address 0
output			DRAM_BA_1;				//	SDRAM Bank Address 0
output			DRAM_CLK;				//	SDRAM Clock
output			DRAM_CKE;				//	SDRAM Clock Enable
////////////////////////	Flash Interface	////////////////////////
inout	[7:0]	FL_DQ;					//	FLASH Data bus 8 Bits
output	[21:0]	FL_ADDR;				//	FLASH Address bus 22 Bits
output			FL_WE_N;				//	FLASH Write Enable
output			FL_RST_N;				//	FLASH Reset
output			FL_OE_N;				//	FLASH Output Enable
output			FL_CE_N;				//	FLASH Chip Enable
////////////////////////	SRAM Interface	////////////////////////
inout	[15:0]	SRAM_DQ;				//	SRAM Data bus 16 Bits
output	[17:0]	SRAM_ADDR;				//	SRAM Address bus 18 Bits
output			SRAM_UB_N;				//	SRAM Low-byte Data Mask 
output			SRAM_LB_N;				//	SRAM High-byte Data Mask 
output			SRAM_WE_N;				//	SRAM Write Enable
output			SRAM_CE_N;				//	SRAM Chip Enable
output			SRAM_OE_N;				//	SRAM Output Enable
////////////////////	ISP1362 Interface	////////////////////////
inout	[15:0]	OTG_DATA;				//	ISP1362 Data bus 16 Bits
output	[1:0]	OTG_ADDR;				//	ISP1362 Address 2 Bits
output			OTG_CS_N;				//	ISP1362 Chip Select
output			OTG_RD_N;				//	ISP1362 Write
output			OTG_WR_N;				//	ISP1362 Read
output			OTG_RST_N;				//	ISP1362 Reset
output			OTG_FSPEED;				//	USB Full Speed,	0 = Enable, Z = Disable
output			OTG_LSPEED;				//	USB Low Speed, 	0 = Enable, Z = Disable
input			OTG_INT0;				//	ISP1362 Interrupt 0
input			OTG_INT1;				//	ISP1362 Interrupt 1
input			OTG_DREQ0;				//	ISP1362 DMA Request 0
input			OTG_DREQ1;				//	ISP1362 DMA Request 1
output			OTG_DACK0_N;			//	ISP1362 DMA Acknowledge 0
output			OTG_DACK1_N;			//	ISP1362 DMA Acknowledge 1
////////////////////	LCD Module 16X2	////////////////////////////
inout	[7:0]	LCD_DATA;				//	LCD Data bus 8 bits
output			LCD_ON;					//	LCD Power ON/OFF
output			LCD_BLON;				//	LCD Back Light ON/OFF
output			LCD_RW;					//	LCD Read/Write Select, 0 = Write, 1 = Read
output			LCD_EN;					//	LCD Enable
output			LCD_RS;					//	LCD Command/Data Select, 0 = Command, 1 = Data
////////////////////	SD Card Interface	////////////////////////
inout			SD_DAT;					//	SD Card Data
inout			SD_DAT3;				//	SD Card Data 3
inout			SD_CMD;					//	SD Card Command Signal
output			SD_CLK;					//	SD Card Clock
////////////////////////	I2C		////////////////////////////////
inout			I2C_SDAT;				//	I2C Data
output			I2C_SCLK;				//	I2C Clock
////////////////////////	PS2		////////////////////////////////
input		 	PS2_DAT;				//	PS2 Data
input			PS2_CLK;				//	PS2 Clock
////////////////////	USB JTAG link	////////////////////////////
input  			TDI;					// CPLD -> FPGA (data in)
input  			TCK;					// CPLD -> FPGA (clk)
input  			TCS;					// CPLD -> FPGA (CS)
output 			TDO;					// FPGA -> CPLD (data out)
////////////////////////	VGA			////////////////////////////
output			VGA_CLK;   				//	VGA Clock
output			VGA_HS;					//	VGA H_SYNC
output			VGA_VS;					//	VGA V_SYNC
output			VGA_BLANK;				//	VGA BLANK
output			VGA_SYNC;				//	VGA SYNC
output	[9:0]	VGA_R;   				//	VGA Red[9:0]
output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
////////////////	Ethernet Interface	////////////////////////////
inout	[15:0]	ENET_DATA;				//	DM9000A DATA bus 16Bits
output			ENET_CMD;				//	DM9000A Command/Data Select, 0 = Command, 1 = Data
output			ENET_CS_N;				//	DM9000A Chip Select
output			ENET_WR_N;				//	DM9000A Write
output			ENET_RD_N;				//	DM9000A Read
output			ENET_RST_N;				//	DM9000A Reset
input			ENET_INT;				//	DM9000A Interrupt
output			ENET_CLK;				//	DM9000A Clock 25 MHz
////////////////////	Audio CODEC		////////////////////////////
inout			AUD_ADCLRCK;			//	Audio CODEC ADC LR Clock
input			AUD_ADCDAT;				//	Audio CODEC ADC Data
inout			AUD_DACLRCK;			//	Audio CODEC DAC LR Clock
output			AUD_DACDAT;				//	Audio CODEC DAC Data
inout			AUD_BCLK;				//	Audio CODEC Bit-Stream Clock
output			AUD_XCK;				//	Audio CODEC Chip Clock
////////////////////	TV Devoder		////////////////////////////
input	[7:0]	TD_DATA;    			//	TV Decoder Data bus 8 bits
input			TD_HS;					//	TV Decoder H_SYNC
input			TD_VS;					//	TV Decoder V_SYNC
output			TD_RESET;				//	TV Decoder Reset
////////////////////////	GPIO	////////////////////////////////
inout	[35:0]	GPIO_0;					//	GPIO Connection 0
inout	[35:0]	GPIO_1;					//	GPIO Connection 1

wire	CPU_CLK;
wire	CPU_RESET;
wire	CLK_18_4;
wire	CLK_25;

//	Flash
assign	FL_RST_N	=	1'b1;

//	16*2 LCD Module
assign	LCD_ON		=	1'b1;	//	LCD ON
assign	LCD_BLON	=	1'b1;	//	LCD Back Light	

//	All inout port turn to tri-state
assign	SD_DAT		=	1'bz;
assign	AUD_ADCLRCK	=	AUD_DACLRCK;
assign	GPIO_0		=	36'hzzzzzzzzz;
assign	GPIO_1		=	36'hzzzzzzzzz;

//	Disable USB speed select
assign	OTG_FSPEED	=	1'bz;
assign	OTG_LSPEED	=	1'bz;

//	Turn On TV Decoder
//assign	TD_RESET	=	1'b1;

//	Set SD Card to SD Mode
//assign	SD_DAT3		=	1'b1;


//toplevel to cpu connection wires
	//inputs from low-level software (MAC/PHY) to UDP stack
	wire [31:0] data_in_from_ethernet;
	wire [1:0]  data_in_from_ethernet_type;
	wire cpu_ip_done;
	wire [7:0] cpu_ip_index;
	wire cpu_arp_done;
	wire [2:0] cpu_arp_index;
	
	//inputs from application software to UDP stack
	wire data_out_from_app_valid;
	wire [31:0] data_out_from_app;
	wire [31:0] dest_ip_addr;
	wire [15:0] dest_port;
	wire [15:0] data_out_from_app_length;

	//outputs from UDP stack to low-level software (to MAC/PHY)
	wire ack;
	wire cpu_ip_ready;
	wire [47:0]	cpu_ip_mac;
	wire [31:0]	cpu_ip_data;
	wire [7:0]	cpu_ip_length;
	wire cpu_arp_ready;
	wire [47:0]	cpu_arp_mac;
	wire [31:0]	cpu_arp_data;

	//outputs from UDP stack to application sofware
	wire data_in_to_app_valid;
	wire [31:0] data_in_to_app;
	wire [15:0] input_port;

	//app variables
	reg [31:0] data_buffer;

	assign LEDR[0] = ack;
	assign LEDR[2:1] = data_in_from_ethernet_type;
	assign LEDR[3] = cpu_arp_ready;
	assign LEDR[4] = cpu_ip_ready;
	assign LEDR[5] = toplevel.v_arp;
	assign LEDR[6] = toplevel.send_en;
	assign LEDR[7] = toplevel.arp_valid;

Reset_Delay	delay1	(.iRST(KEY[0]),.iCLK(CLOCK_50),.oRESET(CPU_RESET));

SDRAM_PLL 	PLL1	(.inclk0(CLOCK_50),.c0(DRAM_CLK),.c1(CPU_CLK),.c2(CLK_25));
Audio_PLL 	PLL2	(.areset(!CPU_RESET),.inclk0(CLOCK_27),.c0(CLK_18_4));

system_0 	u0	(
				// 1) global signals:
                 .clk(CPU_CLK),
				 .clk_50(CLOCK_50),
                 .reset_n(CPU_RESET),

                // the_Audio_0
                 .iCLK_18_4_to_the_Audio_0(CLK_18_4),
                 .oAUD_BCK_from_the_Audio_0(AUD_BCLK),
                 .oAUD_DATA_from_the_Audio_0(AUD_DACDAT),
                 .oAUD_LRCK_from_the_Audio_0(AUD_DACLRCK),
                 .oAUD_XCK_from_the_Audio_0(AUD_XCK),

                // the_VGA_0
                 .VGA_BLANK_from_the_VGA_0(VGA_BLANK),
                 .VGA_B_from_the_VGA_0(VGA_B),
                 .VGA_CLK_from_the_VGA_0(VGA_CLK),
                 .VGA_G_from_the_VGA_0(VGA_G),
                 .VGA_HS_from_the_VGA_0(VGA_HS),
                 .VGA_R_from_the_VGA_0(VGA_R),
                 .VGA_SYNC_from_the_VGA_0(VGA_SYNC),
                 .VGA_VS_from_the_VGA_0(VGA_VS),
                 .iCLK_25_to_the_VGA_0(CLK_25),

                // the_SD_CLK
                 .out_port_from_the_SD_CLK(SD_CLK),

                // the_SD_CMD
                 .bidir_port_to_and_from_the_SD_CMD(SD_CMD),

                // the_SD_DAT
                 .bidir_port_to_and_from_the_SD_DAT(SD_DAT),

                // the_SEG7_Display
                 .oSEG0_from_the_SEG7_Display(),
                 .oSEG1_from_the_SEG7_Display(),
                 .oSEG2_from_the_SEG7_Display(),
                 .oSEG3_from_the_SEG7_Display(),
                 .oSEG4_from_the_SEG7_Display(),
                 .oSEG5_from_the_SEG7_Display(),
                 .oSEG6_from_the_SEG7_Display(),
                 .oSEG7_from_the_SEG7_Display(),

                // the_DM9000A
				 .ENET_CLK_from_the_DM9000A(ENET_CLK),
                 .ENET_CMD_from_the_DM9000A(ENET_CMD),
                 .ENET_CS_N_from_the_DM9000A(ENET_CS_N),
                 .ENET_DATA_to_and_from_the_DM9000A(ENET_DATA),
                 .ENET_INT_to_the_DM9000A(ENET_INT),
                 .ENET_RD_N_from_the_DM9000A(ENET_RD_N),
                 .ENET_RST_N_from_the_DM9000A(ENET_RST_N),
                 .ENET_WR_N_from_the_DM9000A(ENET_WR_N),
				 .iOSC_50_to_the_DM9000A(CLOCK_50),
				
                // the_ISP1362
                 .OTG_ADDR_from_the_ISP1362(OTG_ADDR),
                 .OTG_CS_N_from_the_ISP1362(OTG_CS_N),
                 .OTG_DATA_to_and_from_the_ISP1362(OTG_DATA),
                 .OTG_INT0_to_the_ISP1362(OTG_INT0),
                 .OTG_INT1_to_the_ISP1362(OTG_INT1),
                 .OTG_RD_N_from_the_ISP1362(OTG_RD_N),
                 .OTG_RST_N_from_the_ISP1362(OTG_RST_N),
                 .OTG_WR_N_from_the_ISP1362(OTG_WR_N),

                // the_button_pio
                 .in_port_to_the_button_pio(KEY),

                // the_lcd_16207_0
                 .LCD_E_from_the_lcd_16207_0(LCD_EN),
                 .LCD_RS_from_the_lcd_16207_0(LCD_RS),
                 .LCD_RW_from_the_lcd_16207_0(LCD_RW),
                 .LCD_data_to_and_from_the_lcd_16207_0(LCD_DATA),

                // the_led_green
                 .out_port_from_the_led_green(),

                // the_led_red
                 .out_port_from_the_led_red(),

                // the_sdram_0
                 .zs_addr_from_the_sdram_0(DRAM_ADDR),
                 .zs_ba_from_the_sdram_0({DRAM_BA_1,DRAM_BA_0}),
                 .zs_cas_n_from_the_sdram_0(DRAM_CAS_N),
                 .zs_cke_from_the_sdram_0(DRAM_CKE),
                 .zs_cs_n_from_the_sdram_0(DRAM_CS_N),
                 .zs_dq_to_and_from_the_sdram_0(DRAM_DQ),
                 .zs_dqm_from_the_sdram_0({DRAM_UDQM,DRAM_LDQM}),
                 .zs_ras_n_from_the_sdram_0(DRAM_RAS_N),
                 .zs_we_n_from_the_sdram_0(DRAM_WE_N),

                  // the_sram_0
                 .SRAM_ADDR_from_the_sram_0(SRAM_ADDR),
                 .SRAM_CE_N_from_the_sram_0(SRAM_CE_N),
                 .SRAM_DQ_to_and_from_the_sram_0(SRAM_DQ),
                 .SRAM_LB_N_from_the_sram_0(SRAM_LB_N),
                 .SRAM_OE_N_from_the_sram_0(SRAM_OE_N),
                 .SRAM_UB_N_from_the_sram_0(SRAM_UB_N),
                 .SRAM_WE_N_from_the_sram_0(SRAM_WE_N),

                // the_switch_pio
                 .in_port_to_the_switch_pio(SW),

                // the_tri_state_bridge_0_avalon_slave
                 .select_n_to_the_cfi_flash_0(FL_CE_N),
                 .tri_state_bridge_0_address(FL_ADDR),
                 .tri_state_bridge_0_data(FL_DQ),
                 .tri_state_bridge_0_readn(FL_OE_N),
                 .write_n_to_the_cfi_flash_0(FL_WE_N),

                // the_uart_0
                 .rxd_to_the_uart_0(UART_RXD),
                 .txd_from_the_uart_0(UART_TXD),

				  // the_cpu_arp_data
                  .in_port_to_the_cpu_arp_data(cpu_arp_data),

                  // the_cpu_arp_done
                  .out_port_from_the_cpu_arp_done(cpu_arp_done),

                  // the_cpu_arp_index
                  .out_port_from_the_cpu_arp_index(cpu_arp_index),

                  // the_cpu_arp_mac_h
                  .in_port_to_the_cpu_arp_mac_h(cpu_arp_mac[47:32]),

                  // the_cpu_arp_mac_l
                  .in_port_to_the_cpu_arp_mac_l(cpu_arp_mac[31:0]),

                  // the_cpu_arp_ready
                  .in_port_to_the_cpu_arp_ready(cpu_arp_ready),

                  // the_cpu_ip_data
                  .in_port_to_the_cpu_ip_data(cpu_ip_data),

                  // the_cpu_ip_done
                  .out_port_from_the_cpu_ip_done(cpu_ip_done),

                  // the_cpu_ip_index
                  .out_port_from_the_cpu_ip_index(cpu_ip_index),

                  // the_cpu_ip_length
                  .in_port_to_the_cpu_ip_length(cpu_ip_length),

                  // the_cpu_ip_mac_h
                  .in_port_to_the_cpu_ip_mac_h(cpu_ip_mac[47:32]),

                  // the_cpu_ip_mac_l
                  .in_port_to_the_cpu_ip_mac_l(cpu_ip_mac[31:0]),

                  // the_cpu_ip_ready
                  .in_port_to_the_cpu_ip_ready(cpu_ip_ready),

                  // the_data_ack
                  .in_port_to_the_data_ack(ack),

                  // the_data_in
                  .out_port_from_the_data_in(data_in_from_ethernet),

                  // the_data_type
                  .out_port_from_the_data_type(data_in_from_ethernet_type)
                );

I2C_AV_Config 	u1	(	//	Host Side
						.iCLK(CLOCK_50),
						.iRST_N(KEY[0]),
						//	I2C Side
						.I2C_SCLK(I2C_SCLK),
						.I2C_SDAT(I2C_SDAT)	);

	toplevel work(
		.clk(CLOCK_50),
		.reset(~KEY[0]),
		.data_in_from_ethernet(data_in_from_ethernet),
		.data_in_from_ethernet_type(data_in_from_ethernet_type),
		.cpu_ip_done(cpu_ip_done),
		.cpu_ip_index(cpu_ip_index),
		.cpu_arp_done(cpu_arp_done),
		.cpu_arp_index(cpu_arp_index),
		.data_out_from_app_valid(data_out_from_app_valid),
		.data_out_from_app(data_out_from_app),
		.dest_ip_addr(dest_ip_addr),
		.dest_port(dest_port),
		.data_out_from_app_length(data_out_from_app_length),
		.ack(ack),
		.cpu_ip_ready(cpu_ip_ready),
		.cpu_ip_mac(cpu_ip_mac),
		.cpu_ip_data(cpu_ip_data),
		.cpu_ip_length(cpu_ip_length),
		.cpu_arp_ready(cpu_arp_ready),
		.cpu_arp_mac(cpu_arp_mac),
		.cpu_arp_data(cpu_arp_data),
		.data_in_to_app_valid(data_in_to_app_valid),
		.data_in_to_app(data_in_to_app),
		.input_port(input_port)
	);

	//simple application
	assign data_out_from_app_valid = 1'b0;
	assign data_out_from_app = 32'b0;
	assign dest_ip_addr = 32'h0A0A0A8C;
	assign dest_port = 16'h0400; //port 1024
	assign data_out_from_app_length = 16'b0;
	//display incoming packets data
	always @(posedge CLOCK_50) begin
		if (data_in_to_app_valid) begin
			data_buffer <= data_in_to_app;
		end
	end
	HexDigit dig0(HEX0, data_buffer[3:0]);
	HexDigit dig1(HEX1, data_buffer[7:4]);
	HexDigit dig2(HEX2, data_buffer[11:8]);
	HexDigit dig3(HEX3, data_buffer[15:12]);
	HexDigit dig4(HEX4, data_buffer[19:16]);
	HexDigit dig5(HEX5, data_buffer[23:20]);
	HexDigit dig6(HEX6, data_buffer[27:24]);
	HexDigit dig7(HEX7, data_buffer[31:28]);

endmodule

module HexDigit(segs, num);
	input [3:0] num	;		//the hex digit to be displayed
	output [6:0] segs ;		//actual LED segments
	reg [6:0] segs ;
	always @ (num)
	begin
		case (num)
				4'h0: segs = 7'b1000000;
				4'h1: segs = 7'b1111001;
				4'h2: segs = 7'b0100100;
				4'h3: segs = 7'b0110000;
				4'h4: segs = 7'b0011001;
				4'h5: segs = 7'b0010010;
				4'h6: segs = 7'b0000010;
				4'h7: segs = 7'b1111000;
				4'h8: segs = 7'b0000000;
				4'h9: segs = 7'b0010000;
				4'ha: segs = 7'b0001000;
				4'hb: segs = 7'b0000011;
				4'hc: segs = 7'b1000110;
				4'hd: segs = 7'b0100001;
				4'he: segs = 7'b0000110;
				4'hf: segs = 7'b0001110;
				default segs = 7'b1111111;
		endcase
	end
endmodule
