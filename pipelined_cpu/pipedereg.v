module pipedereg ( dwreg,dm2reg,dwmem,daluc,daluimm,da,db,dimm,drn,
                   dshift,djal,dpc4,clock,resetn,ewreg,em2reg,ewmem,
                   ealuc,ealuimm,ea,eb,eimm,ern0,eshift,ejal,epc4 );

   input         dwreg,dm2reg,dwmem,djal,daluimm,dshift;
   input  [31:0] dpc4,da,db,dimm ;
   input  [3:0]  daluc;
   input  [4:0]  drn;
   wire          dwreg,dm2reg,dwmem,djal,daluimm,dshift;
   wire   [31:0] dpc4,da,db,dimm ;
   wire   [3:0]  daluc;
   wire   [4:0]  drn;

   input         clock,resetn;
   wire          clock,resetn;

   output        ewreg,em2reg,ewmem,ejal,ealuimm,eshift;
   output [31:0] epc4,ea,eb,eimm ;
   output [3:0]  ealuc;
   output [4:0]  ern0;
	
   reg           ewreg,em2reg,ewmem,ejal,ealuimm,eshift;
   reg    [31:0] epc4,ea,eb,eimm ;	
   reg    [3:0]  ealuc;
   reg    [4:0]  ern0;

   always @ (negedge resetn or posedge clock)
      if (resetn == 0) 
         begin
            epc4       <= 32'b0;
            ea         <= 32'b0;
            eb         <= 32'b0;
            eimm       <= 32'b0; 
            ealuc      <=  4'b0;
            ern0       <=  5'b0;
            ewreg      <=  1'b0;
            em2reg     <=  1'b0;
            ewmem      <=  1'b0;
            ejal       <=  1'b0;
            ealuimm    <=  1'b0;
            eshift     <=  1'b0;
         end 
      else
         begin 
            epc4       <=  dpc4;
            ea         <=  da;
            eb         <=  db;
            eimm       <=  dimm;
            ealuc[3:0] <=  daluc[3:0];
            ern0       <=  drn;
            ewreg      <=  dwreg;
            em2reg     <=  dm2reg;
            ewmem      <=  dwmem;
            ejal       <=  djal;
            ealuimm    <=  daluimm;
            eshift     <=  dshift;
         end
endmodule
