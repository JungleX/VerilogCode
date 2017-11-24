`timescale 1ns / 1ps

`define clk_period 10

`include "CNN_Parameter.vh"

module FeatureMapRamFloat16_tb();

	reg clk;
	reg ena_w; 
	reg ena_r;

    reg ena_zero_w; // 0: not write; 1: write
    reg [`WRITE_ADDR_WIDTH - 1:0] zero_start_addr;
    reg [`WRITE_ADDR_WIDTH - 1:0] zero_end_addr;

	reg ena_add_write; // 0: not add; 1: add
	reg [`WRITE_ADDR_WIDTH - 1:0] addr_write;
	reg [`PARA_Y*`DATA_WIDTH - 1:0] din;

    reg ena_para_w; // 0: not write; 1: write
    reg [`WRITE_ADDR_WIDTH - 1:0] addr_para_write;
    reg [`FM_SIZE_WIDTH - 1:0] fm_out_size;
    reg [`PARA_Y*`PARA_KERNEL*`DATA_WIDTH - 1:0] para_din;

    reg [1:0] read_type;
	reg [`READ_ADDR_WIDTH - 1:0] addr_read;
	reg [`READ_ADDR_WIDTH - 1:0] sub_addr_read;

	wire write_ready;
	wire [`PARA_Y*`DATA_WIDTH - 1:0] dout;

	FeatureMapRamFloat16 ram_fm(
		.clk(clk),

        .ena_add_write(ena_add_write), // 0: not add; 1: add

        .ena_zero_w(ena_zero_w),
        .zero_start_addr(zero_start_addr),
        .zero_end_addr(zero_end_addr),

		.ena_w(ena_w), // 0: read; 1: write
		.addr_write(addr_write),
		.din(din),

        .ena_para_w(ena_para_w),        
        .addr_para_write(addr_para_write),
        .fm_out_size(fm_out_size),
        .para_din(para_din),

		.ena_r(ena_r),
        .read_type(read_type),
		.addr_read(addr_read),
		.sub_addr_read(sub_addr_read),

		.write_ready(write_ready),
		.dout(dout)
    );

	initial 
        clk = 1'b0;
    always #(`clk_period/2)clk = ~clk;

    initial begin
    	#0

    	#(`clk_period/2)

        // para write
        #`clk_period
        ena_zero_w <= 0;
        ena_w <= 0;
        ena_para_w <= 1;
        ena_add_write <= 1;
        addr_para_write <= 9; // padding = 1; 6+1*2 + 1 = 9
        fm_out_size <= 8; // 6+1*2=8
        para_din <= {16'h3c00, 16'h4000, 16'h3c00, 16'h3c00, 16'h4000, 16'h4200};

        //#(`clk_period*2)
        #`clk_period
        ena_para_w <= 1;

        while(write_ready == 0) begin
            #`clk_period
            ena_para_w <= 1;
        end

        //#`clk_period
        ena_para_w <= 0;
        ena_w <= 0;
        ena_zero_w <= 0;

        #`clk_period
        ena_zero_w <= 0;
        ena_w <= 0;
        ena_para_w <= 1;
        ena_add_write <= 1;
        addr_para_write <= 9;
        fm_out_size <= 8;
        para_din <= {16'h3c00, 16'h4000, 16'h4200, 16'h4000, 16'h3c00, 16'h4200};

        #`clk_period
        ena_para_w <= 1;

        while(write_ready == 0) begin
            #`clk_period
            ena_para_w <= 1;
        end

        //#`clk_period
        ena_para_w <= 0;
        ena_w <= 0;
        ena_zero_w <= 0;
    	// PARA_Y = 3 ============================================= 

        // PARA_Y = 3 CONV read =============================================
        #`clk_period
        ena_r      <= 1;
        read_type   <= 0;
        addr_read  <= 3;
        sub_addr_read <= 0;

        #`clk_period
        read_type   <= 0;
        addr_read  <= 3;
        sub_addr_read <= 1;
        // PARA_Y = 3 CONV read =============================================

        // PARA_Y = 3 POOL read =============================================
        #`clk_period
        ena_r      <= 1;
        read_type   <= 1;
        addr_read  <= 9;

        #`clk_period
        read_type   <= 1;
        addr_read  <= 10;
        // PARA_Y = 3 POOL read =============================================

        // PARA_Y = 3 FC read =============================================
        #`clk_period
        ena_r      <= 1;
        read_type   <= 2;
        addr_read  <= 9;

        #`clk_period
        read_type   <= 2;
        addr_read  <= 10;
        // PARA_Y = 3 FC read =============================================
    end
endmodule