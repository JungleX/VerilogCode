`include "common.vh"

module PE #(
    parameter integer PE_BUF_ADDR_WIDTH  = 10,
    parameter integer OP_WIDTH           = 16
)
(
    input wire                                clk,
    input wire                                reset,
    input wire                                mask,
    input wire [ `CTRL_WIDTH - 1 : 0 ]        ctrl,
    input wire                                src_2_sel,
    
    input wire [ OP_WIDTH    - 1 : 0 ]        read_data_0,
    input wire [ OP_WIDTH    - 1 : 0 ]        read_data_1,  
    input wire [ OP_WIDTH    - 1 : 0 ]        read_data_2, 
      
    output wire                               write_valid,
    output wire [ OP_WIDTH   - 1 : 0 ]        pe_buffer_read_data,
    input wire                                pe_neuron_read_req,
    input wire                                pe_neuron_write_data,
    input wire                                pe_neuron_write_req,
    input wire [ PE_BUF_ADDR_WIDTH - 1: 0 ]   pe_neuron_write_addr
);

//LOCALPARAMS
localparam integer OP_CODE_WIDTH   = 3;

//data
wire [ OP_WIDTH         - 1 : 0 ]            pe_buffer_read_data_d;

//fifo
wire                                         _pe_buffer_write_req;
wire                                         pe_buffer_write_req;
wire                                         pe_buffer_read_req;
wire                                         _pe_buffer_read_req;

wire                                         flush, flush_d;
wire                                         enable;
wire [ OP_CODE_WIDTH - 1 : 0]                op_code;

wire [ PE_BUF_ADDR_WIDTH - 1 : 0 ]           buf_rd_addr;
wire [ PE_BUF_ADDR_WIDTH - 1 : 0 ]           buf_wr_addr;
wire [ PE_BUF_ADDR_WIDTH - 1 : 0 ]           _buf_wr_addr;

//Normalization FIFO
wire norm_fifo_push;
wire norm_fifo_pop;
wire norm_fifo_empty;
wire norm_fifo_full;

assign {norm_fifo_push, norm_fifo_pop, buf_rd_addr, _buf_wr_addr,
        flush, write_valid, _pe_buffer_write_req, _pe_buffer_read_req, enable, op_code} = ctrl;
        
assign pe_buffer_read_req = _pe_buffer_read_req || pe_neuron_read_req;
assign pe_buffer_write_req = _pe_buffer_write_req || pe_neuron_write_req;
assign buf_wr_addr = pe_neuron_write_req ? pe_neuron_write_addr : _buf_wr_addr;

wire                           macc_enable;
wire                           macc_clear;
wire [OP_CODE_WIDTH - 1 : 0]   macc_op_code;
wire [OP_WIDTH      - 1 : 0]   macc_op_0;
wire [OP_WIDTH      - 1 : 0]   macc_op_1;
wire [OP_WIDTH      - 1 : 0]   macc_op_add;
wire [OP_WIDTH      - 1 : 0]   macc_out;

//enable 在 ctrl 倒数第4位
assign macc_enable      = enable && mask;
assign macc_clear       = !mask;
//op_code 是 ctrl 后2位
assign macc_op_code     = op_code;

assign macc_op_0        = read_data_0;
assign macc_op_1        = read_data_1;
assign macc_op_add      = src_2_sel_dd == `SRC_2_BIAS ? read_data_2 : pe_buffer_read_data;

//Delays
register #(
    .NUM_STAGES  ( 2           ),
    .DATA_WIDTH  ( 1           )
) src_2_delay(
    .CLK         ( clk         ),
    .RESET       ( reset       ),
    .DIN         ( src_2_sel   ),
    .DOUT        ( src_2_sel_dd)
);

register #(
    .NUM_STAGES  ( 3           ),
    .DATA_WIDTH  ( OP_WIDTH           )
) fifo_out_delay (
    .CLK         ( clk         ),
    .RESET       ( reset       ),
    .DIN         ( pe_buffer_read_data   ),
    .DOUT        ( pe_buffer_read_data_d )
);

// ********************************************
// MACC
// ********************************************
macc #(
	.OP_0_WIDTH        ( OP_WIDTH            ),
	.OP_1_WIDTH        ( OP_WIDTH            ),
	.ACC_WIDTH         ( OP_WIDTH            ),
	.OUT_WIDTH         ( OP_WIDTH            )
) MACC_pe (
    .clk               ( clk                 ),
    .reset             ( reset               ),
    .enable            ( macc_enable         ),
    .clear             ( macc_clear          ),
    .op_code           ( macc_op_code        ),
    .op_0              ( macc_op_0           ),
    .op_1              ( macc_op_1           ),
    .op_add            ( macc_op_add         ),
    .out               ( macc_out            )
);

// ***********************************************
// PE Buffer
// ***********************************************


endmodule