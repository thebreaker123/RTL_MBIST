module data_gen (
    input wire CLK,
    input wire nRESET,
    input wire DATA_EN,
    input wire [3:0] gen_Turn,
    input wire [2:0] PAT_SEL,
    output reg [7:0] DATA_MBIST,
    output reg [7:0] DATA_comp
);

    always @(posedge CLK or negedge nRESET) begin
        if (!nRESET) begin
            DATA_MBIST <= 8'h00; 
            DATA_comp  <= 8'h00;
        end
        else if (DATA_EN) begin
            case (PAT_SEL)
                // 1. MSCAN Mode
                3'd0: begin
                    if (gen_Turn == 4'd1) begin
                        DATA_MBIST <= 8'h00; 
                        DATA_comp  <= 8'h00; 
                    end 
                    else if (gen_Turn == 4'd3) begin
                        DATA_MBIST <= 8'hff; 
                        DATA_comp  <= 8'hff; 
                    end
                    else begin
                        DATA_MBIST <= 8'h00;
                        DATA_comp  <= 8'h00;
                    end
                end 

                // 2. Checkerboard Mode
                3'd1: begin
                    case (gen_Turn)
                        4'h0: begin // Pattern 0101
                            DATA_MBIST <= 8'b01010101; 
                            DATA_comp  <= 8'b01010101;
                        end
                        4'hf: begin // Pattern 1010
                            DATA_MBIST <= 8'b10101010; 
                            DATA_comp  <= 8'b10101010; 
                        end
                        default: begin
                            DATA_MBIST <= 8'h00;
                            DATA_comp  <= 8'h00;
                        end
                    endcase
                end

                // 3. March C Mode
                3'd2: begin
                    if (gen_Turn == 4'd0 || gen_Turn == 4'd2 || gen_Turn == 4'd4) begin
                        DATA_MBIST <= 8'h00; 
                        DATA_comp  <= 8'hff;            
                    end 
                    else if (gen_Turn == 4'd1 || gen_Turn == 4'd3 || gen_Turn == 4'd5) begin
                        DATA_MBIST <= 8'hff; 
                        DATA_comp  <= 8'h00; 
                    end
                    else begin
                        DATA_MBIST <= 8'h00;
                        DATA_comp  <= 8'h00;
                    end
                end

                // 4. Default Case (Tránh lỗi Synthesis)
                default: begin
                    DATA_MBIST <= 8'h00; 
                    DATA_comp  <= 8'h00; 
                end
            endcase     
        end 
        else begin
            // Duy trì giá trị khi không Enable
            DATA_MBIST <= DATA_MBIST; 
            DATA_comp  <= DATA_comp;
        end
    end
     
endmodule