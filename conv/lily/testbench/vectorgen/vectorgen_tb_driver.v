module vectorgen_tb_driver #(
)(
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

endmodule