`timescale 1ns/1ns
`include "./compare.v"

module t;
reg a,b;
wire equal;
initial
	begin
		a=0;
		b=0;
	#100 a=0;b=1;
	#100 a=1;b=1;
	#100 a=1;b=0;
	#100 a=0;b=0;
	#100 $stop;
	end

	compare m(.equal(equal),.a(a),.b(b));
endmodule