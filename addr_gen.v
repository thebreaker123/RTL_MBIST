module addr_gen(
    input wire CLK,
    input wire nRESET,
    input wire ADDR_EN,
    input wire ADDR_RST,
    input wire [3:0] gen_Turn,
    input wire [2:0] PAT_SEL,
    output reg [7:0] ADDR_MBIST
);

    always @(posedge CLK or negedge nRESET) begin
        if (!nRESET) begin
            ADDR_MBIST <= 8'h00;
        end
        else begin
            if (!ADDR_RST) begin
                ADDR_MBIST <= 8'h00;
            end
            else if (ADDR_EN) begin
                case (PAT_SEL)
                    3'd0, 3'd1, 3'd2: begin
                        if (ADDR_MBIST >= 8'd127)
                            ADDR_MBIST <= 8'h00;
                        else                            
                            ADDR_MBIST <= ADDR_MBIST + 8'd1;
                    end
                    3'd3: begin
                        ADDR_MBIST <= 8'h00;
                    end
                    default: begin
                        ADDR_MBIST <= 8'h00;
                    end
                endcase
            end
            else begin
                ADDR_MBIST <= ADDR_MBIST;
            end
        end
    end

endmodule