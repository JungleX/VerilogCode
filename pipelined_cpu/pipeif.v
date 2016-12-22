module pipeif ( pcsource,pc,bpc,da,jpc,npc,pc4,ins,rom_clk );   // if state
//pipeif if_stage ( pcsource,pc,bpc,da,jpc,npc,pc4,ins,clock );    // add rom_clk

   input  [31:0] pc,bpc,jpc,da ;
   output [31:0] npc,pc4,ins ; 
   input   [1:0] pcsource ;
   input         rom_clk ;
   
   wire   [31:0] pc,bpc,jpc,da,npc,pc4,ins ;
   wire    [1:0] pcsource ;
   wire          rom_clk ;
   
   assign  pc4 = pc + 4'b0100;
   
   mux4x32 mux_next_pc ( pc4,bpc,da,jpc,pcsource,npc );
   pipeline_inst_rom  inst_rom ( pc[9:2],rom_clk,ins ) ;


   
endmodule

/*   
  module pipeline_inst_rom (
	address,
	clock,
	q);

	input	[7:0]  address;
	input	  clock;
	output	[31:0]  q; 
	
endmodule   */