module ram #(
    parameter integer ADDR_WIDTH  = 12
)
(
    input wire                         clk,
    input wire                         reset,
    
    input wire                         s_read_req,
    
    input wire                         s_write_req,
    input wire [ ADDR_WIDTH - 1 : 0 ]  s_write_addr
);

reg [ADDR_WIDTH-1:0] wr_addr;

reg rd_addr_v;

always @(posedge clk)
    if (reset)
        rd_addr_v <= 1'b0;
    else 
        rd_addr_v <= s_read_req;
        
always @(posedge clk)
begin
    if (reset)
        wr_addr <= 0;
    else if (s_write_req)
        wr_addr <= s_write_addr;
end

endmodule
