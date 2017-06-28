`include "params.vh"

module PU_controller #(
    parameter integer LAYER_PARAM_WIDTH          = 10,
    parameter integer MAX_LAYERS                 = 64
)(
    input wire                                 clk,
    input wire                                 reset,
    input wire                                 start,
    
    output reg [ 3               - 1 : 0 ]     state
);

//FSM states
localparam IDLE         = 0,
           WAIT         = 1;

reg [ 3                   - 1 : 0 ]         next_state;

reg [ LAYER_PARAM_WIDTH   - 1 : 0 ]         max_layers;

initial begin
    max_layers = `max_layers;
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

endmodule
