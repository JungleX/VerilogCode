module vectorgen # (
) (
    input wire                            clk,
    input wire                            reset,
    output reg [2 - 1:0]                  state,
    
    input wire                            read_ready,
    
    output wire                           read_req
);

localparam integer IDLE = 0, READ = 1, READY = 2, LAST = 3;

//Vectorgen Controls Signals
wire                                     vectorgen_start;

// State machine
reg [1:0] next_state;

reg [4:0] reads_remaining;

always @(posedge clk)
begin
    if(reset)
        reads_remaining <= 0;
end

always @*
begin: VECGEN_FSM
    next_state = state;
    case (state)
        IDLE: begin
            if (vectorgen_start)
                next_state = READ;
        end
        READ: begin
            if((reads_remaining == 1) && read_req && read_ready || (reads_remaining == 0))
                next_state = READY;
        end
    endcase
end

always @(posedge clk)
begin
    if (reset)
        state <= 1'b0;
    else
        state <= next_state;
end

assign read_req = ((state != LAST && !(state == READY && vectorgen_lastData)) && (read_ready && ((vectorgen_nextData || vectorgen_skip || vectorgen_start) ||
    reads_remaining != 0))) && read_ready;

endmodule