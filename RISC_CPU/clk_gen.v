//---clk_gen.v---
`timescale 1ns/1ns
module clk_gen(clk,reset,fetch,alu_ena);
input clk,reset;
output fetch,alu_ena;
wire clk,reset;
reg fetch,alu_ena;
reg[7:0] state;
parameter S1   = 8'b00000001,
				  S2   = 8'b00000010,
				  S3   = 8'b00000100,
				  S4   = 8'b00001000,
				  S5   = 8'b00010000,
				  S6   = 8'b00100000,
				  S7   = 8'b01000000,
				  S8   = 8'b10000000,
				  idle = 8'b00000000;

always @(posedge clk)
	if(reset)
		begin
			fetch <= 0;
			alu_ena <= 0;
			state <= idle;
		end
	else
		begin
			case(state)
				S1:
					begin
						alu_ena <= 1;
						state <= S2;
					end
				S2:
					begin
						alu_ena <= 0;
						state <= S3;
					end
				S3:
					begin
						fetch <= 1;
						state <= S4;
					end
				S4: state <= S5;
				S5: state <= S6;
				S6: state <= S7;
				S7: 
					begin
						fetch <= 0;
						state <= S8;
					end
				S8: state <= S1;
				idle: state <= S1;
				default: state <= idle;
			endcase
		end
endmodule