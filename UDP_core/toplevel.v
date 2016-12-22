/* Top Level Module of all written
 * hardware modules.  
 */

`define MY_IP_ADDR					  32'hc0a80102
`define MY_MAC_ADDR					  48'h01606e11020f
/*
`include "IP_send.v"
`include "IP_recv.v"
`include "arp_send.v"
`include "arp_rcv.v"
`include "recv_buffer.v"
`include "send_buffer.v"
`include "mac_cache.v"
`include "udp_rcv.v"
`include "udp_send.v"
*/
module toplevel(
		input clk,
		input reset,
		//inputs from low-level software (MAC/PHY) to UDP stack
		input [31:0] data_in_from_ethernet,
		input [1:0] data_in_from_ethernet_type,
		input cpu_ip_done,
		input [7:0] cpu_ip_index,
		input cpu_arp_done,
		input [2:0] cpu_arp_index,
		//inputs from application software to UDP stack
		input data_out_from_app_valid,
		input [31:0] data_out_from_app,
		input [31:0] dest_ip_addr,
		input [15:0] dest_port,
		input [15:0] data_out_from_app_length,
		//outputs from UDP stack to low-level software (to MAC/PHY)
		output ack,
		output cpu_ip_ready,
		output [47:0] cpu_ip_mac,
		output [31:0] cpu_ip_data,
		output [7:0] cpu_ip_length,
		output cpu_arp_ready,
		output [47:0] cpu_arp_mac,
		output [31:0] cpu_arp_data,
		//outputs from UDP stack to application software
		output data_in_to_app_valid,
		output [31:0] data_in_to_app,
		output [15:0] input_port
);

	// The IP and MAC addresses for the FPGA:
	wire [31:0] SPA;
	assign SPA = `MY_IP_ADDR;
	wire [47:0] SHA;
	assign SHA = `MY_MAC_ADDR;
	
	// Outputs of udp_send_module
	wire [15:0] udp_data_length;
	wire [31:0] udp_data_to_ip;
	wire valid;
	wire [31:0] ip_addr;

	// Outputs of recv_buffer_module
	wire        /*ack,*/ v_arp, v_ip;
	wire [31:0] data_arp, data_ip;

	// Outputs of arp_recv_module
	wire [31:0] w_ip_addr, send_ip_addr;
	wire [47:0] w_mac_addr, send_mac_addr;
	wire        w_en, send_en;

	// Outputs of IP_recv_module
	wire [31:0] udp_data;
	wire        udp_valid;

	// Outputs of mac_cache_module
	wire [47:0] r_mac_addr;

	// Outputs of IP_send_module
	wire [31:0] ip_send_ip_addr, send_ip_data;
	wire        udp_ready, send_ip_valid;

	// Outputs from arp_send_module
	wire        arp_valid, reply_ready, request_ready;
	wire [31:0] arp_data;
	wire [47:0] arp_mac_addr;

	// Outputs from send_buffer_module
	wire        ip_send_ready, arp_send_ready, req_en, r_mac_cache_en;//, cpu_ip_ready, cpu_arp_ready;
	wire [31:0] arp_send_ip_addr, r_mac_cache_ip_addr;//, cpu_ip_data, cpu_arp_data;
