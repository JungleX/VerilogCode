//---cputop.v---
/*`include "cpu.v"
`include "ram.v"
`include "rom.v"
`include "addr_decode.v"*/

`timescale 1ns/1ns
`define PERIOD 100

module cputop;
reg reset_reg,clock;
integer test;
reg[(3*8):0] mnemonic;
reg[12:0] PC_addr,IR_addr;
wire[7:0] data;
wire[12:0] addr;
wire rd,wr,halt,ram_sel,rom_sel;
wire[2:0] opcode;
wire fetch;
wire[12:0] ir_addr,pc_addr;

//---CPU?????????ROM?RAM?????---
cpu t_cpu(.clk(clock),.reset(reset_reg),.halt(halt),.rd(rd),.wr(wr),
          .addr(addr),.data(data),.opcode(opcode),.fetch(fetch),
			 .ir_addr(ir_addr),.pc_addr(pc_addr));

ram t_ram(.addr(addr[9:0]),.read(rd),.write(wt),.ena(ram_sel),.data(data));

rom t_rom(.addr(addr),.read(rd),.ena(rom_sel),.data(data));

addr_decode t_add_decode(.addr(addr),.ram_sel(ram_sel),.rom_sel(rom_sel));

//---end of CPU?????????ROM?RAM?????---
initial
	begin
		clock = 1;
		$timeformat(-9, 1, "ns", 12);
		display_debug_message;
		sys_reset;
		test1;
//		$stop;
//		test2;
//		$stop;
//		test3;
		$finish;
	end

task display_debug_message;
	begin
		$display("\n*******************************************");
		$display(  "* THE FOLLOWING DEBUG TASK ARE AVAILABLE: *");
		$display(  "* \"test1;\" to load the 1st diagnostic program. *");
//		$display(  "");
//		$display(  "");
		$display(  "*******************************************\n");
	end
endtask

//reg[7:0] memory[13'h1fff:0];

task test1;
	begin
		test = 0;
		disable MONITOR;
		$readmemb("test1.pro",t_rom.memory);
		$display("rom loaded successfully!");
		$readmemb("test1.dat",t_ram.ram);
		$display("ram loaded successfully!");
		#1 test = 1;
		#14800 ;
		sys_reset;
	end
endtask

/*
task test2;
	begin
	end
endtask

task test3;
	begin
	end
endtask
*/

task sys_reset;
	begin
		reset_reg = 0;
		#(`PERIOD*0.7) reset_reg = 1;
		#(1.5*`PERIOD) reset_reg= 0;
	end
endtask

always @(test)
	begin:MONITOR
		case(test)
			1:
				begin
					$display("\n*** RUNNING CPUtest1 - The Basic CPU Diagnostic Program ***");
					$display("\n      TIME       pc       INSTR       ADDR       DATA");
					$display("    -------     ----     -------     ------     ------");
					while(test == 1)
						begin
							@(t_cpu.pc_addr)//fixed
							if((t_cpu.pc_addr%2 == 1)&&(t_cpu.fetch == 1))//fixed
								begin
									#60 PC_addr <= t_cpu.pc_addr - 1;
										 IR_addr <= t_cpu.ir_addr;
									#340 $strobe("%t    %h    %s    %h   %h", $time, PC_addr, mnemonic, IR_addr, data);
								end
						end
				end
/*			2:
				begin
				end
			3:
				begin
				end
*/
		endcase
	end
	
//------------------------------------------
always @(posedge halt)
	begin
		#500
			$display("\n****************************************");
			$display(  "** A HALT INSTRUCTION WAS PROCESSED !!!");
			$display("****************************************\n");
	end

always #(`PERIOD/2) clock = ~ clock;

always @(t_cpu.opcode)
	case(t_cpu.opcode)
		3'b000: mnemonic = "HLT";
		3'b001: mnemonic = "SKZ";
		3'b010: mnemonic = "ADD";
		3'b011: mnemonic = "AND";
		3'b100: mnemonic = "XOR";
		3'b101: mnemonic = "LDA";
		3'b110: mnemonic = "STO";
		3'b111: mnemonic = "JMP";
		default: mnemonic = "???";
	endcase
	
endmodule