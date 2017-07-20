

`include "common.vh"
`include "params.vh"
module PU_tb;



localparam integer NUM_PE              = `num_pe;
localparam integer OP_WIDTH            = 16;

localparam integer TID_WIDTH           = 16;
localparam integer PAD_WIDTH           = 3;
localparam integer STRIDE_SIZE_W       = 3;
localparam integer LAYER_PARAM_WIDTH   = 10;
localparam integer L_TYPE_WIDTH        = 2;

localparam integer PE_CTRL_WIDTH       = 10 + 2*PE_BUF_ADDR_WIDTH;


localparam integer WR_ADDR_WIDTH       = 7;
localparam integer RD_ADDR_WIDTH       = WR_ADDR_WIDTH + `C_LOG_2(NUM_PE);




localparam integer POOL_CTRL_WIDTH     = 7;
localparam integer POOL_CFG_WIDTH      = 3;
localparam integer SERDES_COUNT_W      = 6;

localparam integer PE_SEL_W            = `C_LOG_2(NUM_PE);




wire                                            pe_neuron_bias;
wire [ PE_SEL_W            - 1 : 0 ]            pe_neuron_sel;
wire                                            pe_neuron_read_req;

wire [ DATA_WIDTH          - 1 : 0 ]            pu_data_out;
wire [ DATA_WIDTH          - 1 : 0 ]            pu_data_in;
reg                                             pu_data_in_v;
reg                                             start;
wire [ SERDES_COUNT_W      - 1 : 0 ]            pu_serdes_count;
wire [ PE_CTRL_WIDTH       - 1 : 0 ]            pe_ctrl;
wire [ RD_ADDR_WIDTH       - 1 : 0 ]            wb_read_addr;
wire                                            read_req;


wire                                            vecgen_rd_req;



wire                                            vecgen_ready;
wire [ DATA_IN_WIDTH       - 1 : 0 ]            vecgen_wr_data;

wire [ NUM_PE              - 1 : 0 ]            vecgen_mask;

// PU Source and Destination Select
wire [ `SRC_0_SEL_WIDTH    - 1 : 0 ]            src_0_sel;
wire [ `SRC_1_SEL_WIDTH    - 1 : 0 ]            src_1_sel;
wire [ `SRC_2_SEL_WIDTH    - 1 : 0 ]            src_2_sel;
wire [ `OUT_SEL_WIDTH      - 1 : 0 ]            out_sel;
wire [ `DST_SEL_WIDTH      - 1 : 0 ]            dst_sel;


wire [ POOL_CTRL_WIDTH     - 1 : 0 ]            pool_ctrl;
wire [ POOL_CFG_WIDTH      - 1 : 0 ]            pool_cfg;





wire buffer_read_empty;

wire [63:0] buffer_read_data_out;

PU_tb_driver #(
    .OP_WIDTH                  ( OP_WIDTH                        ),
    .NUM_PE                    ( NUM_PE                          )
) driver (
    .clk                       ( clk                             ),   //output
    .reset                     ( reset                           ),   //output
    .buffer_read_data_valid    ( buffer_read_data_valid          ),   //output
    .buffer_read_data_out      ( buffer_read_data_out            ),   //output 
    .buffer_read_empty         ( buffer_read_empty               ),   //output
    .buffer_read_req           ( buffer_read_req                 ),   //input
    .buffer_read_last          ( buffer_read_last                ),   //output
    .pu_rd_req                 ( read_req                        ),   //input
    .pu_rd_ready               ( pu_rd_ready                     ),   //output
    .pu_wr_req                 ( outBuf_push                     ),   //input
    .pu_data_out               ( pu_data_out                     ),   //input
    .pu_data_in                ( pu_data_in                      ),   //output
    .pass                      ( pass                            ),
    .fail                      ( fail                            )
);


