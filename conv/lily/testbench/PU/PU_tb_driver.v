`include "params.vh"
`include "common.vh"
module PU_tb_driver #(
	parameter integer OP_WIDTH    = 16,
	parameter integer NUM_PE      = 1,
	parameter integer VERBOSE     = 2            //ศ฿ำเ
)
(
    output wire                           clk,
    output wire                           reset,
    output reg [4*OP_WIDTH-1:0]           buffer_read_data_out,
    output reg                            buffer_read_empty,
    output reg                            buffer_read_data_valid,
    input wire                            buffer_read_req,
    output reg                            buffer_read_last,
    input  wire                           pu_rd_req,
    output wire                           pu_rd_ready,
    input wire                            pu_wr_req,
    input wire signed [DATA_WIDTH-1:0]    pu_data_out,           //data_width = num_pe * op_width
    output reg [DATA_WIDTH-1:0]           pu_data_in, 
    output reg                            pass,
    output reg                            fail
);



localparam integer DATA_WIDTH  = OP_WIDTH * NUM_PE;



reg signed [OP_WIDTH-1:0] data_in [0:1<<20];

reg signed [OP_WIDTH-1:0] buffer [0:1<<20];
reg signed [OP_WIDTH-1:0] expected_out [0:1<<20];



reg signed [OP_WIDTH-1:0] norm_lut [0:1<<6];

initial
$readmemb ("norm_lut.vh", norm_lut);



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

clk_rst_driver 
clkgen(
	.clk       ( clk       ),
	.reset_n   (           ),
	.reset     ( reset     )
);

task expected_pooling_output;
    input integer pool_w;
    input integer pool_h;
    input integer stride;
	integer iw, ih, ic;
	integer ow, oh;
	integer ii, jj;
	integer kk, ll;
	integer output_index, input_index;
	integer max;
	integer in_w, in_h;
	integer tmp;
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
        tmp = ceil_a_by_b(iw - pool_w, stride) + 1;
        if( tmp < NUM_PE)
            ow = tmp;
        else
            ow = pool_fm_dimensions[0];
        $display ("Pooling dimensions\t = %d x %d",
            pool_fm_dimensions[0],
            pool_fm_dimensions[1]);
        oh = pool_fm_dimensions[1];
        for (ii=0; ii<oh; ii=ii+1)
        begin
            for (jj=0; jj<ow; jj=jj+1)
            begin
                in_w = jj*stride;
                in_h = ii*stride;
                input_index = (ii*stride)*iw+jj*stride;
                output_index = ii*ow+jj;
                if( in_h < ih && in_w < iw)
                    max = expected_out[input_index];
                else
                    max = 0;
                for (kk=0; kk<pool_h; kk=kk+1)
                begin
                    for (ll=0; ll<pool_w; ll=ll+1)
                    begin
                        in_w = jj*stride+ll;
                        in_h = ii*stride+kk;
                        input_index = (in_h)*iw + in_w;
                        if (in_h < ih && in_w < iw)
                            max = max > expected_out[input_index] ?
                                max : expected_out[input_index];
                    end
                end
                expected_pool_out[output_index] = max;
            end
        end
        expected_writes = ceil_a_by_b(ow, NUM_PE) * oh;
        ouput_fm_size = ceil_a_by_b(ow, NUM_PE) * oh;
        $display("Expected number of pooled writes = %6d",
            expected_writes);
	end
endtask

task print_pooled_output;
    integer w,h;
    begin
        for (h=0; h<pool_fm_dimensions[1]; h=h+1)
        begin
            for (w=0; w<pool_fm_dimensions[0]; w=w+1)
            begin
                $write ("%8d", expected_pool_out[h*pool_fm_dimensions[0]+w]);
            end
            $display;
        end
    end
endtask

task print_pe_output;
    integer w,h;
    begin
        for (h=0; h<output_fm_dimensions[1]; h=h+1)
        begin
            for (w=0; w<output_fm_dimensions[0]; w=w+1)
            begin
                $write ("%6d", expected_out[h*output_fm_dimensions[0]+w]);
            end
            $display
        end
    end
endtask

