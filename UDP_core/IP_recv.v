
`define IP_ADDRR 32'hc0a80102
`define VERS 31:28
`define HLEN 27:24
`define TLEN 15:0

module IP_recv(
	input             clk,
	input             reset,
	input             ivalid,
	input [31:0]      ip_data,

	output reg        udp_valid,
	output reg [31:0] udp_data
);

reg [15:0] cnt;
reg [16:0] tmp_accum1, tmp_accum2, tmp_accum3;
reg [15:0] accum1, accum2, final_accum,checksum, head_length, full_length, data_length;
reg [31:0] ip_data_buffer;
reg	   options, bufcnt, start_data;
reg [7:0] proto;

always @(posedge clk) begin
	if (reset) begin
		cnt <= 16'b0;
		bufcnt <= 1'b1;
		udp_data <= 32'h0;
		udp_valid <= 1'b0;
		ip_data_buffer <= 32'h0;
		options <= 1'b0;
		data_length <= 16'h0;
		start_data <= 1'b0;
		proto <= 8'h0;
	end
	else if (ivalid) begin
		case (cnt) 
			0: begin
				udp_valid <= 1'b0;
				accum1 <= ip_data[15:0];
				accum2 <= ip_data[31:16];
				head_length <= ip_data[`HLEN] << 2;
				full_length <= ip_data[`TLEN];
				if (ip_data[`HLEN] == 4'd5) begin
					options <= 1'b0;
				end
				else if (ip_data[`HLEN] > 4'd5) begin
					options <= 1'b1;
				end
				cnt <= cnt + 16'b1;
				bufcnt <= 1'b1;
			end
			1: begin
				tmp_accum1 = (accum1 + ip_data[15:0]);
				accum1 <= tmp_accum1[15:0] + tmp_accum1[16];
				tmp_accum2 = (accum2 + ip_data[31:16]);
				accum2 <= tmp_accum2[15:0] + tmp_accum2[16];

				data_length <= full_length - head_length;
				cnt <= cnt + 16'b1;
				start_data <= 1'b1;
			end
			2: begin
				tmp_accum2 = (accum2 + ip_data[31:16]);
				accum2 <= tmp_accum2[15:0] + tmp_accum2[16];
				accum1 <= accum1;
				checksum <= ip_data[15:0];
				proto <= ip_data[23:16];

				data_length <= data_length >> 2;
				cnt <= cnt + 16'b1;
			end
			3: begin
				tmp_accum1 = (accum1 + ip_data[15:0]);
				accum1 <= tmp_accum1[15:0] + tmp_accum1[16];
				tmp_accum2 = (accum2 + ip_data[31:16]);
				accum2 <= tmp_accum2[15:0] + tmp_accum2[16];
				cnt <= cnt + 16'b1;
			end
			4: begin
				tmp_accum1 = (accum1 + ip_data[15:0]);
				accum1 <= tmp_accum1[15:0] + tmp_accum1[16];
				tmp_accum2 = (accum2 + ip_data[31:16]);
				accum2 <= tmp_accum2[15:0] + tmp_accum2[16];
				tmp_accum1 <= 17'h0;
				tmp_accum2 <= 17'h0;

				if (ip_data != `IP_ADDRR) begin
					//error
				end
				cnt <= cnt + 16'b1;
			end
			5: begin
				if (options == 1'b0) begin
					tmp_accum3 = accum1 + accum2;
					final_accum <= tmp_accum3[15:0] + tmp_accum3[16];
					if (data_length == 16'h0000) begin
						//stop
						$display("stop");
					end
					else if (data_length != 16'h0000) begin
						data_length <= data_length - 16'h0001;
						ip_data_buffer <= ip_data;
					end
				end
				else if (options == 1'b1) begin
					//something with options length here
					$display("OPTIONS WERE INCLUDED!");
				end
				cnt <= cnt + 16'b1;
			end
			6:  begin
				if (final_accum != ~checksum) begin
					//die
					$display("something messed up here: %h %h %h", final_accum, ~checksum, checksum);
				end
				udp_valid <= 1'b1;
				ip_data_buffer <= ip_data;
				udp_data <= ip_data_buffer;
				data_length <= data_length - 16'h0001;
				cnt <= cnt + 16'b1;
			end
			7:  begin
			$display("outputing: %h i have %d words left", ip_data_buffer, data_length);
				udp_valid <= 1'b1;
				ip_data_buffer <= ip_data;
				udp_data <= ip_data_buffer;
				data_length <= data_length - 16'h0001;
				//cnt <= cnt + 16'b1;
			end
			default: cnt <= 16'h0;
		endcase
	end
	else if (~ivalid) begin
		if ((data_length == 16'h0) && (start_data == 1'b1)) begin
			if (bufcnt != 1'b0) begin
				bufcnt <= bufcnt - 1'b1;
				udp_valid <= 1'b1;
				udp_data <= ip_data_buffer;
				cnt <= 16'b0;
				start_data <= 1'b0;
			end
			/*else if (bufcnt == 1'b0) begin
				udp_valid <= 1'b0;
				cnt <= 16'b0;
				start_data <= 1'b0;
			end*/
		end
		else if ((data_length == 16'h0) && (start_data == 1'b0)) begin
			udp_valid <= 1'b0;
		end
		else if (data_length != 16'h0) begin
			udp_valid <= 1'b0;
		end	
	end	
end

endmodule
