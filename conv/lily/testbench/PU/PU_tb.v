`include "params.vh"

module PU_tb;

localparam integer NUM_PE              = `num_pe;
localparam integer OP_WIDTH            = 16;

reg                                              start;
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

integer ii;

initial begin
	driver.status.start;
	start = 0;

	@(negedge clk);

	start = 1;
	wait(u_controller.state != 0);          //pu_controller ready
	start = 0;            //Cleared after triggering

	max_layers = u_controller.max_layers+1;      //+1?
	$display;
	$display("****************************************");
	$display("Number of layers = %d", max_layers);
	$display("****************************************");
	$display;
	
	for (ii=0; ii<max_layers; ii++)
	begin
	end

end

assign read_req = vecgen_rd_req;

vectorgen #(
) vecgen (
    .clk                  ( clk                       ),
    .reset                ( reset                     ),  
    .read_req             ( vecgen_rd_req             )
);

PU_controller #(
) u_controller (
	.clk               ( clk                      ),
	.reset             ( reset                    ),
	.start             ( start                    )  
);

endmodule
