`include "params.vh"
`include "common.vh"
module PU_tb_driver #(
	parameter integer OP_WIDTH    = 16,
	parameter integer NUM_PE      = 1,
	parameter integer VERBOSE     = 2            //ศ฿ำเ
)(
    output wire                           clk,
    output wire                           reset,
    
    output reg                            buffer_read_empty,
    output reg                            buffer_read_data_valid,
    
    output reg                            buffer_read_last,
    input  wire                           pu_rd_req,
    output wire                           pu_rd_ready,
    
    
    
    
    output reg                            pass,
    output reg                            fail
);









reg signed [OP_WIDTH-1:0] buffer [0:1<<20];
reg signed [OP_WIDTH-1:0] expected_out [0:1<<20];



reg signed [OP_WIDTH-1:0] norm_lut [0:1<<6];

initial
$readmemb ("hardware/include/norm_lut.vh", norm_lut);



integer input_fm_dimensions [3:0];
integer input_fm_size;
integer output_fm_dimensions [3:0];
integer pool_fm_dimensions [3:0];
integer weight_dimensions [4:0];
integer buffer_dimensions [4:0];
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
















































































































































































































task expected_output;
    input integer input_width;
    input integer input_height;
    input integer input_channels;
    
    input integer batchsize;
    
    input integer kernel_width;
    input integer kernel_height;
    input integer kernel_stride;
    
    input integer output_channels;
    
    input integer pad_w;
    input integer pad_r_s;       //row start
    input integer pad_r_e;      //row end
    
    integer output_width;
    integer output_height;
    
    integer iw, ih, ic, b, kw, kh, ow, oh;
    
    integer input_index, output_index, kernel_index;
    
    integer in, in_w, in_h;
    
    begin
        write_count = 0;
        ow = ( input_width - kernel_width + 2*pad_w) / kernel_stride + 1;
        output_width = (ceil_a_by_b(
            ((input_width - kernel_width + 2*pad_w) / kernel_stride) + 1,          //ow
            NUM_PE)) * NUM_PE;
            
            output_height = (input_height - kernel_height + pad_r_s + pad_r_e) / kernel_stride + 1;
            $display ("Expected output size %d x %d x %d x %d\n",
                output_width, output_height, output_channels, batchsize);
            output_fm_dimensions[0] = output_width;
            output_fm_dimensions[1] = output_height;
            output_fm_dimensions[2] = output_channels;
            output_fm_dimensions[3] = batchsize;   
            for(ih=0; ih<output_height; ih=ih+1)
            begin
                for(iw=0; iw<output_width; iw=iw+1)
                begin
                    output_index = ih * output_width + iw;
                    expected_out[output_index] = 0;
                    for(ic=0; ic<input_channels; ic=ic+1)
                    begin
                        for(kh=0; kh<kernel_height; kh=kh+1)
                        begin
                            if (VERBOSE > 1) $write("%6d + ",
                                expected_out[output_index]);
                            for (kw=0; kw < kernel_width && iw < ow; kw=kw+1)
                            begin
                                in_h = ( ih*kernel_stride + kh - pad_r_s );
                                in_w = ( iw*kernel_stride + kw - pad_w);
                                input_index = (0 * input_height + in_h) * input_width + in_w;
                                in = data_in[input_index];
                                if(in_h < 0 || in_h >= input_height ||
                                    in_w < 0 || in_w >= input_width)
                                    in = 0;
                                kernel_index = (0*kernel_height + kh) * kernel_width + kw;
                                expected_out[output_index] = ((weight[kernel_index] * in) >>> `PRECISION_FRAC) + expected_out[output_index];
                                if(VERBOSE > 1) $write("%8d x ",weight[kernel_index]);
                                if(VERBOSE > 1) $write("%-8d + ",in);
                            end   //end loop kw
                            if(VERBOSE > 1) $display
                        end  //end loop kh
                        if(VERBOSE > 1)
                        begin
                            $write(" = %6d",
                                expected_out[output_index]);
                            $display;
                            $display;
                        end
                    end   // end loop ic
                    
                    if(VERBOSE > 1)
                    begin
                        $write(" = %6d",
                            expected_out[output_index]);
                        $display;
                        $display;
                    end   
                    if (VERBOSE > 1) $display;
                end //end loop iw
            end  //end loop ih
            expected_writes = (output_width/NUM_PE) * output_height;
            output_fm_size = ceil_a_by_b(output_width, NUM_PE) * output_height;
            if(VERBOSE == 1) $display("Expected number of writes = %6d", expected_writes);
     end
endtask

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
	integer i, j, c;
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
		buffer_dimensions[0] = width;
        buffer_dimensions[1] = height;
        buffer_dimensions[2] = input_channels;
        buffer_dimensions[3] = output_channels;
        buffer[0] = 0;
        buffer[1] = 0;
        buffer[2] = 0;
        buffer[3] = 0;
        for (k=0; k<input_channels; k=k+1)
        begin
            for (l=0; l<output_channels; l=l+1)
            begin
                for(i=0; i<height; i=i+1)
                begin
                    for(j=0; j<width; j=j+1)
                    begin
                        index = (((l*output_channels + k)* height + i) * width + j); 
                        weight[index] = (index+0) << `PRECISION_FRAC;                //fixed-point
                        buffer[index+4] = weight[index];
                        
                        
                        
                    end
                end
            end
        end
        buffer_read_empty = 1'b0;
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















integer write_count;
initial write_count = 0;
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

initial begin
    buffer_read_data_valid = 0;
    buffer_read_last = 1'b0;
    buffer_read_empty = 1'b1;
end

endmodule