//	wire [47:0] cpu_ip_mac, cpu_arp_mac;
//	wire [7:0]  cpu_ip_length;

	// Instantiated Modules
	
	udp_rcv udp_rcv_module(
		.clk(clk),
		.reset(reset),
		.udp_valid(udp_valid),
		.udp_data(udp_data),
		.data_valid(data_in_to_app_valid),
		.data(data_in_to_app),
		.dest_port(input_port)
	);

	udp_send udp_send_module(
		.clk(clk),
		.reset(reset),
		//from software app
		.data_in_valid(data_out_from_app_valid),
		.data_in(data_out_from_app),
		.ip_addr_in(dest_ip_addr),
		.dest_port(dest_port),
		.length_in(data_out_from_app_length),
		//to IP_send
		.ip_addr_out(ip_addr),
		.data_out_valid(valid),
		.data_out(udp_data_to_ip),
		.length_out(udp_data_length)
	);
	
	recv_buffer recv_buffer_module(
		.clk(clk),
		.reset(reset),
		//write port
		.data_in(data_in_from_ethernet),
		.data_type(data_in_from_ethernet_type),
		.data_ack(ack),
		//read ports
		.data_arp(data_arp),
		.v_arp(v_arp),
		.data_ip(data_ip),
		.v_ip(v_ip)
	);

	arp_rcv arp_recv_module(
	       .clk(clk),
	       .reset(reset),
	       .arp_valid(v_arp),
	       .arp_data(data_arp),
		.reply_ready(reply_ready),
	       .w_ip_addr(w_ip_addr),
	       .w_mac_addr(w_mac_addr),
	       .w_en(w_en),
	       .send_ip_addr(send_ip_addr),
	       .send_mac_addr(send_mac_addr),
	       .send_en(send_en)
	);

	IP_recv IP_recv_module(
		.clk(clk),
		.reset(reset),
		.ivalid(v_ip),
		.ip_data(data_ip),
		.udp_valid(udp_valid),
		.udp_data(udp_data)
	);


	mac_cache mac_cache_module(
		.clk(clk),
		.reset(reset),
		//write port
		.w_ip_addr(w_ip_addr),
		.w_mac_addr(w_mac_addr),
		.w_en(w_en),
		//read port
		.r_ip_addr(r_mac_cache_ip_addr),
		.r_mac_addr(r_mac_addr),
		.r_en(r_mac_cache_en)
	);

	IP_send IP_send_module(
		.clk(clk),
		.reset(reset),
		// from UDP send
		.udp_data(udp_data_to_ip),
		.ip_addr(ip_addr),
		.valid(valid),
		.data_length(udp_data_length),
		// send buffer
		.ready(ip_send_ready),
		// output ports
		.oip_addr(ip_send_ip_addr),
		.oData(send_ip_data),
		.udp_ready(udp_ready),
		.ovalid(send_ip_valid)
	);

	arp_send arp_send_module(
		.clk(clk),
		.reset(reset),
		.send_ip_addr_reply(send_ip_addr),
		.send_mac_addr_reply(send_mac_addr),
		.send_ip_addr_request(arp_send_ip_addr),
		.SPA(SPA),
		.SHA(SHA),
		.request_en(req_en),
		.reply_en(send_en),
		.send_buffer_ready(arp_send_ready),
		.arp_valid(arp_valid),
		.arp_data(arp_data),
		.reply_ready(reply_ready),
		.request_ready(request_ready),
		.arp_mac_addr(arp_mac_addr)
	);

	send_buffer send_buffer_module(
		.clk(clk),
		.reset(reset),
		//ip send
		.ip_send_addr(ip_send_ip_addr),
		.ip_send_data(send_ip_data),
		.ip_send_valid(send_ip_valid),
		.ip_send_ready(ip_send_ready),
		//arp_send
		//**send reply ports
		.arp_send_mac_addr(arp_mac_addr),
		.arp_send_data(arp_data),
		.arp_send_valid(arp_valid),
		.arp_send_ready(arp_send_ready),
		//**send request ports
		.req_ready(request_ready),
		.arp_send_ip_addr(arp_send_ip_addr),
		.req_en(req_en),
		//mac_cache
		.r_mac_addr(r_mac_addr),
		.r_mac_cache_en(r_mac_cache_en),
		.r_mac_cache_ip_addr(r_mac_cache_ip_addr),
		//cpu
		.cpu_ip_ready(cpu_ip_ready),
		.cpu_ip_done(cpu_ip_done),
		.cpu_ip_index(cpu_ip_index),
		.cpu_ip_mac(cpu_ip_mac),
		.cpu_ip_data(cpu_ip_data),
		.cpu_ip_length(cpu_ip_length),
		.cpu_arp_ready(cpu_arp_ready),
		.cpu_arp_done(cpu_arp_done),
		.cpu_arp_index(cpu_arp_index),
		.cpu_arp_mac(cpu_arp_mac),
		.cpu_arp_data(cpu_arp_data)
	);

endmodule
