`include "params.vh"

module PU_tb;

localparam integer NUM_PE              = `num_pe;
localparam integer OP_WIDTH            = 16;

localparam integer TID_WIDTH           = 16;
localparam integer PAD_WIDTH           = 3;
localparam integer STRIDE_SIZE_W       = 3;
localparam integer LAYER_PARAM_WIDTH   = 10;
localparam integer L_TYPE_WIDTH        = 2;

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

reg [ LAYER_PARAM_WITDH   - 1 : 0 ]         _kw, _kh;
reg [ LAYER_PARAM_WITDH   - 1 : 0 ]         _iw, _ih, _ic, _oc;
reg [ LAYER_PARAM_WIDTH   - 1 : 0 ]         _endrow_iw;
reg                                         _skip;

reg [ PAD_WIDTH           - 1 : 0 ]         _pad;
reg [ PAD_WIDTH           - 1 : 0 ]         _pad_row_start;
reg [ PAD_WIDTH           - 1 : 0 ]         _pad_row_end;
reg [ STRIDE_SIZE_W       - 1 : 0 ]         _stride;

reg [ TID_WIDTH           - 1 : 0 ]         _max_threads;
reg [ L_TYPE_WIDTH        - 1 : 0 ]         l_type;
reg                                         _pool;
reg [ 1                       : 0 ]         _pool_kernel;
reg [ LAYER_PARAM_WIDTH   - 1 : 0 ]         _pool_oh;
reg [ LAYER_PARAM_WIDTH   - 1 : 0 ]         _pool_iw;
reg [ LAYER_PARAM_WIDTH   - 1 : 0 ]         input_width;

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
		{_stride, _pool_iw, _pool_oh, _pool_kernel, _pool, l_type, _max_threads, 
		_pad, _pad_row_start, _pad_row_end, _skip, _endrow_iw, _ic, _ih, _iw,
		_oc, _kh, _kw} = u_controller.cfg_rom[ii];
		$display("***************************************");
		$display("Layer configuration: ");
		$display("***************************************");
		case(l_type)
			0: $display("Type : Convolution");
			1: $display("Type : InnerProduct");
			2: $display("Type : Normalization");
		endcase
		if(_pool == 1) $display("Pooling\t: Enabled");
		else           $display("Pooling\t: Disabled");

		input_width = _max_threads + _kh - 2 * _pad;

		$display("Input  FM : %4d x %4d x %4d", input_width, _ih+1, _ic+1);
		$display("Output FM :             %4d", _oc+1);
		$display("Kernel    : %4d x %4d", _kh+1, _kw+1);
		$display("Padding   : %4d", _pad);
		$display("Stride    : %4d", _stride);
		$display("****************************************");
		wait (u_controller.state == 1);        //wait
		@(negedge clk)
			if(l_type == 0) begin     //convol
				driver.initialize_input(input_width, _ih+1, 1, 1);
				driver.initialize_weight(_kh+1, _kh+1, _ic+1, _oc+1);
			end
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
