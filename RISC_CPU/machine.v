//---machine.v---
`timescale 1ns/1ns
module machine(inc_pc,load_acc,load_pc,rd,wr,load_ir,datactl_ena,halt,clk,zero,ena,opcode);
output inc_pc,load_acc,load_pc,rd,wr,load_ir;
output datactl_ena,halt;
input clk,zero,ena;
input[2:0] opcode;
reg inc_pc,load_acc,load_pc,rd,wr,load_ir;
reg datactl_ena,halt;
reg[2:0] state;

parameter	HLT  = 3'b000,
				SKZ  = 3'b001,
				ADD  = 3'b010,
				ANDD = 3'b011,
				XORR = 3'b100,
				LDA  = 3'b101,
				STO  = 3'b110,
				JMP  = 3'b111;

always @(posedge clk)
begin
	if(!ena)
		begin
			state <= 3'b000;
			{inc_pc,load_acc,load_pc,rd} <= 4'b0000;
			{wr,load_ir,datactl_ena,halt} <= 4'b0000;
		end
	else
		ctl_cycle;
end

//---ctl_cycle---
task ctl_cycle;
begin
	casex(state)
		3'b000:
			begin
				{inc_pc,load_acc,load_pc,rd} <= 4'b0001;
				{wr,load_ir,datactl_ena,halt} <= 4'b0100;
				state <= 3'b001;
			end
		3'b001:
			begin
				{inc_pc,load_acc,load_pc,rd} <= 4'b1001;
				{wr,load_ir,datactl_ena,halt} <= 4'b0100;
				state <= 3'b010;
			end
		3'b010: //idle
			begin
				{inc_pc,load_acc,load_pc,rd} <= 4'b0000;
				{wr,load_ir,datactl_ena,halt} <= 4'b0000;
				state <= 3'b011;
			end
		3'b011:
			begin
				if(opcode == HLT)
					begin
						{inc_pc,load_acc,load_pc,rd} <= 4'b1000;
						{wr,load_ir,datactl_ena,halt} <= 4'b0001;
					end
				else
					begin
						{inc_pc,load_acc,load_pc,rd} <= 4'b1000;
						{wr,load_ir,datactl_ena,halt} <= 4'b0000;
					end
				state <= 3'b100;
			end
		3'b100:
			begin
				if(opcode == JMP)
					begin
						{inc_pc,load_acc,load_pc,rd} <= 4'b0010;
						{wr,load_ir,datactl_ena,halt} <= 4'b0001;
					end
				else
					if(opcode == ADD || opcode == ANDD || opcode == XORR || opcode == LDA)
						begin
							{inc_pc,load_acc,load_pc,rd} <= 4'b0001;
							{wr,load_ir,datactl_ena,halt} <= 4'b0000;
						end
					else
						if(opcode == STO)
							begin
								{inc_pc,load_acc,load_pc,rd} <= 4'b0000;
								{wr,load_ir,datactl_ena,halt} <= 4'b0010;
							end
						else
							begin
								{inc_pc,load_acc,load_pc,rd} <= 4'b0000;
								{wr,load_ir,datactl_ena,halt} <= 4'b0000;
							end
				state <= 3'b101;
			end
		3'b101:
			begin
				if(opcode == ADD || opcode == ANDD || opcode == XORR || opcode == LDA)
					begin
						{inc_pc,load_acc,load_pc,rd} <= 4'b0101;
						{wr,load_ir,datactl_ena,halt} <= 4'b0000;
					end
				else
					if(opcode == SKZ && zero == 1)
						begin
							{inc_pc,load_acc,load_pc,rd} <= 4'b1000;
							{wr,load_ir,datactl_ena,halt} <= 4'b0000;
						end
					else
						if(opcode == JMP)
							begin
								{inc_pc,load_acc,load_pc,rd} <= 4'b0101;
								{wr,load_ir,datactl_ena,halt} <= 4'b0000;
							end
						else
							if(opcode == STO)
								begin
									{inc_pc,load_acc,load_pc,rd} <= 4'b0000;
									{wr,load_ir,datactl_ena,halt} <= 4'b1010;
								end
							else
								begin
									{inc_pc,load_acc,load_pc,rd} <= 4'b0000;
									{wr,load_ir,datactl_ena,halt} <= 4'b0000;
								end
				state <= 3'b110;
			end
		3'b110: //idle
			begin
				if(opcode == STO)
					begin
						{inc_pc,load_acc,load_pc,rd} <= 4'b0000;
						{wr,load_ir,datactl_ena,halt} <= 4'b0010;
					end
				else
					if(opcode == ADD || opcode == ANDD || opcode == XORR || opcode == LDA)
						begin
							{inc_pc,load_acc,load_pc,rd} <= 4'b0001;
							{wr,load_ir,datactl_ena,halt} <= 4'b0000;
						end
					else
						begin
							{inc_pc,load_acc,load_pc,rd} <= 4'b0000;
							{wr,load_ir,datactl_ena,halt} <= 4'b0000;
						end
				state <= 3'b111;
			end
		3'b111:
			begin
				if(opcode == SKZ && zero == 1)
					begin
						{inc_pc,load_acc,load_pc,rd} <= 4'b1000;
						{wr,load_ir,datactl_ena,halt} <= 4'b0000;
					end
				else
					begin
						{inc_pc,load_acc,load_pc,rd} <= 4'b0000;
						{wr,load_ir,datactl_ena,halt} <= 4'b0000;
					end
				state <= 3'b000;
			end
		default:
			begin
				{inc_pc,load_acc,load_pc,rd} <= 4'b0000;
				{wr,load_ir,datactl_ena,halt} <= 4'b0000;
				state <= 3'b000;
			end	
		endcase
end
endtask
//---ctl_cycle end---
endmodule