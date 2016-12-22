/**************

udp_rcv.v

Takes in data from IP_recv.v when udp_valid is high, strips the UDP header, and serves the raw data to the application layer.
Current implementation does not utilize checksum.

jdp45 hmm32 mjk64
ece 576
cornell univ
nov 07

**************/


module udp_rcv(
	input             clk,
	input             reset,
	input             udp_valid,
	input [31:0]      udp_data,

	output reg        data_valid,
	output reg [31:0] data,
	output reg [15:0] dest_port
);

reg [2:0] cnt;
reg [15:0] source_port, length, checksum;
reg start_data;
wire [15:0] data_length;
reg [15:0] data_length_countdown;

assign data_length = (length == 16'b0) ? 16'b0 : (length >> 2) - 2; //number of total bytes divided by 4 makes the number of total words, and subtract 2 words for the header

always @(posedge clk) begin
	if (reset) begin
		cnt <= 2'b0;
		data_valid <= 1'b0;
		data <= 32'b0;
		source_port <= 16'b0;
		dest_port <= 16'b0;
		length <= 16'b0;
		checksum <= 16'b0;
		start_data <= 1'b0;
		data_length_countdown <= 16'b0;
	end
	else if (udp_valid) begin
		case (cnt) 
			0: begin
				source_port <= udp_data[31:16];
				dest_port <= udp_data[15:0];
				cnt <= cnt + 2'b1;
			end
			1: begin
				length <= udp_data[31:16];
				checksum <= udp_data[15:0];
				cnt <= cnt + 2'b1;
			end
			2: begin
				if (data_length  != 16'b0) begin
					start_data <= 1'b1;
					data <= udp_data;
					data_valid <= 1'b1;
					data_length_countdown <= data_length - 16'b1;
					cnt <= cnt + 2'b1;
				end
			end
			3: begin
				if (data_length_countdown != 16'b0) begin
					data <= udp_data;
					data_valid <= 1'b1;
					data_length_countdown <= data_length_countdown - 16'b1;
				end

			end
			default: cnt <= 2'h0;
		endcase
	end
	else if (~udp_valid) begin
		if (((data_length == 16'b0) || (data_length_countdown == 16'b0)) && (start_data == 1'b1)) begin
			data_valid <= 1'b0;
			cnt <= 2'b0;
			start_data <= 1'b0;
			data_length_countdown <= 16'h2;
		end
		else begin
			data_valid <= 1'b0;
		end
	end
end

endmodule
