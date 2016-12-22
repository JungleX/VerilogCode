/*************************
arp_rcv.v

Takes in ARP (Address Resolution Protocol)  packets, parses the various fields in the packet, and
outputs IP and MAC addresses to be sent to the IP/MAC cache.  Also determines if the incoming ARP packet
is a request for a MAC address, and if so, tells the arp_send module to which target IP and MAC address
to send our MAC address.

jdp45 mjk64 hmm32
ece576 UDP project
cornell univ 11/2007
**************************/

module arp_rcv(
       input clk,
       input reset,
       input arp_valid,
       input [31:0] arp_data,
       input reply_ready,
       output reg [31:0] w_ip_addr,
       output reg [47:0] w_mac_addr,
       output reg w_en,
       output reg [31:0] send_ip_addr,
       output reg [47:0] send_mac_addr,
       output reg send_en
);

reg [2:0] word_counter;         //increments when ARP data is being received in 7 separate 32-bit words
reg [15:0] HTYPE, PTYPE, OPER;
reg [7:0] HLEN, PLEN;
reg [47:0] SHA, THA;
reg [31:0] SPA, TPA;
reg set_outputs;                //tells state machine that the data has just been
                               //fully receieved and to set the output ports

always @(posedge clk) begin
       if (reset) begin
               // initialization
               word_counter <= 3'd0;
               set_outputs <= 1'b0;
               HTYPE <= 16'b0;
               PTYPE <= 16'b0;
               OPER <= 16'b0;
               HLEN <= 8'b0;
               PLEN <= 8'b0;
               SHA <= 48'b0;
               THA <= 48'b0;
               SPA <= 32'b0;
               TPA <= 32'b0;
               w_ip_addr <= 32'b0;
               w_mac_addr <= 48'b0;
               w_en <= 1'b0;
               send_ip_addr <= 32'b0;
               send_mac_addr <= 48'b0;
               send_en <= 1'b0;
       end
       else begin
               //take in ARP packets one word at a time when reg has valid data, as indicated by the valid bit.
               //then, when all words have been received, reset the word counter and set the set_outputs flag high
               //to enable the output addresses and enable bits to be updated once the valid bit goes low.
		//(will freeze if arp_send is not ready)
               if (arp_valid && reply_ready) begin
                       case (word_counter)
                               3'd0:
                               begin
                                       HTYPE <= arp_data[31:16];
                                       PTYPE <= arp_data[15:0];
                                       word_counter <= word_counter + 1;
                                       set_outputs <= 1'b0;
					w_en <= 1'b0;
					send_en <= 1'b0;
                               end
                               3'd1:
                               begin
                                       HLEN <= arp_data[31:24];
                                       PLEN <= arp_data[23:16];
                                       OPER <= arp_data[15:0];
                                       word_counter <= word_counter + 1;
                               end
                               3'd2:
                               begin
                                       SHA[47:16] <= arp_data;
                                       word_counter <= word_counter + 1;
                               end
                               3'd3:
                               begin
                                       SHA[15:0] <= arp_data[31:16];
                                       SPA[31:16] <= arp_data[15:0];
                                       word_counter <= word_counter + 1;
                               end
                               3'd4:
                               begin
                                       SPA[15:0] <= arp_data[31:16];
                                       THA[47:32] <= arp_data[15:0];
                                       word_counter <= word_counter + 1;
                               end
                               3'd5:
                               begin
                                       THA[31:0] <= arp_data;
                                       word_counter <= word_counter + 1;
                               end
                               3'd6:
                               begin
                                	TPA <= arp_data;
                                       	word_counter <= 3'd0;
                                       	set_outputs <= 1'b1;
                               end
                               default:
                               begin
                                       word_counter <= 3'd0;
                                       set_outputs <= 1'b0;
                               end
                       endcase
               end
               else begin
                       //if last word was just received, set output ports
                       if (set_outputs) begin
                               w_en <= 1'b1;
                               w_ip_addr <= SPA;
                               w_mac_addr <= SHA;

                               /*
                               If OPER = 1 (for now: little endian), and generally if the
                               target hardware address (THA) is 00:00:00:00:00:00, then
                               this ARP packet is a request for a MAC address, and we need to
                               send our MAC and IP address back to them.  (This code operates
                               using the OPER, not the THA.)  This will only
			       occur if the reply_ready signal coming in from
			       arp_send.v is high.
                               */
                               if ((OPER == 16'h1) && reply_ready) begin
                                       send_en <= 1'b1;
                                       send_ip_addr <= SPA;
                                       send_mac_addr <= SHA;
                               end
                               else begin
                                       send_en <= 1'b0;
                               end

                               //reset set_outputs bit
                               set_outputs <= 1'b0;
                       end
			else begin
				w_en <= 1'b0;
				send_en <= 1'b0;
			end
                      	//else, if valid bit is low for any other reason, do
			//nothing and wait for it to return high
               end
       end
end

endmodule

