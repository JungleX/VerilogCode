module alu (a,b,aluc4,s,z);
   input [31:0] a,b;
   input [3:0]  aluc4;
   output [31:0] s;
   output        z;
   wire [3:0] aluc4;
   reg [31:0] s;
   reg        z;
   always @ (a or b or aluc4) 
      begin                                   // event
         casex (aluc4)
             4'bx000: s = a + b;              //x000 ADD
             4'bx100: s = a - b;              //x100 SUB
             4'bx001: s = a & b;              //x001 AND
             4'bx101: s = a | b;              //x101 OR
             4'bx010: s = a ^ b;              //x010 XOR
             4'bx110: s = b << 32'h0F;        //LUI: imm << 16bit             
             4'b0011: s = b << a;             //SLL: rd <- (rt << sa)
             4'b0111: s = b >> a;             //SRL: rd <- (rt >> sa) (logical)
             4'b1111: s = $signed(b) >>> a;   //SRA: rd <- (rt >> sa) (arithmetic)
             default: s = 0;
         endcase
         if (s == 0 )  z = 1;
            else z = 0;         
      end      
endmodule 