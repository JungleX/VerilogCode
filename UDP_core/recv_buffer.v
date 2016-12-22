
//states
`define INITR     2'h0
`define ARP_RECV 2'h1
`define IP_RECV  2'h2
`define ACK      2'h3

//types
`define NONE     2'h0
`define ARP_TYPE 2'h1
`define IP_TYPE  2'h2

module recv_buffer(
	input clk,
	input reset,
	//write port - cpu
	input [31:0] data_in,
	input [1:0] data_type,
	output reg data_ack,
	//read ports
	output reg [31:0] data_arp,
	output reg v_arp,
	output reg [31:0] data_ip,
	output reg v_ip
	);

reg [31:0] arp_buffer;
reg [31:0] ip_buffer;
reg [1:0] state;

always @(posedge clk) begin
	if (reset) begin
		arp_buffer <= 32'h0;
		data_ack <= 1'b0;
		data_arp <= 32'h0;
		v_arp <= 1'b0;
		data_ip <= 32'h0;
		v_ip <= 1'b0;
		state <= `INITR;
	end else
	begin
		case(state)
			`INITR: begin
				data_ack <= 1'b0;
				case(data_type)
					`NONE: state <= `INITR;
					`ARP_TYPE: state <= `ARP_RECV;
					`IP_TYPE: state <= `IP_RECV;
					default: state <= `INITR;
				endcase
			end
			`ARP_RECV: begin
				//send output to arp_recv module
				data_arp <= data_in;
				v_arp <= 1'b1;
				//data_ack data from cpu
				data_ack <= 1'b1;
				state <= `ACK;
			end
			`IP_RECV: begin
				//send output to ip_recv module
				data_ip <= data_in;
				v_ip <= 1'b1;
				//data_ack data from cpu
				data_ack <= 1'b1;
				state <= `ACK;
			end
			`ACK: begin
				v_arp <= 1'b0;
				v_ip  <= 1'b0;
				if (data_type == `NONE) begin
					state <= `INITR;
				end else
				begin
					data_ack <= 1'b1;
					state <= `ACK;
				end
			end
		endcase
	end
end
endmodule
