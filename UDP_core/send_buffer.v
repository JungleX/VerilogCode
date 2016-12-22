
`define INIT 2'h0 //all
`define RECV 2'h1 //ri, ra
`define MAC  2'h1 //trans
`define IP   2'h1 //cpu
`define WAIT 2'h2 //ri, ra, trans
`define ARP  2'h2
`define REQ  2'h3 //trans


module send_buffer(
	input clk,
	input reset,
	//ip send
	input [31:0] ip_send_addr,
	input [31:0] ip_send_data,
	input ip_send_valid,
	output reg ip_send_ready,
	//arp_send
	//**send reply ports
	input [47:0] arp_send_mac_addr,
	input [31:0] arp_send_data,
	input arp_send_valid,
	output reg arp_send_ready,
	//**send request ports
	input req_ready,
	output reg [31:0] arp_send_ip_addr,
	output reg req_en,
	//mac_cache
	input [47:0] r_mac_addr,
	output reg r_mac_cache_en,
	output reg [31:0] r_mac_cache_ip_addr,
	//cpu
	output reg cpu_ip_ready,
	input cpu_ip_done,
	input [7:0] cpu_ip_index,
	output reg [47:0] cpu_ip_mac,
	output reg [31:0] cpu_ip_data,
	output reg [7:0] cpu_ip_length,
	output reg cpu_arp_ready,
	input cpu_arp_done,
	input [2:0] cpu_arp_index,
	output reg [47:0] cpu_arp_mac,
	output reg [31:0] cpu_arp_data
	);

//arp vars
reg [1:0] ra_state;
reg [47:0] ra_mac_addr;
reg [31:0] ra_data[6:0];
reg [2:0] ra_count;
//ip vars
reg [1:0] ri_state;
reg [47:0] ri_mac_addr;
reg [31:0] ri_ip_addr;
reg [31:0] ri_data[255:0];
reg [7:0] ri_count;
reg ri_buf_wait; //goes high after recving ip data, low after sent to cpu
reg ri_buf_translate; //goes high after recving ip data
//translation vars
reg [1:0] mac_state;
reg [15:0] mac_timeout;

integer i;

//receive arp reply state machine
always @(posedge clk) begin
	if(reset) begin
		ra_state <= `INIT;
		ra_count <= 3'h0;
		arp_send_ready <= 1'b1;
		cpu_arp_ready <= 1'b0;
		ra_mac_addr <= 48'h0;
		for(i = 3'h0; i < 3'h7; i = i+1)
			ra_data[i] <= 32'h0;
	end else
	begin
		case (ra_state)
			`INIT: begin
				if (arp_send_valid) begin
					ra_state <= `RECV;
					ra_mac_addr <= arp_send_mac_addr;
					ra_data[0] <= arp_send_data;
					ra_count <= 3'h1; //start receiving at the second word
				end
			end
			`RECV: begin
				if (ra_count < 3'h7) begin
					ra_data[ra_count] <= arp_send_data;
					ra_count <= ra_count + 3'h1;
				end else
				begin
					ra_count <= 3'h0;
					arp_send_ready <= 1'b0;
					ra_state <= `WAIT;
					cpu_arp_ready <= 1'b1;
				end
			end
			`WAIT: begin
				if (cpu_arp_done == 1'b1) begin
					cpu_arp_ready <= 1'b0;
					ra_state <= `INIT;
					arp_send_ready <= 1'b1;
				end
			end
		endcase
	end
end

