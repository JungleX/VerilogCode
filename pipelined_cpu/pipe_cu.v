module pipe_cu ( op,func,rs,rt,rsrtequ,
                 dwreg,dm2reg,dwmem,daluc,daluimm,dshift,djal,regrt,sext,fwda,fwdb,
                 mrn,mm2reg,mwreg,ern,em2reg,ewreg,
                 pcsource,wpcir,clock );

   input  [5:0]  op,func;
   input  [4:0]  rs,rt,mrn,ern;
   input         rsrtequ;
   input		 mm2reg,mwreg,em2reg,ewreg;
   input         clock;

   output        dwreg,regrt,djal,dm2reg,dshift,daluimm,sext,dwmem;
   output [3:0]  daluc;
   output [1:0]  pcsource,fwda,fwdb;
   output		 wpcir;
	
   wire   [4:0]  ern,mrn;
	
   reg    [1:0]  fwda,fwdb;
//   wire   [1:0]  fwda,fwdb;
//   assign        fwda = 2'b0;
//   assign        fwdb = 2'b0;

   wire          dwreg,regrt,djal,dm2reg,dshift,daluimm,sext,dwmem;
   wire   [3:0]  daluc;
   wire   [1:0]  pcsource;
   wire		     wpcir;
   
   
   


	


   wire r_type = ~|op;
   wire i_add = r_type & func[5] & ~func[4] & ~func[3] &
                ~func[2] & ~func[1] & ~func[0];          //100000
   wire i_sub = r_type & func[5] & ~func[4] & ~func[3] &
                ~func[2] &  func[1] & ~func[0];          //100010
   wire i_and = r_type & func[5] & ~func[4] & ~func[3] &
                 func[2] & ~func[1] & ~func[0];          //100100
   wire i_or  = r_type & func[5] & ~func[4] & ~func[3] &
                 func[2] & ~func[1] &  func[0];          //100101
   wire i_xor = r_type & func[5] & ~func[4] & ~func[3] &
                 func[2] &  func[1] & ~func[0];          //100110
   wire i_sll = r_type & ~func[5] & ~func[4] & ~func[3] &
                ~func[2] & ~func[1] & ~func[0];          //000000
   wire i_srl = r_type & ~func[5] & ~func[4] & ~func[3] &
                ~func[2] &  func[1] & ~func[0];          //000010
   wire i_sra = r_type & ~func[5] & ~func[4] & ~func[3] &
                ~func[2] &  func[1] &  func[0];          //000011
   wire i_jr  = r_type & ~func[5] & ~func[4] &  func[3] &
                ~func[2] & ~func[1] & ~func[0];          //001000
                
   wire i_addi = ~op[5] & ~op[4] &  op[3] & ~op[2] & ~op[1] & ~op[0]; //001000
   wire i_andi = ~op[5] & ~op[4] &  op[3] &  op[2] & ~op[1] & ~op[0]; //001100
   wire i_ori  = ~op[5] & ~op[4] &  op[3] &  op[2] & ~op[1] &  op[0]; //001101
   wire i_xori = ~op[5] & ~op[4] &  op[3] &  op[2] &  op[1] & ~op[0]; //001110
   wire i_lw   =  op[5] & ~op[4] & ~op[3] & ~op[2] &  op[1] &  op[0]; //100011
   wire i_sw   =  op[5] & ~op[4] &  op[3] & ~op[2] &  op[1] &  op[0]; //101011
   wire i_beq  = ~op[5] & ~op[4] & ~op[3] &  op[2] & ~op[1] & ~op[0]; //000100
   wire i_bne  = ~op[5] & ~op[4] & ~op[3] &  op[2] & ~op[1] &  op[0]; //000101
   wire i_lui  = ~op[5] & ~op[4] &  op[3] &  op[2] &  op[1] &  op[0]; //001111
   wire i_j    = ~op[5] & ~op[4] & ~op[3] & ~op[2] &  op[1] & ~op[0]; //000010
   wire i_jal  = ~op[5] & ~op[4] & ~op[3] & ~op[2] &  op[1] &  op[0]; //000011
   
   wire i_rs  = i_add | i_sub | i_and | i_or | i_xor | i_jr | i_addi | i_andi |
				i_ori | i_xori | i_lw | i_sw | i_beq | i_bne;
   wire i_rt  = i_add | i_sub | i_and | i_or | i_xor | i_sll | i_srl | i_sra | 
				i_sw | i_beq | i_bne;
	  
   assign pcsource[1] = i_jr | i_j | i_jal;
   assign pcsource[0] = ( i_beq & rsrtequ ) | (i_bne & ~rsrtequ) | i_j | i_jal ;
	   
   assign daluc[3] = i_sra ;
   assign daluc[2] = i_sub | i_or  | i_srl | i_sra | i_ori ;
   assign daluc[1] = i_xor | i_sll | i_srl | i_sra | i_xori;
   assign daluc[0] = i_and | i_or  | i_sll | i_srl | i_sra | i_andi | i_ori ;
	   

   assign dshift   = i_sll | i_srl | i_sra ;
