module pipelined_computer (resetn,clock,mem_clock,pc,ins,inst,ealu,malu,walu);
   input         resetn,clock,mem_clock;
   output [31:0] pc,ins,inst,ealu,malu,walu;
   wire   [31:0] bpc,jpc,npc,pc4,ins,dpc4,inst,da,db,dimm,ea,eb,eimm;
   wire   [31:0] epc4,mb,mmo,wmo,wdi;
   wire   [4:0]  drn,ern0,ern,mrn,wrn;
   wire   [3:0]  daluc,ealuc;
   wire   [1:0]  pcsource;
   wire          wpcir;
   wire          dwreg,dm2reg,dwmem,daluimm,dshift,djal; // id stage
   wire          ewreg,em2reg,ewmem,ealuimm,eshift,ejal; // exe stage
   wire          mwreg,mm2reg,mwmem;                     // mem stage
   wire          wwreg,wm2reg;                           // wb stage
   
   pipepc prog_cnt   ( npc,wpcir,clock,resetn,pc );
//     module pipepc ( npc,wpcir,clock,resetn,pc );
   
   pipeif if_stage   ( pcsource,pc,bpc,da,jpc,npc,pc4,ins,mem_clock );    // add rom_clk
//     module pipeif ( pcsource,pc,bpc,da,jpc,npc,pc4,ins,rom_clk );   // if state

   pipeir inst_reg   ( pc4,ins,wpcir,clock,resetn,dpc4,inst );
//     module pipeir ( pc4,ins,wpcir,clock,resetn,dpc4,inst );   // if state   
   
   pipeid id_stage   ( mwreg,mrn,ern,ewreg,em2reg,mm2reg,dpc4,inst,
                       wrn,wdi,ealu,malu,mmo,wwreg,clock,resetn,
                       bpc,jpc,pcsource,wpcir,dwreg,dm2reg,dwmem,daluc,
                       daluimm,da,db,dimm,drn,dshift,djal );        // dimm include sa.
//     module pipeid ( mwreg,mrn,ern,ewreg,em2reg,mm2reg,dpc4,inst,    // id state
//                     wrn,wdi,ealu,malu,mmo,wwreg,clock,resetn,
//                     bpc,jpc,pcsource,wpcir,dwreg,dm2reg,dwmem,daluc,
//                     daluimm,da,db,dimm,drn,dshift,djal );  // and "dsa" ? not necessary! dimm is enough!
                       
   pipedereg de_reg  ( dwreg,dm2reg,dwmem,daluc,daluimm,da,db,dimm,drn,
                       dshift,djal,dpc4,clock,resetn,ewreg,em2reg,ewmem,
                       ealuc,ealuimm,ea,eb,eimm,ern0,eshift,ejal,epc4 ); // in dsa out esa
                       
                       
   pipeexe exe_stage ( ealuc,ealuimm,ea,eb,eimm,eshift,ern0,epc4,ejal,
                       ern,ealu );                                       // in esa
                       
                       
   pipeemreg em_reg  ( ewreg,em2reg,ewmem,ealu,eb,ern,clock,resetn,
                       mwreg,mm2reg,mwmem,malu,mb,mrn);
                       
                       
   pipemem mem_stage ( mwmem,malu,mb,clock,mem_clock,mmo );
   
   
   pipemwreg mw_reg  ( mwreg,mm2reg,mmo,malu,mrn,clock,resetn,
                       wwreg,wm2reg,wmo,walu,wrn);
                       
                       
                       
   mux2x32 wb_stage  ( walu,wmo,wm2reg,wdi );
   
endmodule

/* module pipelined_comp (clock,memclock,resetn,pc,inst,ealu,malu,walu);
   input clock,memclock,resetn;
   output [31:0] pc,inst,ealu,malu,walu;
   wire [31:0] bpc,jpc,npc,pc4,ins,pcfour,inst,da,db,dimm,ea,eb,eimm;
   wire [31:0] epcfour,mb,mmo,wmo,wrfdi;
   wire [4:0] ddesr,edesr0,edesr,mdesr,wdesr;
   wire [3:0] daluc,ealuc;
   wire [1:0] pcsource;
   wire wpcir;
   wire dwreg,dm2reg,dwmem,daluimm,dshift,djal;
   wire ewreg,em2reg,ewmem,ealuimm,eshift,ejal;
   wire mwreg,mm2reg,mwmem;
   wire wwreg,wm2reg;
   pipepc prog_cnt   ( npc,wpcir,clock,resetn,pc );
   pipeif if_stage   ( pcsource,pc,bpc,da,jpc,npc,pc4,ins );
   pipeir inst_reg   ( pc4,ins,wpcir,clock,resetn,pcfour,inst );
   pipeid id_stage   ( mwreg,mdesr,edesr0,ewreg,em2reg,mm2reg,pcfour,inst,
                       wdesr,wrfdi,ealu,malu,mmo,wwreg,clock,resetn,
                       bpc,jpc,pcsource,wpcir,dwreg,dm2reg,dwmem,daluc,
                       daluimm,da,db,dimm,ddesr,dshift,djal );
   pipedereg de_reg  ( dwreg,dm2reg,dwmem,daluc,daluimm,da,db,dimm,ddesr,
                       dshift,djal,pcfour,clock,resetn,ewreg,em2reg,ewmem,
                       ealuc,ealuimm,ea,eb,eimm,edesr0,eshift,ejal,epcfour );
   pipeexe exe_stage ( ealuc,ealuimm,ea,eb,eimm,eshift,edesr0,epcfour,ejal,
                       edesr,ealu);
   pipeemreg em_reg  ( ewreg,em2reg,ewmem,ealu,eb,edesr,clock,resetn,
                       mwreg,mm2reg,mwmem,malu,mb,mdesr );
   pipemem mem_stage ( mwmem,malu,mb,clock,memclock,memclock,mmo );
   pipemwreg mw_reg  ( mwreg,mm2reg,mmo,malu,mdesr,clock,resetn,
                       wwreg,wm2reg,wmo,walu,wdesr );
   mux2x32 wb_stage  ( walu,wmo,wm2reg,wrfdi ); endmodule */