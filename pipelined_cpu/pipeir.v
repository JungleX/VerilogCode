module pipeir ( pc4,ins,wpcir,clock,resetn,dpc4,inst );   // if state
//pipeir inst_reg   ( pc4,ins,wpcir,clock,resetn,dpc4,inst );
   
   input  [31:0] pc4,ins ;
   input         wpcir,clock,resetn ;
   output [31:0] dpc4,inst ;
   
   wire   [31:0] pc4,ins ;
   wire          wpcir,clock,resetn ;
   
   reg    [31:0] dpc4,inst ;
	
	
   always @ (negedge resetn or posedge clock)
      if (resetn == 0)
         begin
            dpc4 <= 0;
            inst <= 0;          
         end 
      else if (wpcir == 1) 
         begin 
            dpc4 <= pc4;
            inst <= ins;
         end

endmodule
