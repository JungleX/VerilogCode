module pipemem( mwmem,malu,mb,clock,ram_clk,mmo);

   input         mwmem;
   input  [31:0] malu,mb;
   input         clock,ram_clk;

   output [31:0] mmo;

// wire mwmem_clock;
// assign mwmem_clock = mwmem & (~clock) ;

   lpm_ram_dq0 d_ram1(malu[9:2],ram_clk,mb,mwmem,mmo);

endmodule
