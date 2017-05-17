`include "bit_width.vh"
`define clk_period 10

module read_fm();
	reg clk;

	reg [14:0] pcie_data[0:154586]; // get data from file, 154587 = 227*227*3
	reg [15:0] write_data; // write data, two 16 bits floating-point numbers
	wire [15:0] read_data; // read data, a 16 bits floating-point number

	reg [15:0] addra;
        reg [15:0] addrb;
	reg ena;
    	reg enb;
    	reg wea;

	conv1 con_layer_1(
		.clka(clk), 
		.ena(ena),
		.wea(wea), 
		.addra(addra),
		.dina(write_data), 
		.clkb(clk), 
		.enb(enb), 
		.addrb(addrb), 
		.doutb(read_data));

	initial 
		clk = 1'b0;
	always #(`clk_period/2)clk = ~clk;

	initial begin
		$readmemb("data.mem", pcie_data);
	end

endmodule

