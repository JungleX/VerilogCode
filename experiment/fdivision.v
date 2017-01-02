module fdivision(RESET,F10_MB,F500_KB);
	input F10_MB,RESET;
	output F500_KB;
	reg F500_KB;
	reg[7:0]j;
	
	always @(posedge F10_MB)
		if(!RESET)
			begin
				F500_KB<=0;
				j<=0;
			end
		else
			begin
				if(j==19)
					begin
						j<=0;
						F500_KB<=~F500_KB;
					end
				else
					j<=j+1;
			end
endmodule
