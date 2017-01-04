module seqdet(x,z,clk,rst,state);

input x,clk,rst;
output z;
output[2:0] state;
reg[2:0] state;
wire z;

parameter IDLE='d0, A='d1, B='d2, 
	C='d3, D='d4, E='d5, F='d6, G='d7;

assign z=(state==E && x==0)?1:0;
always@(posedge clk)
	if(!rst)
		begin
		state<=IDLE;
		end
	else
		casex(state)
			IDLE: if(x==1)
				begin
				state<=A;
				end
			A: if(x==0)
				begin
				state<=B;
				end
			B: if(x==0)
				begin
				state<=C;
				end
			    else
				begin
				state<=F;
				end
			C: if(x==1)
				begin
				state<=D;
				end
			    else
				begin
				state<=G;
				end
			D: if(x==0)
				begin
				state<=E;
				end
			    else
				begin
				state<=A;
				end
			E: if(x==0)
				begin
				state<=C;
				end
			    else
				begin
				state<=A;
				end
			F: if(x==1)
				begin
				state<=A;
				end
			    else
				begin
				state<=B;
				end
			G: if(x==1)
				begin
				state<=F;
				end
			default: state=IDLE;
		endcase
endmodule
