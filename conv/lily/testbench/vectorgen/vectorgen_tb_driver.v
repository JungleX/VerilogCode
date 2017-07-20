module vectorgen_tb_driver #(







)
(
    output wire                     clk,
    output wire                     reset,





    output reg                      read_ready






);
































test_status #(
    .PREFIX   ( "VECTORGEN"   ),
    .TIMEOUT  ( 100000          )
) status (
    .clk      ( clk           ),
    .reset    ( reset         ),
    .pass     ( pass          ),         //input
    .fail     ( fail          )          //input
);




















































































































always @(negedge clk)
    read_ready = 1'b1;






endmodule