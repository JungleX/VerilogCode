module PU_tb_driver #(
	parameter integer OP_WIDTH    = 16
)(
);

reg signed [OP_WIDTH-1:0] norm_lut [0:1<<6];

initial
$readmemb ("hardware/include/norm_lut.vh", norm_lut);

integer output_fm_dimensions [3:0];
reg pool_enabled;

test_status #(
	.PREFIX        ( "PU"      ),
	.TIMEOUT       ( 1000000   )
) status (
	.clk           ( clk       ),
	.reset         ( reset     ),
	.pass          ( pass      ),
	.fail          ( fail      )
);

clk_rst_driver clkgen(
	.clk       ( clk       ),
	.reset_n   (           ),
	.reset     ( reset     )
);

task expected_pooling_output;
	integer iw, ih, ic;
	begin
		pool_enabled = 1'b1;
		$display ("PE output dimension\t=%d x %d x %d",
			output_fm_dimensions[0],
			output_fm_dimensions[1],
			output_fm_dimensions[2]);
		iw = output_fm_dimensions[0];
		ih = output_fm_dimensions[1];
		ic = output_fm_dimensions[2];
	end
endtask

endmodule