// shift 1 Ñ¡ÔñÒÆÎ»Î»Êý£»0 Ñ¡Ôñ¼Ä´æÆ÷µÄÊý¾Ý   

   assign daluimm  = i_addi | i_andi | i_ori | i_xori |i_lw | i_sw | i_lui ;
// aluimm 1 Ñ¡ÔñÀ©Õ¹ºóµÄÁ¢¼´Êý£ Ñ¡Ôñ´æÆ÷ÖÐµÄÊý¾?      

   assign sext    = i_addi | i_lw | i_sw | i_beq | i_bne ;
// beqÓëbneµÄÁ¢¼´ÊýÒÑ²»¾­¹ýÕâ¸ömux
// sext 1 ·ûºÅÀ©Õ¹£»0 0À©Õ¹
//   assign wmem    = i_sw ;

// m2reg 1 Ñ¡Ôñ´æ´¢Æ÷ÖÐ¶Á³öµÄÊý¾Ý£»0 ALUÖÐµÄÔËËã½á¹û
// regrt 1 Ñ¡Ôñrt£»0 Ñ¡Ôñrd
// jal 1 PC+8£»0 ALU»ò´æ´¢Æ÷ÖÐµÄÊý¾Ý
   assign dm2reg   = i_lw ;
   assign regrt   = i_addi |i_andi | i_ori | i_xori |i_lw | i_lui ;
   assign djal     = i_jal;

//   assign wpcir = ~1;               // 

   assign wpcir =  ~ ( ewreg & em2reg & (ern != 0) & (i_rs & (ern == rs) | i_rt & (ern == rt)));
   assign dwreg  = (i_add | i_sub | i_and | i_or | i_xor | i_sll | 
				    i_srl | i_sra | i_addi | i_andi |
					i_ori | i_xori | i_lw | i_lui | i_jal) & wpcir; // prevent from executing twice
   assign dwmem  = i_sw & wpcir; // prevent from executing twice

   always @ ( negedge clock )   // clock ?? wg
	
	  begin 
		 fwda = 2'b00; // default forward a: no hazards
		 if (ewreg & (ern != 0) & (ern == rs) & ~em2reg) 
			begin
			   fwda = 2'b01; // select exe_alu
			end
		 else
			begin
			   if (mwreg & (mrn != 0) & (mrn == rs) & ~mm2reg)
				  begin
				     fwda = 2'b10; // select mem_alu
				  end
			   else
	     		  begin
	     		     if (mwreg & (mrn != 0) & (mrn == rs) & mm2reg)
						begin
						   fwda = 2'b11; // select mem_lw
						end
   				  end
			end
         fwdb = 2'b00; // default forward b: no hazards
		 if (ewreg & (ern != 0) & (ern == rt) & ~em2reg)
			begin
			   fwdb = 2'b01; // select exe_alu
			end
		 else
			begin
			   if (mwreg & (mrn != 0) & (mrn == rt) & ~mm2reg)
				  begin
				     fwdb = 2'b10; // select mem_alu
				  end
			   else
				  begin
			         if (mwreg & (mrn != 0) & (mrn == rt) & mm2reg)
						begin
						   fwdb = 2'b11; // select mem_lw
						end
				  end
			end
      end






// --------------  always end

endmodule

