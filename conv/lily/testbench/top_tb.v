`timescale 1ns/1ps

module top_tb();

// System Signals
reg                                  ACLK;
reg                                  ARESETN;

// TXN REQ
reg                                  tx_req;

initial begin
        ACLK = 0;
        ARESETN = 1;
        tx_req = 0;
        @(negedge ACLK);
        ARESETN = 0;
        @(negedge ACLK);
        ARESETN = 1;
        @(negedge ACLK);
        @(negedge ACLK);
        @(negedge ACLK);
        tx_req = 1;
end

always #1 ACLK = ~ACLK;

initial begin
        #100000 $finish;
end


endmodule
