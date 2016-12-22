module pipemwreg (mwreg,mm2reg,mmo,malu,mrn,clock,resetn,
                  wwreg,wm2reg,wmo,walu,wrn);

   input         mwreg,mm2reg;
   input  [31:0] mmo,malu;
   input   [4:0] mrn;

   input         clock,resetn;

   output        wwreg,wm2reg;
   output [31:0] wmo,walu;
   output  [4:0] wrn;
   
   reg           wwreg,wm2reg;
   reg    [31:0] wmo,walu;
   reg     [4:0] wrn;
	  
   always @ (negedge resetn or posedge clock)
      if (resetn == 0)
         begin
            wwreg    <=  1'b0;
            wm2reg   <=  1'b0;
            wmo      <= 32'b0;
            walu     <= 32'b0;
            wrn      <=  5'b0;
         end
      else
         begin 
            wwreg    <= mwreg;
            wm2reg   <= mm2reg;
            wmo      <= mmo;
            walu     <= malu;
            wrn      <= mrn;
         end

endmodule
