`include "params.vh"


module PU_controller 
#(
    
    
    parameter integer NUM_PE                    = 4,
    
    
    
    
    parameter integer LAYER_PARAM_WIDTH          = 10,
    parameter integer PARAM_C_WIDTH              = 16,
    parameter integer MAX_LAYERS                 = 64,
    
    parameter integer TID_WIDTH                  = 8,
    parameter integer PAD_WIDTH                  = 3,
    parameter integer STRIDE_SIZE_W              = 3,
    
    
    
    
    parameter integer SERDES_COUNT_W             = 6

)
(

    input wire                                 clk,
    input wire                                 reset,
    input wire                                 start,
    
    output wire [ L_TYPE_WIDTH    -1 : 0 ]     l_type,
    
    
    
    
    
    
    output wire                                buffer_read_req,
    input wire                                 buffer_read_last,
    input wire                                 vectorgen_ready,
    
    
    
    
    
    
    
    
    
    
    
    
    output reg [ 3               - 1 : 0 ]     state,






    output wire                                bias_read_req                    








);



//FSM states
localparam IDLE         = 0,
           WAIT         = 1,
	   RD_CFG_1         = 2,
	   RD_CFG_2         = 3,   
           BUSY         = 4;

















wire [ LAYER_PARAM_WIDTH     - 1 : 0 ]         pool_ih_count;  
wire                                           pool_ih_inc;
wire                                           pool_ih_stall;
wire [ LAYER_PARAM_WIDTH     - 1 : 0 ]         pool_ih_default;
wire [ LAYER_PARAM_WIDTH     - 1 : 0 ]         pool_ih_min;
reg  [ LAYER_PARAM_WIDTH     - 1 : 0 ]         pool_ih_max;

wire [ LAYER_PARAM_WIDTH     - 1 : 0 ]         pool_iw_count;
wire                                           pool_iw_inc;
wire                                           next_pool_ih;
wire [ LAYER_PARAM_WIDTH     - 1 : 0 ]         pool_iw_default;

reg  [ LAYER_PARAM_WIDTH     - 1 : 0 ]         pool_iw_max;


wire                                           stride_inc;
wire                                           next_pool_iw;
wire [ LAYER_PARAM_WIDTH     - 1 : 0 ]         stride_default;










wire                                            pool_in_pop;
wire                                            _pool_in_pop;



















wire                                            kh_max_dec;




















wire [ LAYER_PARAM_WIDTH  - 1 : 0 ]       ih, ih_max, ih_max_pad;



wire                                      ic_inc, ic_inc_d;






wire [ LAYER_PARAM_WIDTH  - 1 : 0 ]        l,l_max;
wire                                       l_inc, l_inc_d, l_clear;

wire                                       next_fm;














wire                                      skip;


wire                                      vecgen_ready;

wire [ TID_WIDTH         - 1 : 0 ]        max_threads;



wire [ LAYER_PARAM_WIDTH - 1 : 0 ]        endrow_iw;





reg [ 3                   - 1 : 0 ]        next_state;
reg [ CFG_WIDTH           - 1 : 0 ]        cfg_rom[0:CFG_DEPTH-1];        //control flow graph
reg [ CFG_WIDTH           - 1 : 0 ]        layer_params;

wire [ SERDES_COUNT_W     - 1 : 0 ]        serdes_count;











wire                                       param_pool_enable;
reg                                        pool_enable;


reg [ LAYER_PARAM_WIDTH   - 1 : 0 ]        max_layers;























reg [ TID_WIDTH               -1 : 0 ]         tid [0:NUM_PE-1];
reg [ NUM_PE                  -1 : 0 ]         mask;




wire                                           pool_ready;
















wire [ 256                - 1 : 0 ]        GND;




localparam CFG_DEPTH = MAX_LAYERS;
localparam L_TYPE_WIDTH = 2;
localparam CFG_WIDTH = 
    //SERDES_COUNT_W +
    2*PARAM_C_WIDTH +
    7*LAYER_PARAM_WIDTH +
    TID_WIDTH +
    3*PAD_WIDTH +
    L_TYPE_WIDTH +
    2 + 2 +
    STRIDE_SIZE_W;


localparam L_IP = 1;


assign GND = 256'd0;

initial begin
    max_layers = `max_layers;
	`ifdef simulation
		$readmemb("./hardware/include/pu_controller_bin.vh", cfg_rom);
	`else
		$readmemb("pu_controller_bin.vh", cfg_rom);           //cnn 数据流图文件,124
	`endif
end

always @(posedge clk)
begin
	if (state != RD_CFG_1)
		layer_params <= cfg_rom[0];//cfg_rom[1];
end

wire [STRIDE_SIZE_W-1:0]      param_conv_stirde;
reg [STRIDE_SIZE_W-1:0]       param_conv_stride_d;
always @(posedge clk)
    if (reset)
        param_conv_stride_d <= 1;
    else
        param_conv_stride_d <= param_conv_stride;

assign {
    //serdes_count,
    param_conv_stride,
    param_pool_iw,
    param_oh,
    pool_kernel,
    param_pool_enable,
    l_type,
    max_threads,
    pad_w,
    pad_r_s,
    pad_r_e,
    skip,
    endrow_iw,
    param_ic,
    param_ih,
    param_iw,
    param_oc,
    param_kh,
    param_kw} = layer_params;

always @(posedge clk)
    if (reset)
        pool_enable <= 1'b0;
    else if (pool_ih_count == 0)
        pool_enable <= param_pool_enable;

assign kh_default = param_kh;


assign kh_max_dec = (ih > (ih_max - param_kh + pad_r_e - param_conv_stride ) &&
    iw_inc_d && (iw == iw_min) && kh_max != (param_conv_stride-1)) && (conv_stride_count == conv_stride_max);



































reg [6:0] wait_timer;
wire [6:0] max_wait_time = 8;
wire wait_complete = wait_timer == max_wait_time;


always @(posedge clk)
    if (reset || state != WAIT)
        wait_timer <= 0;
    else if (!wait_complete)
        wait_timer <= wait_timer + 1'b1;

assign buffer_read_req = wait_complete && state == WAIT && !(buffer_read_last_sticky);

reg buffer_read_last_sticky;

always @(posedge clk)
begin
    if (reset)
        buffer_read_last_sticky <= 1'b0;
    else begin
        if (buffer_read_last)
            buffer_read_last_sticky <= 1'b1;
        else if (state == RD_CFG_1)
            buffer_read_last_sticky <= 1'b0;
    end
end

wire buffer_read_done = buffer_read_last || buffer_read_last_sticky || l_type == 2;



assign vecgen_ready = vectorgen_ready;

always @*
begin: FSM        //finit state machine
    next_state = state;
    case (state)
        IDLE: begin
            if (start)
                next_state = WAIT;
        end
	WAIT: begin
		if (vecgen_ready && wait_complete && buffer_read_done)
		  next_state = RD_CFG_1;
	end
    endcase
end













always @(posedge clk)
begin
    if(reset)
        state <= IDLE;
    else
        state <= next_state;
end



























































































































































































































counter #(
    .COUNT_WIDTH           ( LAYER_PARAM_WIDTH       )
) 
ih_counter(
    .CLK                   ( clk                     ),
    .RESET                 ( reset                   ),
    .CLEAR                 ( 1'b0                    ),
    .DEFAULT               ( ih_max                  ),
    .INC                   ( ih_inc                  ),
    .DEC                   ( 1'b0                    ),
    .MIN_COUNT             ( ih_min                  ),
    .MAX_COUNT             ( ih_max_pad              ),
    .OVERFLOW              ( next_ic                 ),       //output
    .UNDERFLOW             (                         ),
    .COUNT                 ( ih                      )        //output
);



























// =============================================================
// Output FM channels
// =============================================================
counter #(
) oc_counter (
    .INC                 ( oc_inc                 ),
    .OVERFLOW            ( next_l                 )
);
















// =============================================================
// layer count
// ==============================================================
assign l_inc = next_l && oc_inc && state == BUSY;
assign l_max = max_layers;
assign l_clear = state == IDLE;
wire [LAYER_PARAM_WIDTH-1:0] l_min, l_default;
assign l_default = GND[LAYER_PARAM_WIDTH-1:0];
assign l_min = GND[LAYER_PARAM_WIDTH-1:0];
counter #(
    .COUNT_WIDTH           ( LAYER_PARAM_WIDTH       )
) 
l_counter(
    .CLK                   ( clk                     ),
    .RESET                 ( reset                   ),
    .CLEAR                 ( l_clear                 ),
    .DEFAULT               ( l_default               ),
    .INC                   ( l_inc                   ),
    .DEC                   ( 1'b0                    ),
    .MIN_COUNT             ( l_min                   ),
    .MAX_COUNT             ( l_max                   ),
    .OVERFLOW              ( next_fm                 ),       //output
    .UNDERFLOW             (                         ),
    .COUNT                 ( l                       )        //output
);

assign done = next_fm && l_inc;






























































reg ic_is_zero;




































/*always @(posedge clk)
	if (reset)
		ic_is_zero <= 0;
	else if (state == RD_CFG_2)
		ic_is_zero <= (param_ic == 0);
	else if (ic_inc || state_d == RD_CFG_2)
		ic_is_zero <= (ic_is_max) || (param_ic == 0);
*/






















assign vectorgen_start       = start || ((l_inc_d || ic_inc_d && l_type != L_IP) && state != IDLE);


























































































































































































































































































































































































































































































































































































































































assign bias_read_req = (ic_is_zero && state == RD_CFG_2);











































genvar gen;
generate
for (gen = 0; gen < NUM_PE; gen = gen+1)
begin: THREAD_LOGIC









    always @(posedge clk)
    begin

        mask[gen] <= tid[gen] < max_threads;
    end

end
endgenerate















































reg stride_state, next_stride_state;
always @(posedge clk)
    if (reset)
        stride_state <= 1'b0;
    else 
        stride_state <= next_stride_state;
always @(*)
begin
    next_stride_state = stride_state;
    case (stride_state)
        0: if (pool_in_pop)
            next_stride_state = 1;
        1: if (pool_iw_inc)
            next_stride_state = 0;
    endcase
end

assign stride_inc = pool_enable && (stride_state ? (pool_ready || pool_iw_count == pool_iw_max ) : pool_in_pop);


assign stride_default = GND[LAYER_PARAM_WIDTH-1:0];

counter #(
    .COUNT_WIDTH            ( LAYER_PARAM_WIDTH      )
)
stride_counter (
    .CLK                    ( clk                    ),
    .RESET                  ( reset                  ),
    .CLEAR                  ( 1'b0                   ),
    .DEFAULT                ( stride_default         ),
    .INC                    ( stride_inc             ),
    


    .OVERFLOW               ( next_pool_iw           )  //output


);




assign pool_iw_inc = next_pool_iw && stride_inc;


always @(posedge clk)
    if (reset)
        pool_iw_max <= 0;
    else if (pool_ih_count == 0)
        pool_iw_max <= param_pool_iw;






assign pool_iw_default = GND[LAYER_PARAM_WIDTH-1:0];

counter #(
    .COUNT_WIDTH            ( LAYER_PARAM_WIDTH      )
)
pool_iw_counter (
    .CLK                    ( clk                    ),
    .RESET                  ( reset                  ),
    .CLEAR                  ( 1'b0                   ),
    .DEFAULT                ( pool_iw_default        ),
    .INC                    ( pool_iw_inc            ),
    


    .OVERFLOW               ( next_pool_ih           ),  //output

    .COUNT                  ( pool_iw_count          )   //output
);

assign pool_ih_inc = next_pool_ih && pool_iw_inc;
assign pool_ih_min = 0;
assign pool_ih_default = 0;

always @(posedge clk)
begin
    if (reset) pool_ih_max <= 0;
    else if (pool_ih_count == 0) pool_ih_max <= param_oh;   //???
end

counter #(
    .COUNT_WIDTH            ( LAYER_PARAM_WIDTH      )
)
pool_ih_counter (
    .CLK                    ( clk                    ),
    .RESET                  ( reset                  ),
    .CLEAR                  ( 1'b0                   ),
    .DEFAULT                ( pool_ih_default        ),
    .INC                    ( pool_ih_inc            ),
    .DEC                    ( 1'b0                   ),
    .MIN_COUNT              ( pool_ih_min            ),
    .MAX_COUNT              ( pool_ih_max            ),
    .OVERFLOW               ( pool_ih_stall          ),  //output
    .UNDERFLOW              (                        ),
    .COUNT                  ( pool_ih_count          )   //output
);

endmodule
