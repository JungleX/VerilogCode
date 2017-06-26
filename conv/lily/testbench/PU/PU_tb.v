`include "params.vh"

module PU_tb;

localparam integer NUM_PE              = `num_pe;
localparam integer OP_WIDTH            = 16;

wire                                             read_req;
wire                                             vecgen_rd_req;

PU_tb_driver #(
    .OP_WIDTH                  ( OP_WIDTH                        ),
    .NUM_PE                    ( NUM_PE                          )
) driver (
    .clk                       ( clk                             ),
    .reset                     ( reset                           ),
    .pu_rd_req                 ( read_req                        ),
    .pu_rd_ready               ( pu_rd_ready                     ),
    .pass                      ( pass                            ),
    .fail                      ( fail                            )
);

assign read_req = vecgen_rd_req;

vectorgen #(
) vecgen (
    .clk                  ( clk                       ),
    .reset                ( reset                     ),  
    .read_req             ( vecgen_rd_req             )
);

endmodule