task expected_output_fc;
    input integer input_channels;
    input integer output_channels;
    input integer max_threads;
    integer ic, oc;
    integer input_index, output_index, kernel_index;
    integer in;
    reg signed [48-1:0] acc;
    begin
        write_count = 0;
        output_fm_dimensions[0] = 1;
        output_fm_dimensions[1] = 1;
        output_fm_dimensions[2] = output_channels; 
        output_fm_dimensions[3] = 1;
        for (oc=0; oc<output_channels; oc=oc+1)
        begin
            output_index = oc;
            expected_out[output_index] = 0;
            acc = 0;
            for (ic=0; ic<input_channels && oc < max_threads; ic=ic+1)
            begin
                input_index = ic;
                if (ic==0)
                    in = 1;
                else
                    in = weight[input_index-1];
                kernel_index = ((oc/NUM_PE)*input_channels+ic) * NUM_PE + oc % NUM_PE;
                acc = (data_in[kernel_index] * in) + acc;
                if (VERBOSE > 1) $write("%4d x %-4d + ",
                    data_in[kernel_index], in);
            end
            expected_out[output_index] = acc >>> `PRECISION_FRAC;
            if( VERBOSE > 1)
                $display (" = %d\n", expected_out[output_index]);
        end
        expected_writes = ceil_a_by_b(output_channels, NUM_PE);
        output_fm_size = ceil_a_by_b(output_channels, NUM_PE) * NUM_PE;
        if (VERBOSE > 1) $display("Expected number of writes = %6d", expected_writes);
    end
endtask

task expected_output_norm;
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
    
    reg [6-1:0] lrn_weight_index;
    
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
                                expected_out[output_index] = ((in * in) >>> `PRECISION_FRAC) + expected_out[output_index];
                                if(VERBOSE > 1) $write("%8d x ",in);
                                if(VERBOSE > 1) $write("%-8d + ",in);
                            end   //end loop kw
                            if(VERBOSE > 1) $display;
                        end  //end loop kh
                        if(VERBOSE > 1)
                        begin
                            $write("%6d * %6d",
                                expected_out[output_index], data_in[output_index]);
                        end
                        lrn_weight_index = expected_out[output_index];
                        expected_out[output_index] = data_in[output_index] * norm_lut[lrn_weight_index];
                        if (VERBOSE > 1)
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
                            if(VERBOSE > 1) $display;
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


task initialize_weight_fc;
    input integer input_channels;
    input integer output_channels;
    integer i, j, k;
    integer idx, val;
    integer width, height;
    begin
        rd_ready = 1'b1;
        data_in_counter = 0;
        width = 1;
        height = 1;
        weight_dimensions[0] = width;
        weight_dimensions[1] = height;
        weight_dimensions[2] = input_channels;
        weight_dimensions[3] = output_channels;
        output_fm_dimensions[0] = width;
        output_fm_dimensions[1] = height;
        output_fm_dimensions[2] = output_channels;
        output_fm_dimensions[3] = 1;
        input_fm_size = input_channels * output_channels;
        max_data_in_count = width * height * input_channels * output_channels;
        $display ("# Input Synapse = %d", max_data_in_count);
        $display ("Weight Dimensions = %d x %d x %d x %d",
            1, 1, input_channels, output_channels);
        for (i=0; i<output_channels; i=i+1)
        begin
            for (j=0; j<input_channels; j=j+1)
            begin
                idx = i*input_channels + j;
                
                data_in[idx] = idx;
            end
        end
    end
endtask

task initialize_input_fc;
    input integer input_channels;
    integer i, j, k, l;
    integer index;
    begin
        input_fm_dimensions[0] = 1;
        input_fm_dimensions[1] = 1;
        input_fm_dimensions[2] = input_channels;
        input_fm_dimensions[3] = 1;
        buffer_dimensions[0] = input_channels;
        buffer_dimensions[1] = 1;
        buffer_dimensions[2] = 1;
        buffer_dimensions[3] = 1;
        $display("Initializing input for FC layer");
        $display("FC layer inputs = %d", input_channels);
        for (k=0; k<input_channels; k=k+1)
        begin
            index = k;
            weight[index] = (index + 1) << `PRECISION_FRAC;
            buffer[index] = weight[index];
        end
        buffer_ready_empty = 1'b0;
    end
endtask




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
