module pipeid ( mwreg,mrn,ern,ewreg,em2reg,mm2reg,dpc4,inst,    // id state
                wrn,wdi,ealu,malu,mmo,wwreg,clock,resetn,
                bpc,jpc,pcsource,wpcir,dwreg,dm2reg,dwmem,daluc,
                daluimm,da,db,dimm,drn,dshift,djal );  // and "dsa" ? not necessary! dimm is enough!

   input         mwreg,ewreg,em2reg,mm2reg ;
   input         wwreg,clock,resetn;
   input  [31:0] dpc4,inst,wdi,ealu,malu,mmo ;
   input  [4:0]  wrn,mrn,ern ;
   
   output [31:0] bpc,jpc,da,db ;
   output [1:0]  pcsource ;
   output [3:0]  daluc ;
   output [4:0]  drn ;
   output        wpcir,dwreg,dm2reg,dwmem,daluimm,dshift,djal;
   output [31:0] dimm ;

   wire           mwreg,ewreg,em2reg,mm2reg ;
   wire           wwreg,clock,resetn;
   wire   [31:0]  dpc4,inst,wdi,ealu,malu,mmo ;
   wire   [4:0]   wrn,mrn,ern ;
   
   wire   [31:0] bpc,jpc,da,db ;
   wire   [1:0]  pcsource ;
   wire   [3:0]  daluc ;
   wire   [4:0]  drn ;
   wire          wpcir,dwreg,dm2reg,dwmem,daluimm,dshift,djal;


// ---------------------------------

   wire   [1:0]  fwda,fwdb;
   wire          regrt,sext,rsrtequ;
   wire   [31:0] rf_q1,rf_q2;        // inside the mode
   
// ---------------------------------

   wire [13:0]  bpc_sign_ext = {14 {inst[15]}};
   assign bpc = { bpc_sign_ext,inst[15:0],2'b00} + dpc4;  // 

   assign jpc = { dpc4[31:28],inst[25:0],2'b00 };//jal,j,左移两位，与pc4的高4位拼接

   assign rsrtequ = ( da==db );
// equal equal_no(da,db,rsrtequ); //zr

// wire [31:0]   dsa = { 27'b0, inst[10:6] }; // extend to 32 bits from sa for shift instruction
   wire          e = sext & inst[15];          // positive or negative sign at sext signal
   wire [15:0]   imm_es = {16{e}};                // high 16 sign bit
   wire [31:0]   dimm = {imm_es,inst[15:0]}; // sign extend to high 16



// ----------------------------------

   regfile rf (inst[25:21],inst[20:16],wdi,wrn,wwreg,clock,resetn,rf_q1,rf_q2);
// regfile rf (inst[25:21],inst[20:16],wdi,wrn,wwreg,clock,resetn,q1,q2); //zr
// module regfile (rna,rnb,d,wn,we,clk,clrn,qa,qb);


   mux4x32 mux_sel_da (rf_q1,ealu,malu,mmo,fwda,da);    // rf_q1
// mux4x32 fwda_mux (q1,ealu,malu,mmo,fwda,da); //zr
   mux4x32 mux_sel_db (rf_q2,ealu,malu,mmo,fwdb,db);    // rf_q2
// mux4x32 fwdb_mux (q2,ealu,malu,mmo,fwdb,db); //zr
   mux2x5  mux_sel_regrt_rn (inst[15:11],inst[20:16],regrt,drn);  // sel drn.
// mux2x5  regrt_rn (inst[25:21],inst[20:16],regrt,drn); //zr *
// mux2x5  reg_wn (minst[15:11],minst[20:16],regrt,reg_dest); // mc


   pipe_cu cu (inst[31:26],inst[5:0],inst[25:21],inst[20:16],rsrtequ,
               dwreg,dm2reg,dwmem,daluc,daluimm,dshift,djal,regrt,sext,fwda,fwdb,
               mrn,mm2reg,mwreg,ern,em2reg,ewreg,pcsource,wpcir,clock );


endmodule



