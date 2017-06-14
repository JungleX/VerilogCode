 module RamBlock(input clka, input ena, input wea, input dina, input clkb, input enb, input addrb, output doutb, output ready, output complete);
wire clka;
wire ena;
wire wea;
reg [15:0] addra;
wire [15:0] dina; 
wire clkb;
wire enb;
wire [15 : 0] addrb;
wire [15:0] doutb;
reg complete = 0;
reg ready = 0;

reg [15:0] load_size = 16'd0;

blk_mem_16 inram0 (
  .clka(clka),    // input wire clka
  .ena(ena),      // input wire ena
  .wea(wea),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [15 : 0] addra
  .dina(dina),    // input wire [15 : 0] dina
  .clkb(clkb),    // input wire clkb
  .enb(enb),      // input wire enb
  .addrb(addrb),  // input wire [15 : 0] addrb
  .doutb(doutb)  // output wire [15 : 0] doutb
);

always @(posedge clka)
begin
    if(ena) begin
        if(ready == 1) begin
            if(load_size < 36864)   //36K
            begin
                addra = load_size;
                load_size = load_size+1;
            end
            else
                complete = 1;
            end
        else
            ready = 1;
    end
end

endmodule