reg [ LAYER_PARAM_WITDH   - 1 : 0 ]         _kw, _kh, _ks;
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
	wait(u_controller.state != 0);          //!=IDLE
	start = 0;            //Cleared after triggering

	max_layers = u_controller.max_layers;//+1;      
	$display;
	$display("****************************************");
	$display("Number of layers = %d", max_layers);
	$display("****************************************");
	$display;
	
	for (ii=0; ii<max_layers; ii=ii+1)   //11
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

    .OP_WIDTH        ( OP_WIDTH          ),
    .NUM_PE          ( NUM_PE            )
) u_PU (

    .clk                        ( clk                     ),
    .reset                      ( reset                   ),
    .buffer_read_data_valid     ( buffer_read_data_valid  ),     //input
    .read_data                  ( buffer_read_data_out    ),     //input, 4 data
    .pe_ctrl                    ( pe_ctrl                 ),     //input
    .lrn_enable                 ( lrn_enable              ),     //input
    .pu_serdes_count            ( pu_serdes_count         ),     //input
    .pe_neuron_sel              ( pe_neuron_sel           ),     //input
    .pe_neuron_bias             ( pe_neuron_bias          ),     //input
    .pe_neuron_read_req         ( pe_neuron_read_req      ),     //input
    .vecgen_mask                ( vecgen_mask             ),     //input
    .vecgen_wr_data             ( vecgen_wr_data          ),     //input
    .wb_read_addr               ( wb_read_addr            ),     //input
    .wb_read_req                ( wb_read_req             ),     //input
    .bias_read_req              ( bias_read_req           ),     //input
    .src_0_sel                  ( src_0_sel               ),     //input
    .src_1_sel                  ( src_1_sel               ),     //input
    .src_2_sel                  ( src_2_sel               ),     //input
    .out_sel                    ( out_sel                 ),     //input
    .dst_sel                    ( dst_sel                 ),     //input
    .pool_cfg                   ( pool_cfg                ),     //input
    .pool_ctrl                  ( pool_ctrl               ),    //input
    .read_id                    ( 10'b0                   ),    //input
    .read_d_type                ( 2'b0                    ),    //input
    .read_req                   ( pu_rd_req               ),    //output
    .write_data                 ( pu_data_out             ),    //output
    .write_req                  ( outBuf_push             ),    //output
    .write_ready                ( 1'b1                    )     //input 
);






assign vecgen_rd_data = pu_data_in;
wire vecgen_rd_data_v;
assign vecgen_rd_data_v = pu_data_in_v;
assign vecgen_rd_ready = pu_rd_ready;


vectorgen #(



) vecgen (
    .clk                  ( clk                       ),
    .reset                ( reset                     ),  
    .ready                ( vecgen_ready              ),
    
    
    
    .read_ready           ( vecgen_rd_ready           ), //input
    .read_req             ( vecgen_rd_req             ),
    .write_data           ( vecgen_wr_data            )
    
);










PU_controller 
#(

    .PE_CTRL_W             ( PE_CTRL_WIDTH            ),


    .TID_WIDTH             ( TID_WIDTH                ),
    .PAD_WIDTH             ( PAD_WIDTH                ),
    .LAYER_PARAM_WIDTH     ( LAYER_PARAM_WIDTH        ), .PARAM_C_WIDTH (LAYER_PARAM_WIDTH)
) u_controller (
	.clk                   ( clk                      ),
	.reset                 ( reset                    ),
	.start                 ( start                    ), //input
	.lrn_enable            ( lrn_enable               ), //output
	.pu_serdes_count       ( pu_serdes_count          ), //output
	.pe_neuron_sel         ( pe_neuron_sel            ), //output
	.pe_neuron_bias        ( pe_neuron_bias           ), //output
	.pe_neuron_read_req    ( pe_neuron_read_req       ), //output
	.pe_ctrl               ( pe_ctrl                  ), //output
	.buffer_read_empty     ( buffer_read_empty        ),
	.buffer_read_req       ( buffer_read_req          ), //output
	.buffer_read_last      ( buffer_read_last         ), //input
	
	
	.vectorgen_ready       ( vecgen_ready             ), //input
	
	
	
	.wb_read_req           ( wb_read_req              ),     //output
	.wb_read_addr          ( wb_read_addr             ),     //output
	.pe_write_mask         ( vecgen_mask              ),     //output
	.pool_cfg              ( pool_cfg                 ),     //output
	.pool_ctrl             ( pool_ctrl                ),    //output
	.src_0_sel             ( src_0_sel                ),    //output
	.src_1_sel             ( src_1_sel                ),    //output
	.src_2_sel             ( src_2_sel                ),    //output
	.bias_read_req         ( bias_read_req            ),     //output
	.out_sel               ( out_sel                  ),      //output
	.dst_sel               ( dst_sel                  )       //output
);

endmodule
