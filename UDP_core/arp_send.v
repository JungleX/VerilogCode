`define REQUEST	16'h0001
`define REPLY	16'h0002

/*************************
arp_send.v

Generates ARP packets based on IP and MAC addresses that need to be sent.

Inputs:
clk
reset
send_ip_addr_reply (from arp_rcv)
send_mac_addr_reply (from arp_rcv)
send_ip_addr_request (from send_buffer)
SPA (from ip_send)
SHA (from ip_send)
request_en (a bit that is high if a request needs to be sent)
reply_en (a bit that is high if a reply needs to be sent)
send_buffer_ready (enables sending of ARP packets to the send_buffer module)

Outputs:
arp_valid (to send_buffer)
arp_data (to send_buffer)
reply_ready (to arp_rcv)
request_ready (to send_buffer)
arp_mac_addr (to send_buffer)


jdp45 mjk64 hmm32
ece576 UDP project
cornell univ 11/2007
**************************/

module arp_send(
	input clk,
	input reset,
	input [31:0] send_ip_addr_reply,
	input [47:0] send_mac_addr_reply,
	input [31:0] send_ip_addr_request,
	input [31:0] SPA,
	input [47:0] SHA,
	input request_en,
	input reply_en,
	input send_buffer_ready,
	output reg arp_valid,
	output reg [31:0] arp_data,
	output reply_ready,
	output request_ready,
	output reg [47:0] arp_mac_addr
);

reg [2:0] word_counter;         //increments when ARP data is being received in 7 separate 32-bit words
reg [15:0] HTYPE, PTYPE, OPER;
reg [7:0] HLEN, PLEN;
reg [47:0] THA;
reg [31:0] TPA;
reg request_buffer_valid, reply_buffer_valid, clear_to_send;
reg [31:0] ip_request_buffer, ip_reply_buffer;
reg [47:0] mac_reply_buffer;

//only ready for new packets when buffers do not have valid data in them
assign request_ready = ~request_buffer_valid;
assign reply_ready = ~reply_buffer_valid;


always @(posedge clk) begin
       if (reset) begin
               	// initialization
               	word_counter <= 3'd0;
               	HTYPE <= 16'h0001;
               	PTYPE <= 16'h0800;
               	HLEN <= 8'h06;
               	PLEN <= 8'h04;
		OPER <= 16'h0;
		THA <= 48'h0;
		TPA <= 32'h0;
		clear_to_send <= 1'b0;
		request_buffer_valid <= 1'b0;
		reply_buffer_valid <= 1'b0;
		ip_request_buffer <= 32'b0;
		ip_reply_buffer <= 32'b0;
		mac_reply_buffer <= 32'b0;
		arp_mac_addr <= 48'b0;
		arp_valid <= 1'b0;
		arp_data <= 32'b0;
       end
       else begin
		case ({request_en, reply_en})
			2'b00:
			begin
				//check the buffers for data
				if ((send_buffer_ready) && (!clear_to_send) && (!arp_valid)) begin
					if (request_buffer_valid) begin
						OPER <= `REQUEST;
						TPA <= ip_request_buffer;
						THA <= 48'h0;
						request_buffer_valid <= 1'b0;
						clear_to_send <= 1'b1;
					end
					else if ((reply_buffer_valid) && (!request_buffer_valid)) begin
						OPER <= `REPLY;
						TPA <= ip_reply_buffer;
						THA <= mac_reply_buffer;
						reply_buffer_valid <= 1'b0;
						clear_to_send <= 1'b1;
					end
				end
				else begin
					clear_to_send <= 1'b0;
				end
			end
			2'b01:
			begin
				if ((send_buffer_ready) && (!clear_to_send) && (!arp_valid)) begin
					OPER <= `REPLY;
					TPA <= send_ip_addr_reply;
					THA <= send_mac_addr_reply;
					clear_to_send <= 1'b1;
				end
				else begin
					ip_reply_buffer <= send_ip_addr_reply;
					reply_buffer_valid <= 1'b1;
					mac_reply_buffer <= send_mac_addr_reply;
					clear_to_send <= 1'b0;
				end
			end
			2'b10:
			begin
				if ((send_buffer_ready) && (!clear_to_send) && (!arp_valid)) begin
					OPER <= `REQUEST;
					TPA <= send_ip_addr_request;
					THA <= 48'h0;
					clear_to_send <= 1'b1;
				end
				else begin
					ip_request_buffer <= send_ip_addr_request;
					request_buffer_valid <= 1'b1;
					clear_to_send <= 1'b0;
				end
			end
			2'b11:
			begin
				if ((send_buffer_ready) && (!clear_to_send) && (!arp_valid)) begin
					OPER <= `REQUEST;
					TPA <= send_ip_addr_request;
					THA <= 48'h0;
					clear_to_send <= 1'b1;
				end
				else begin
					ip_request_buffer <= send_ip_addr_request;
					request_buffer_valid <= 1'b1;
					clear_to_send <= 1'b0;
				end
				ip_reply_buffer <= send_ip_addr_reply;
				reply_buffer_valid <= 1'b1;
				mac_reply_buffer <= send_mac_addr_reply;
			end
			default:
			begin
				
			end
		endcase	
		//Data Tx state machine:
               	//send out ARP packets one word at a time when send_buffer_ready is high, 
		//and set the valid bit high when doing so.  increment through the 
		//words using word_counter.
               	if (send_buffer_ready) begin
                       	case (word_counter)
                               3'd0:
                               begin
					if (clear_to_send) begin //packet is beginning to be sent
						arp_data <= {HTYPE, PTYPE};
						arp_valid <= 1'b1;
                                       		word_counter <= word_counter + 1;
						clear_to_send <= 1'b0;

						//send MAC address independently of packet
						if (OPER == `REQUEST) begin
							arp_mac_addr <= 48'hFFFFFFFFFFFF;
						end
						else begin
							arp_mac_addr <= THA;
						end
					end
					else begin //packet just finished being sent... now we wait for another clear_to_send
						arp_valid <= 1'b0;
					end
                               end
                               3'd1:
                               begin
					arp_data <= {HLEN, PLEN, OPER};
					arp_valid <= 1'b1;
                                       	word_counter <= word_counter + 1;
                               end
                               3'd2:
                               begin
					arp_data <= SHA[47:16];
					arp_valid <= 1'b1;
                                       	word_counter <= word_counter + 1;
                               end
                               3'd3:
                               begin
					arp_data <= {SHA[15:0], SPA[31:16]};
					arp_valid <= 1'b1;
                                       	word_counter <= word_counter + 1;
                               end
                               3'd4:
                               begin
                                       	arp_data <= {SPA[15:0], THA[47:32]};
					arp_valid <= 1'b1;
                                       	word_counter <= word_counter + 1;
                               end
                               3'd5:
                               begin
                                       	arp_data <= THA[31:0];
					arp_valid <= 1'b1;
                                       	word_counter <= word_counter + 1;
                               end
                               3'd6:
                               begin
                                       	arp_data <= TPA;
					arp_valid <= 1'b1;
                                       	word_counter <= 3'd0;
                               end
                               default: //should not reach this state
                               begin
					arp_data <= 32'b0;
					arp_valid <= 1'b0;
                                       	word_counter <= 3'd0;
                               end
                      	endcase
			
               end
               else begin
			arp_valid <= 1'b0;
			//word_counter <= 3'd0;
               end
       end
end

endmodule