//receive ip state machine
always @(posedge clk) begin
	if(reset) begin
		ri_state <= `INIT;
		ri_count <= 8'h0;
		ri_buf_wait <= 1'b0;
		ip_send_ready <= 1'b1;
		ri_buf_translate <= 1'b0;
		cpu_ip_ready <= 1'b0;
		for(i = 8'h0; i < 8'hFF; i = i+1)
			ri_data[i] <= 32'h0;
	end else
	begin
		case (ri_state)
			`INIT: begin
				if (ip_send_valid) begin
					ri_state <= `RECV;
					ri_ip_addr <= ip_send_addr;
					ri_data[0] <= ip_send_data;
					ri_count <= 8'h1; //start receiving at the second word
				end
			end
			`RECV: begin
				if (ip_send_valid) begin
					ri_data[ri_count] <= ip_send_data;
					ri_count <= ri_count + 8'h1;
				end else
				begin
					//ri_count <= 8'h0; - keep this count around in order to know the length of the data
					ip_send_ready <= 1'b0;
					ri_state <= `WAIT;
					ri_buf_wait <= 1'b1;
					ri_buf_translate <= 1'b1;
				end
			end
			`WAIT: begin
				ri_buf_translate <= 1'b0;
				if (cpu_ip_done == 1'b1 || mac_timeout == 16'h0) begin
					cpu_ip_ready <= 1'b0;
					ri_state <= `INIT;
					ip_send_ready <= 1'b1;
					ri_count <= 8'h0;
				end else
				if (r_mac_addr != 48'h0) begin
					cpu_ip_ready <= 1'b1;
				end
			end
		endcase
	end
end

//ip->mac translation state machine
always @(posedge clk) begin
	if(reset) begin
		mac_state <= `INIT;
		mac_timeout <= 16'hFFFF;
		ri_mac_addr <= 48'h0;
		r_mac_cache_en <= 1'b0;
		r_mac_cache_ip_addr <= 32'h0;
		req_en <= 1'b0;
		arp_send_ip_addr <= 32'b0;
	end else
	begin
		case (mac_state)
			`INIT: begin
				if (ri_buf_translate) begin
					mac_state <= `MAC;
					r_mac_cache_en <= 1'b1;
					r_mac_cache_ip_addr <= ri_ip_addr;
				end
			end
			`MAC: begin
				r_mac_cache_en <= 1'b0;
				if (r_mac_addr == 48'h0) begin
					//no translation, need to send an arp request
					$display("arp request time!");
					mac_state <= `REQ;
				end else
				begin
					//found a translation, use it and done
					$display("found translation in mac cache!");
					ri_mac_addr <= r_mac_addr;
					mac_state <= `INIT;
				end
			end
			`REQ: begin
				if(req_ready) begin
					arp_send_ip_addr <= ri_ip_addr;
					req_en <= 1'b1;
					mac_state <= `WAIT;
				end
			end
			`WAIT: begin
				mac_timeout <= mac_timeout - 16'h1;
				if (mac_timeout == 16'hFFFF) begin
					$display("waiting for reply!");
					//turn off arp request
					req_en <= 1'b0;
					//turn mac cache back on
					r_mac_cache_en <= 1'b1;
					r_mac_cache_ip_addr <= ri_ip_addr;
				end else
				if (r_mac_addr != 48'h0) begin
				    	$display("got translation!");
					//found a translation, use it and done
					r_mac_cache_en <= 1'b0;
					ri_mac_addr <= r_mac_addr;
					mac_state <= `INIT;
				end else 
				if (mac_timeout == 16'h0) begin
				    	$display("timeout!");
					//waited long enough, error out
					r_mac_cache_en <= 1'b0;
					ri_buf_wait <= 1'b0;
					mac_state <= `INIT;
				end
			end
		endcase
	end
end

//send data to cpu logic
always @(ra_mac_addr) begin
	cpu_arp_mac <= ra_mac_addr;
end

always @(ri_mac_addr) begin
	cpu_ip_mac <= ri_mac_addr;
end

always @(ri_count) begin
	cpu_ip_length <= ri_count;
end

always @(ri_data[cpu_ip_index]) begin
	cpu_ip_data <= ri_data[cpu_ip_index];
end

always @(ra_data[cpu_arp_index]) begin
	cpu_arp_data <= ra_data[cpu_arp_index];
end

//send data to cpu state machine
/*
reg [1:0] dc_state;
reg [7:0] dc_count;
reg dc_is_arp;
always @(posedge clk) begin
	if(reset) begin
		dc_state <= `INIT;
		dc_count <= 8'h0;
		dc_count_max <= 8'h0;
		dc_is_arp <= 1'b0;
	end else
	begin
		case (dc_state)
			`INIT: begin
				if (ra_buf_ready == 1'b1) begin
					dc_state <= `SEND;
					dc_is_arp <= 1'b1;
					ether_mac_addr <= ra_mac_addr;
					dc_count_max <= 8'h7; //arp packets are always 7 words
					dc_count <= 8'h0;
				else if (ri_buf_ready == 1'b1) begin
					dc_state <= `SEND;
					dc_is_arp <= 1'b0;
					ether_mac_addr <= ri_mac_addr;
					dc_count_max <= ri_count; //ip packets length is stored in ri_count
					dc_count <= 8'h0;
				end
			end
			`SEND: begin
				if (cpu_ready) begin
					dc_count <= dc_count + 1;
					cpu_valid <= 1'b1;
					dc_state <= `WAIT;
					if (dc_is_arp == 1'b1) begin
						cpu_data <= ra_data[dc_count[2:0]];
					else begin
						cpu_data <= ri_data[dc_count];
					end
				end else
				begin
				end
			end
			`WAIT: begin
				if (!cpu_ready) begin
					cpu_valid <= 1'b0;
				end
			end
		endcase
	end
end
*/
endmodule
