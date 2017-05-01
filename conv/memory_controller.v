`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SJTU Tcloud FPGA Group
// Engineer: 
// 
// Create Date: 2017/04/21 16:05:14
// Design Name: 
// Module Name: memory_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


    module memory_controller(
    input clk,
    input rst,
    input ena,
    
    input[2:0] readState, // from global controller
    input[2:0] loadState, // from PCIe controller
    
    input biasFull,
    input biasEmpty,
    output biasRst,
    output biasWrEn,
    output biasRdEn,
    
    input weightFull,
    input weightEmpty,
    output weightWrEn,
    output weightRdEn,
    output weightRst,
    
    output layerEna,
    output layerWea, // 0:read or 1:write
    output layerRst,
    
    output loadDone,
    output[3:0] memoryState // to global controller,{biasFull,biasEmpty,weightFull,weightEmpty}
    );
    
    reg allLoadDone;
    reg b_rst;
    reg b_wr_en;
    reg b_rd_en;
    reg w_rst;
    reg w_wr_en;
    reg w_rd_en;
    reg l_ena;
    reg l_wea;
    reg l_rst;
    reg[3:0] m_state;
    
    parameter ALL_READING          = 3'b111,
                ALL_READ_DONE       = 3'b000,
                BIAS_READING        = 3'b100,
                WEIGHT_READING      = 3'b010,
                LAYER_READING       = 3'b001,
                BIAS_WEIGHT_READING  = 3'b110,
                BIAS_LAYER_READING   = 3'b101,
                WEIGHT_LAYER_READING = 3'b011;
     
    // 1:loading
    // 0:done
    parameter ALL_LOADING          = 3'b111,
                ALL_lOAD_DONE        = 3'b000,
                BIAS_LOADING         = 3'b100,
                WEIGHT_LOADING       = 3'b010,
                LAYER_LOADING        = 3'b001,
                BIAS_WEIGHT_LOADING  = 3'b110,
                BIAS_LAYER_LOADING   = 3'b101,
                WEIGHT_LAYER_LOADING = 3'b011;
                
    assign biasRst = b_rst;
    assign biasWrEn = b_wr_en;
    assign biasRdEn = b_rd_en;
    assign weightRst = w_rst;
    assign weightWrEn = w_wr_en;
    assign weightRdEn = w_rd_en;
    assign layerEna = l_ena;
    assign layerWea = l_wea;
    assign layerRst = l_rst;
    
    assign loadDone = allLoadDone;
    assign memoryState = m_state;
   
    always @(posedge clk or posedge rst) begin
        if(ena) begin
            if(rst) begin
                b_rst   <= 1'b1;
                b_wr_en <= 1'b0; 
                b_rd_en <= 1'b0; 
                w_rst   <= 1'b1;
                w_wr_en <= 1'b0;
                w_rd_en <= 1'b0; 
                l_ena   <= 1'b0;
                l_wea   <= 1'b0;
                l_rst   <= 1'b1;
                allLoadDone <= 1'b0;
            end
            else begin
                b_rst <= 1'b0;
                w_rst <= 1'b0;
                l_rst <= 1'b0;
            end
        end
    end
    
    always @(posedge clk) begin
        if(ena) begin
            m_state <= {biasFull,biasEmpty,weightFull,weightEmpty};
        
            case(readState)
                ALL_READING:
                    begin
                        b_rd_en <= 1'b1;
                        w_rd_en <= 1'b1;
                        l_ena <= 1'b1;
                        l_wea <= 1'b0;
                    end
                ALL_READ_DONE:
                    begin
                        b_rd_en <= 1'b0;
                        w_rd_en <= 1'b0;
                        l_ena <= 1'b0;
                        l_wea <= 1'b0;
                    end
                BIAS_READING:
                    begin
                    b_rd_en <= 1'b1;
                    w_rd_en <= 1'b0;
                    l_ena <= 1'b0;
                    end
                WEIGHT_READING:
                    begin
                        b_rd_en <= 1'b0;
                        w_rd_en <= 1'b1;
                        l_ena <= 1'b0;
                    end
                LAYER_READING:
                    begin
                        b_rd_en <= 1'b0;
                        w_rd_en <= 1'b0;
                        l_ena <= 1'b1;
                        l_wea <= 1'b0;
                    end
                BIAS_WEIGHT_READING: 
                    begin
                        b_rd_en <= 1'b1;
                        w_rd_en <= 1'b1;
                        l_ena <= 1'b0;
                    end
                BIAS_LAYER_READING:
                    begin
                        b_rd_en <= 1'b1;
                        w_rd_en <= 1'b0;
                        l_ena <= 1'b1;
                        l_wea <= 1'b0;
                    end
                WEIGHT_LAYER_READING:
                    begin
                        b_rd_en <= 1'b0;
                        w_rd_en <= 1'b1;
                        l_ena <= 1'b1;
                        l_wea <= 1'b0;
                    end
            endcase
            
            case(loadState)
                ALL_LOADING: 
                    begin 
                        allLoadDone <= 1'b0;
                        b_wr_en <= 1'b1;  
                        w_wr_en <= 1'b1; 
                        l_ena <= 1'b1;
                        l_wea <= 1'b1;
                    end
                ALL_lOAD_DONE:
                    begin
                        allLoadDone <= 1'b1;
                        b_wr_en <= 1'b0;  
                        w_wr_en <= 1'b0;
                        l_ena <= 1'b0;
                    end
                BIAS_LOADING:
                    begin
                        allLoadDone <= 1'b0;
                        b_wr_en <= 1'b1;  
                        w_wr_en <= 1'b0;
                        l_ena <= 1'b0;
                    end                
                WEIGHT_LOADING:
                    begin
                        allLoadDone <= 1'b0;
                        b_wr_en <= 1'b0;  
                        w_wr_en <= 1'b1;
                        l_ena <= 1'b0;
                    end
                LAYER_LOADING:
                    begin
                        allLoadDone <= 1'b0;
                        b_wr_en <= 1'b0;  
                        w_wr_en <= 1'b0;
                        l_ena <= 1'b1;
                        l_wea <= 1'b1;
                    end
                BIAS_WEIGHT_LOADING:
                    begin
                        allLoadDone <= 1'b0;
                        b_wr_en <= 1'b1;  
                        w_wr_en <= 1'b1;
                        l_ena <= 1'b0;
                    end
                BIAS_LAYER_LOADING:
                    begin
                        allLoadDone <= 1'b0;
                        b_wr_en <= 1'b1;  
                        w_wr_en <= 1'b0;
                        l_ena <= 1'b1;
                        l_wea <= 1'b1;
                    end
                WEIGHT_LAYER_LOADING:
                    begin
                        allLoadDone <= 1'b0;
                        b_wr_en <= 1'b0;  
                        w_wr_en <= 1'b1;
                        l_ena <= 1'b1;
                        l_wea <= 1'b1;
                    end
            endcase
        end
    end
        
endmodule
