module vectorgen_tb;

reg                         start;

vectorgen_tb_driver #(
) driver(
);

integer layer_id, max_layers;

initial begin
    driver.status.start;                      //display beginning message  
    @(negedge clk);
    max_layers = controller_dut.max_layers+1;       //why+1?
    for (layer_id = 0; layer_id < max_layers; layer_id = layer_id+1)
    begin
        wait (controller_dut.state == 1);             //wait 
    end
end

PU_controller #(
) controller_dut (
    .clk              ( clk               ),
    .reset            ( reset             ),
    .start            ( start             )
);

initial begin
    start = 0;
    wait (read_ready);
    start = 1;
    wait (ready);
    @(negedge clk);
    @(negedge clk);
    start = 0;
end

endmodule
