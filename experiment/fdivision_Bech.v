`timescale 1ns/100ps
`define clk_cycle 50

module division_Bench;
reg F10_MB,RESET;
wire F500_KB_clk;

always #`clk_cycle F10_MB=~F10_MB;

initial
	begin
		RESET=1;
		F10_MB=0;
		#100 RESET=0;
		#100 RESET=1;
		#10000 $stop;
	end

fdivision fdivision(.RESET(RESET),.F10_MB(F10_MB),.F500_KB(F500_KB_clk));

endmodule