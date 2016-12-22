/* MAC Cache
 * For ECE 576 Hardware implementation of UDP final project
 * This is an associative cache of MAC addresses indexed by
 * associated IP addresses.  This is updated upon receiving
 * ARP packets.  This is read when sending IP packets.  A miss
 * is indicated by outputing a MAC address of 00:00:00:00:00:00.
 * The cache is updated in a FIFO manner.
 * A cache line has the following format:
 * [ V | IP address | MAC address ]
 * [ 1 | 32         | 48          ]
 * Total line size: 81 bits
 */

 `define VALID 80
 `define IP_ADDR 79:48
 `define MAC_ADDR 47:0

module mac_cache(
	input clk,
	input reset,
	//write port
	input [31:0] w_ip_addr,
	input [47:0] w_mac_addr,
	input w_en,
	//read port
	input [31:0] r_ip_addr,
	output reg [47:0] r_mac_addr,
	input r_en
	);

//how many lines does the cache have?
parameter N = 8;

//cache data
reg [80:0] cache [N-1:0];
//this should be log_2(N)-1:0
reg [2:0] next;
reg found;

//loop counter
integer i;

always @(posedge clk) begin
	if(reset) begin
		//invalidate all entries on reset
		for(i = 0; i < N; i = i+1)
			cache[i][`VALID] <= 1'b0;
		//reset next spot to write to 0
		next <= 3'h0;
		found <= 1'b0;
		//set output to 0
		r_mac_addr <= 48'h0;
	end else
	begin
		//write an entry
		if (w_en) begin
			//$display("i am writing");
			found = 1'b0;
			//search all entries for a valid match, update that one if found
			for(i = 0; i < N; i = i+1) begin
				if (cache[i][`VALID] && cache[i][`IP_ADDR] == w_ip_addr) begin
					//$display("writing to i(%d)",i);
					cache[i][`MAC_ADDR] <= w_mac_addr;
					found = 1'b1;
				end
			end
			if (!found) begin
				//if no previous entry found, write next entry, set valid and data, increment next
				//$display("writing to next(%d)",next);
				cache[next][`VALID] <= 1'b1;
				cache[next][`IP_ADDR] <= w_ip_addr;
				cache[next][`MAC_ADDR] <= w_mac_addr;
				next <= next + 3'h1;
			end
		end

		//read an entry
		if (r_en) begin
			//$display("i am trying to read");
			//default to MAC address 00:00:00:00:00:00
			r_mac_addr <= 48'h0;
			//search all entries for a valid match, set r_mac_addr if one is found
			for(i = 0; i < N; i = i+1) begin
				if (cache[i][`VALID] && cache[i][`IP_ADDR] == r_ip_addr) begin
					//$display("found a read match");
					r_mac_addr <= cache[i][`MAC_ADDR];
				end
			end
		end

	end
end

endmodule
