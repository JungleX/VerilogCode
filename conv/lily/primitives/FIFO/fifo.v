module fifo #(
	parameter DATA_WIDTH         = 64,
	parameter INIT               = "init.mif",
	parameter ADDR_WIDTH         = 4,
	parameter RAM_DEPTH          = (1<<ADDR_WIDTH),
	parameter INITIALIZE_FIFO    = "no"
)(
	input wire                       clk,
	input wire                       reset,
	input wire                       push,
	input wire                       pop,
	input wire [DATA_WIDTH-1 : 0]    data_in,
	output reg [DATA_WIDTH-1 : 0]    data_out,
	output reg                       empty,
	output reg                       full,
	output reg [ ADDR_WIDTH   : 0 ]  fifo_count
);

reg [ADDR_WIDTH-1:0]      wr_pointer;
reg [ADDR_WIDTH-1:0]      rd_pointer;

reg [DATA_WIDTH-1:0]      mem[0:RAM_DEPTH-1];

initial begin
	if(INITIALIZE_FIFO == "yes") begin
		$readmemh(INIT, mem, 0, RAM_DEPTH-1);
	end
end

always @(fifo_count)
begin : FIFO_STATUS
	empty = (fifo_count == 0);
	full = (fifo_count == RAM_DEPTH);
end

always @ (posedge clk)
begin : FIFO_COUNTER
	if(reset)
		fifo_count <= 0;
	else if (push && (!pop || pop&&empty) && !full)
		fifo_count <= fifo_count+1;
	else if (pop && (!push||push&&full) && !empty)
		fifo_count <= fifo_count - 1;
end

always @ (posedge clk)
begin : WRITE_PTR
	if(reset) begin
		wr_pointer <= 0;
	end
	else if (push && !full) begin
		wr_pointer <= wr_pointer + 1;
	end
end

always @ (posedge clk)
begin : READ_PTR
	if(reset) begin
		rd_pointer <= 0;
	end else if (pop && !empyt) begin
		rd_pointer <= rd_pointer + 1;
	end
end

always @ (posedge clk)
begin : WRITE
	if(push & !full) begin
		mem[wr_pointer] <= data_in;
	end
end

always @ (posedge clk)
begin : READ
	if(reset) begin
		data_out <= 0;
	end
	if(pop && !empty) begin
		data_out <= mem[rd_pointer];
	end
	else begin
		data_out <= data_out;
	end
end

endmodule
