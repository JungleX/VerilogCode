
module vectorgen_tb;






















reg                         start;

vectorgen_tb_driver #(


) driver(


    .ready         ( ready        ),


    .read_ready    ( read_ready   )  //output





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

































vectorgen #(


) u_vecgen (


    .ready         ( ready        ),  //output


    .read_ready    ( read_ready   )   //input





);




PU_controller #(








) controller_dut (
    .clk              ( clk               ),
    .reset            ( reset             ),
    .start            ( start             ),  //input
    
    .vectorgen_ready  ( ready             )   //input
    
    
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
