module pipeexe ( ealuc,ealuimm,ea,eb,eimm,eshift,ern0,epc4,ejal,
                 ern,ealu);

	input   [3:0]  ealuc;
	input          ealuimm,eshift,ejal;
	input  [31:0]  ea,eb,eimm,epc4 ;       //esa
	input   [4:0]  ern0;

	output  [4:0]  ern;
	output [31:0]  ealu;

	wire   [31:0]  epc8,alu_ina,alu_inb,aluout;
	wire   [31:0]  sa;
	wire           zero;
	wire           eshift;
	

	assign  epc8 = epc4 + 8'h4;
	
	assign  sa[31:0] = { 27'b0,eimm[10:6] }; // extend sa to 32 bits for sll/srl/sra;
	
	// wire [31:0]   dsa = { 27'b0, inst[10:6] }; // extend to 32 bits from sa for shift instruction
	
    assign  ern[4:0] = ern0 | {5{ejal}}; // jal: r31 <-- p4;  // 31 or ern0/ reg_dest - mc
//  muxff ernf (ern0,ejal,ern);  // zr


    mux2x32 mux_shift  (ea,sa,eshift,alu_ina);

    mux2x32 mux_aluimm (eb,eimm,ealuimm,alu_inb);

    alu al_unit (alu_ina,alu_inb,ealuc,aluout,zero );

    mux2x32 mux_jal (aluout,epc8,ejal,ealu);
    
endmodule
