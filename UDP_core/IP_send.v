/*
* Module IP_send
* 11/12/07
* H.McCreary
*/

`define VERSION 4'h4
`define IHL 4'h5
`define TOS 8'h0
`define SRC_ADDR 32'hc0a80102
`define ID_BASE 16'h0
`define FLAG 3'b010
`define FRAGMENT_OFFSET 13'h0
`define TTL 8'h40
`define PROTOCOL 8'h11
`define CHKSUM_BASE 16'h86bc

module IP_send(
	input clk,
	input reset,
	// from UDP send
	input [31:0] udp_data,
	input [31:0] ip_addr,
	input 	     valid,
	input [15:0] data_length,
	// send buffer
	input        ready,
	// output ports
	output reg [31:0] oip_addr,
	output reg [31:0] oData,
	output            udp_ready,
	output		  ovalid
);
	// registers
	reg [31:0] data_buffer1, data_buffer2, data_buffer3, data_buffer4, data_buffer5, data_buffer6;
	reg [31:0] ip_addr_reg;
	reg [15:0] total_length, cnt,datagram_cnt,accum1,accum2,chksum;
	reg [16:0] tmp_accum1, tmp_accum2;
	reg	   isvalid, ovalid_reg;
	reg [2:0]  bufcnt;

	assign udp_ready = ready;
	assign ovalid = ovalid_reg;

	always @(posedge clk) begin
		isvalid <= valid;

		if (reset) begin
			cnt <= 16'h0;
			datagram_cnt <= 16'h0;
			ip_addr_reg <= 32'h0;
			data_buffer1 <= 32'h0;
			data_buffer2 <= 32'h0;
			data_buffer3 <= 32'h0;
			data_buffer4 <= 32'h0;
			data_buffer5 <= 32'h0;
			data_buffer6 <= 32'h0;
			bufcnt <= 3'b111;
			oData <= 32'h0;
			oip_addr <= 32'h0;
			ovalid_reg <= 1'b0;
		end
		if (valid & ~reset) begin
			case (cnt)
				0: begin
					// start calculating header checksum
					tmp_accum1 = ip_addr[31:16] + ip_addr[15:0];
					accum1 <= tmp_accum1[15:0] + tmp_accum1[16];
					bufcnt <= 3'b111;
					data_buffer1 <= udp_data;

					datagram_cnt <= datagram_cnt + 16'h1;
					ip_addr_reg  <= ip_addr;
					total_length <= data_length + (`IHL << 2);

					cnt <= cnt + 16'b1;
				end
				1: begin
					// send first word of header
					oData <= {`VERSION,`IHL,`TOS,total_length};
					oip_addr <= ip_addr_reg;
					// set valid high for output
					ovalid_reg <= 1'b1;
					// continue calculating header checksum
					tmp_accum2 = total_length + (`ID_BASE + datagram_cnt);
					accum2 <= tmp_accum2[15:0] + tmp_accum2[16];
					tmp_accum1 = accum1 + `CHKSUM_BASE;
					accum1 <= tmp_accum1[15:0] + tmp_accum1[16];
					// propagate data down buffer chain
					data_buffer2 <= data_buffer1;
					data_buffer1 <= udp_data;
					cnt <= cnt + 16'b1;
				end
				2: begin
					// send second word of header
					oData <= {`ID_BASE + datagram_cnt,`FLAG,`FRAGMENT_OFFSET};
					// final calculation of head checksum
					tmp_accum1 = accum1 + accum2;
					chksum <= ~(tmp_accum1[15:0] + tmp_accum1[16]);
					// propagate data down buffer chain
					data_buffer3 <= data_buffer2;
					data_buffer2 <= data_buffer1;
					data_buffer1 <= udp_data;
					cnt <= cnt + 16'b1;
				end
				3: begin
					// send third word of header
					oData <= {`TTL,`PROTOCOL,chksum};
					// propagate data down buffer chain
					data_buffer4 <= data_buffer3;
					data_buffer3 <= data_buffer2;
					data_buffer2 <= data_buffer1;
					data_buffer1 <= udp_data;
					cnt <= cnt + 16'b1;
				end
				4: begin
					// send fourth word of header
					oData <= `SRC_ADDR;
					// propagate data down buffer chain
					data_buffer5 <= data_buffer4;
					data_buffer4 <= data_buffer3;
					data_buffer3 <= data_buffer2;
					data_buffer2 <= data_buffer1;
					data_buffer1 <= udp_data;
					cnt <= cnt + 16'b1;
				end
				5: begin
					// send fifth word of header
					oData <= ip_addr_reg;
					// propagate data down buffer chain
					data_buffer6 <= data_buffer5;
					data_buffer5 <= data_buffer4;
					data_buffer4 <= data_buffer3;
					data_buffer3 <= data_buffer2;
					data_buffer2 <= data_buffer1;
					data_buffer1 <= udp_data;
					cnt <= cnt + 16'b1;
				end
				6: begin
					// begin sending buffered data
					oData <= data_buffer6;
					data_buffer6 <= data_buffer5;
					data_buffer5 <= data_buffer4;
					data_buffer4 <= data_buffer3;
					data_buffer3 <= data_buffer2;
					data_buffer2 <= data_buffer1;
					data_buffer1 <= udp_data;
				end
			endcase
		end
		if (~valid) begin
			if (bufcnt != 3'b000) begin
				oData <= data_buffer6;
				data_buffer6 <= data_buffer5;
				data_buffer5 <= data_buffer4;
				data_buffer4 <= data_buffer3;
				data_buffer3 <= data_buffer2;
				data_buffer2 <= data_buffer1;
				data_buffer1 <= udp_data;	
				bufcnt <= bufcnt - 3'b001;
			end
			else if (bufcnt == 3'b000) begin
				ovalid_reg <= 1'b0;
				cnt <= 16'h0;
			end
		end
	end

endmodule
