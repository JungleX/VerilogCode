`include "common.vh"

module PU_tb_driver #(
	parameter integer OP_WIDTH    = 16,
	parameter integer NUM_PE      = 1
)(
    output wire                           clk,
    output wire                           reset,
    input  wire                           pu_rd_req,
    output wire                           pu_rd_ready,
    output reg                            pass,
    output reg                            fail
);

reg signed [OP_WIDTH-1:0] norm_lut [0:1<<6];

initial
$readmemb ("hardware/include/norm_lut.vh", norm_lut);

integer input_fm_dimensions [3:0];
integer input_fm_size;
integer output_fm_dimensions [3:0];
integer pool_fm_dimensions [3:0];
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

/*task expected_pooling_output;
    input integer pool_w;
    input integer pool_h;
    input integer stride;
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
		pool_fm_dimensions[0] = ceil_a_by_b(ceil_a_by_b(iw - pool_w, stride)+1, NUM_PE)*NUM_PE;
        pool_fm_dimensions[1] = ceil_a_by_b(ih - pool_h, stride)+1;
	end
endtask*/

/*task print_pooled_output;
endtask*/

/*task print_pe_output;
endtask*/

/*task expected_output_fc;
endtask*/

/*task expected_output_norm;
endtask*/

/*task expected_output;
endtask*/

integer max_data_in_count;

/*task initialize_weight_fc;
endtask*/

/*task initialize_input_fc;
endtask*/

task initialize_input;
	input integer width;
	input integer height;
	input integer channels;
	input integer output_channels;
	integer i. j, c;
	integer idx;
	begin
		rd_ready = 1'b1;
		data_in_counter = 0;
		input_fm_dimensions[0] = width;
		input_fm_dimensions[1] = height;
		input_fm_dimensions[2] = channels;
		input_fm_dimensions[3] = output_channels;
		input_fm_size = width * height * channels;
		max_data_in_count = width * height;
		$display ("# Input Neurons = %d", max_data_in_count);
		$display ("Input Dimensions = %d x %d x %d x %d",
			width, height, channels, output_channels);
		for (c=0; c < channels; c=c+1)
		begin
			for (i=0; i < height; i=i+1)
			begin
				for (j=0; j < width; j=j+1)
				begin
					idx = j + width*(i + height*c);
					data_in[idx] = idx;         //input feature map data
				end
			end
		end
		
	end
endtask

task initialize_weight;
	input integer width;
	input integer height;
	input integer input_channels;
	input integer output_channels;
	integer i, j, k, l;
	integer index;
	begin
		weight_dimensions[0] = width;
		weight_dimensions[1] = height;
		weight_dimensions[2] = input_channels;
		weight_dimensions[3] = output_channels;
	end
endtask

integer data_in_counter;
task pu_read;
    integer i;
    integer input_idx;
    integer tmp;
    begin
        input_idx = data_in_counter % input_fm_size;
    end
endtask

/*task pu_write
endtask*/

always @(posedge clk)
begin
    if(pu_rd_req && pu_rd_ready)
        pu_read;
end

initial begin
    data_in_counter = 0;
    rd_ready = 0;
end

integer delay_count = 0;
reg rd_ready;
always @(negedge clk)
begin
    if(delay_count != 24)                      //why 24?
        delay_count <= delay_count + 1;
    else
        delay_count <= 0;
end

assign pu_rd_ready = (delay_count == 0) && rd_ready;
//assign pu_rd_ready = rd_ready;

endmodule
