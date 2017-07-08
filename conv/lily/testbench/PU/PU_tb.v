


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





















reg                                                pu_data_in_v;



































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

integer conv_ic, conv_oc;

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
	
	for (ii=0; ii<max_layers; ii=ii+1)
	begin
		{_stride, _pool_iw, _pool_oh, _pool_kernel, _pool, l_type, _max_threads, _pad, _pad_row_start, _pad_row_end, _skip, _endrow_iw, 
		_ic, _ih, _iw, _oc, _kh, _kw} = u_controller.cfg_rom[ii];
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
			if(l_type == 0) 
			begin     //convol
				driver.initialize_input(input_width, _ih+1, 1, 1);
				driver.initialize_weight(_kh+1, _kh+1, _ic+1, _oc+1);
				driver.expected_output(input_width, _ih+1, _ic+1, 1, _kw+1, _kh+1, _stride, _oc+1, _pad, _pad_row_start, _pad_row_end);  // , , ,batchsize
			end
			else if (l_type == 2)        // normalization
			begin
			    driver.initialize_input(input_width, _ih+1, 1, 1);
			    dirver.initialize_weight(0,0,0,0);
			    driver.expected_output_norm(input_width,_ih+1, _ic+1, 1, _kw+1, _kh+1, _stride, _oc+1, _pad, _pad_row_start, _pad_row_end); 
			end
			else begin    //full-connect
			    driver.initialize_input_fc(_ic+1);
			    driver.initialize_weight_fc( _ic+1, (_oc+1)*NUM_PE );
			    driver.expected_output_fc(_ic+1, (_oc+1)*NUM_PE, _max_threads);
			end
			
			if(_pool)
			begin
			    driver.expected_pooling_output(_pool_kernel, _pool_kernel, 2);   //stride
			 
			end
			else
			    driver.pool_enabled = 1'b0;
			if (l_type == 0)     
			begin
			    for (conv_oc = 0; conv_oc < _oc; conv_oc = conv_oc + 1)
			    begin
			        for (conv_ic = 0; conv_ic < _ic; conv_ic = conv_ic + 1)
			        begin
			            $display("OC (%d/%d) : IC (%d/%d)", conv_oc, _oc, conv_ic, _ic);
			            driver.initialize_input(input_width, _ih+1, 1, 1);
			            driver.initilaize_weight(_kh+1, _kh+1, _ic+1, _oc+1);
			            $display("Conv Started");
			            wait (u_controller.state == 4);   //BUSY
			            wait (u_controller.state != 4);
			            repeat(1000) @(negedge clk);
			            $display ("Conv finished");
			        end
			        
			        repeat(100) @(negedge clk);
			        driver.write_count = 0;
			        
			    end
			end
			else
			    wait (driver.write_count/NUM_PE == driver.expected_writes);
			repeat (100) begin
			    @(negedge clk);
			end
	end
	wait (u_controller.state != 4);
	
	repeat (1000) @(negedge clk);
    driver.status.test_pass;
end

initial
begin
    $dumpfile("PU_tb.vcd");
    $dumpvars(0,PU_tb);
end

// ****************************************************
// PU
// ****************************************************
always @(posedge clk)
    pu_data_in_v <= pu_rd_req;
assign read_req = vecgen_rd_req;
PU #(
) u_PU (
);

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
