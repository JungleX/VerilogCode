module compare(equal,a,b);
	input a,b;
	output equal;
	assign equal=(a==b)?1:0;
endmodule
