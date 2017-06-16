`include "common.vh"

module PE #(
    parameter integer PE_BUF_ADDR_WIDTH  = 10,
    parameter integer OP_WIDTH           = 16
)
(
    input wire                                clk,
    input wire                                reset,
    input wire [ `CTRL_WIDTH - 1 : 0 ]        ctrl,
    input wire                                src_2_sel,
    
    output wire                               write_valid,
    input wire                                pe_neuron_read_req,
    input wire                                pe_neuron_write_data,
    input wire                                pe_neuron_write_req,
    input wire [ PE_BUF_ADDR_WIDTH - 1: 0 ]   pe_neuron_write_addr
);

//LOCALPARAMS
localparam integer OP_CODE_WIDTH   = 3;

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

wire src_2_sel_dd;

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

endmodule