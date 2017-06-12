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
	
	integer loading_size = 0;
    integer reading_size = 0;

	initial begin
		$readmemb("H:/git/VerilogCode/conv/PE/image_0001.mem", pcie_data);
		
		wea = 1; // port a for write
		enb = 0;
		loading_size = 0;
		addra = 0;
		while(loading_size <= 51528) begin
		  ena = 1;
		  write_data = {1'b0, pcie_data[loading_size]};
		  #`clk_period
		  addra = addra + 1;
          loading_size = loading_size + 1;
		end
		
		#`clk_period 
        ena = 0;
        wea = 0;
        enb = 1;
        addrb = 0;
        
        // read data
        while(reading_size <= 51528) begin
            #`clk_period
            addrb = addrb + 1;
            reading_size = reading_size + 1;
        end
        
        enb = 0;
        
        // stop the simulation
        #`clk_period
        $finish;
	end

endmodule

