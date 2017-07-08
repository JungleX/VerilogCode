`include "params.vh"

module PU_controller #(
    parameter integer LAYER_PARAM_WIDTH          = 10,
    parameter integer PARAM_C_WIDTH              = 16,
    parameter integer TID_WIDTH                  = 8,
    parameter integer PAD_WIDTH                  = 3,
    parameter integer STRIDE_SIZE_W              = 3,
    parameter integer MAX_LAYERS                 = 64,
    parameter integer SERDES_COUNT_W             = 6
)(
    input wire                                 clk,
    input wire                                 reset,
    input wire                                 start,
    
    output reg [ 3               - 1 : 0 ]     state
);

//FSM states
localparam IDLE         = 0,
           WAIT         = 1,
	       RD_CFG_1     = 2,
           BUSY         = 4;

wire [ LAYER_PARAM_WIDTH  - 1 : 0 ]        l,l_max;
wire                                       l_inc, l_inc_d, l_clear;

wire                                       next_fm;

reg [ 3                   - 1 : 0 ]        next_state;
reg [ CFG_WIDTH           - 1 : 0 ]        cfg_rom[0:CFG_DEPTH-1];        //control flow graph
reg [ CFG_WIDTH           - 1 : 0 ]        layer_params;

reg [ LAYER_PARAM_WIDTH   - 1 : 0 ]        max_layers;

wire [ 256                - 1 : 0 ]        GND;

localparam CFG_DEPTH = MAX_LAYERS;
localparam L_TYPE_WIDTH = 2;
localparam CFG_WIDTH = 
    SERDES_COUNT_W +
    2*PARAM_C_WIDTH +
    7*LAYER_PARAM_WIDTH +
    TID_WIDTH +
    3*PAD_WIDTH +
    L_TYPE_WIDTH +
    2 + 2 +
    STRIDE_SIZE_W;

assign GND = 256'd0;

initial begin
    max_layers = `max_layers;
	`ifdef simulation
		$readmemb("./hardware/include/pu_controller_bin.vh", cfg_rom);
	`else
		$readmemb("pu_controller_bin.vh", cfg_rom);
	`endif
end

always @(posedge clk)
begin
	if (state != RD_CFG_1)
		layer_params <= cfg_rom[1];
end

always @*
begin: FSM
    next_state = state;
    case (state)
        IDLE: begin
            if (start)
                next_state = WAIT;
        end
	WAIT: begin
		
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
) l_counter(
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

endmodule
