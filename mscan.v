module mscan(
    input wire CLK,
    input wire nRESET,
    input wire algr_en,
    output wire [7:0] data_OUT,
    output wire [7:0] W_addr,
    output wire result_comp0,
    output wire result_comp1,
    output wire result_comp2,
    output wire result_comp3,
    output reg iWrite_reg,
    output reg iRead_reg,
    output reg [1:0] memSel_reg,
    output reg writeAll_reg,
    output reg DATA_EN_reg,
    output reg ADDR_EN_reg,
    output reg ADDR_RST_reg,
    output reg [3:0] gen_Turn_reg,
    output reg [2:0] PAT_SEL_reg,
    output reg compare_EN_reg,
    output reg captureData_reg,
    output reg [3:0] compSel_reg,
    output reg rstComp_reg
);

    // FSM states for MSCAN algorithm [cite: 5, 6, 7, 8]
    localparam IDLE         = 5'd0;
    localparam WRITE_ZERO1  = 5'd1;
    localparam READ_ZERO1   = 5'd3;
    localparam READ_ZERO2   = 5'd4;
    localparam READ_ZERO3   = 5'd5;
    localparam READ_ZERO4   = 5'd6;
    localparam READ_ZERO5   = 5'd7;
    localparam COMPARE_ZERO = 5'd8;
    localparam WRITE_ONE    = 5'd9;
    localparam READ_ONE1    = 5'd10;
    localparam READ_ONE2    = 5'd11;
    localparam READ_ONE3    = 5'd12;
    localparam READ_ONE4    = 5'd13;
    localparam READ_ONE5    = 5'd14;
    localparam COMPARE_ONE  = 5'd15;
    localparam DONE         = 5'd16;

    reg [4:0] state;
    reg [7:0] addr_counter; 

    always @(posedge CLK or negedge nRESET) begin
        if (!nRESET) begin 
            iWrite_reg     <= 0;
            iRead_reg      <= 0;
            memSel_reg     <= 0;
            writeAll_reg   <= 0;
            DATA_EN_reg    <= 0;
            ADDR_EN_reg    <= 0;
            ADDR_RST_reg   <= 0;
            gen_Turn_reg   <= 0;
            PAT_SEL_reg    <= 0;
            compare_EN_reg <= 0;
            captureData_reg <= 0;
            compSel_reg    <= 0;
            rstComp_reg    <= 0;
            state          <= IDLE; 
            addr_counter   <= 0; 
        end else begin
            if (algr_en) begin
                case (state)
                    IDLE: begin 
                        iWrite_reg     <= 0;
                        iRead_reg      <= 0;
                        DATA_EN_reg    <= 1;
                        ADDR_RST_reg   <= 1;
                        gen_Turn_reg   <= 4'd1; 
                        PAT_SEL_reg    <= 3'd0; 
                        addr_counter   <= 0;
                        state          <= WRITE_ZERO1; 
                    end

                    WRITE_ZERO1: begin 
                        iWrite_reg     <= 1;
                        writeAll_reg   <= 1;
                        ADDR_EN_reg    <= 1;
                        if (addr_counter < 128) begin 
                            addr_counter <= addr_counter + 1;
                        end else begin 
                            addr_counter <= 0;
                            ADDR_RST_reg <= 0;
                            state        <= READ_ZERO1; 
                            writeAll_reg <= 0;
                        end
                    end

                    READ_ZERO1: begin 
                        ADDR_RST_reg   <= 1;
                        rstComp_reg    <= 0;
                        iRead_reg      <= 1;
                        iWrite_reg     <= 0;
                        memSel_reg     <= 2'b00; 
                        state          <= READ_ZERO2;
                    end

                    READ_ZERO2: begin 
                        compSel_reg    <= 4'b0001;
                        captureData_reg <= 1;
                        state          <= READ_ZERO3;
                    end

                    READ_ZERO3: begin 
                        memSel_reg     <= 2'b01;
                        compSel_reg    <= 4'b0010;
                        state          <= READ_ZERO4;
                    end

                    READ_ZERO4: begin 
                        memSel_reg     <= 2'b10;
                        compSel_reg    <= 4'b0100;
                        state          <= READ_ZERO5;
                    end

                    READ_ZERO5: begin 
                        memSel_reg     <= 2'b11;
                        compSel_reg    <= 4'b1000;
                        state          <= COMPARE_ZERO;
                    end

                    COMPARE_ZERO: begin 
                        compare_EN_reg <= 1;
                        captureData_reg <= 0;
                        if (addr_counter < 128) begin 
                            addr_counter <= addr_counter + 1;
                            state        <= READ_ZERO1;
                            rstComp_reg  <= 1;
                        end else begin 
                            addr_counter <= 0;
                            compare_EN_reg <= 0;
                            gen_Turn_reg <= 4'd3;
                            state        <= WRITE_ONE; 
                        end
                    end

                    WRITE_ONE: begin 
                        iWrite_reg     <= 1;
                        writeAll_reg   <= 1;
                        ADDR_EN_reg    <= 1;
                        if (addr_counter < 128) begin 
                            addr_counter <= addr_counter + 1;
                        end else begin 
                            addr_counter <= 0;
                            state        <= READ_ONE1; 
                            writeAll_reg <= 0;
                        end
                    end

                    READ_ONE1: begin 
                        ADDR_RST_reg   <= 1;
                        rstComp_reg    <= 0;
                        iRead_reg      <= 1;
                        iWrite_reg     <= 0;
                        memSel_reg     <= 2'b00;
                        state          <= READ_ONE2;
                    end

                    READ_ONE2: begin 
                        compSel_reg    <= 4'b0001;
                        captureData_reg <= 1;
                        state          <= READ_ONE3;
                    end

                    READ_ONE3: begin 
                        memSel_reg     <= 2'b01;
                        compSel_reg    <= 4'b0010;
                        state          <= READ_ONE4;
                    end

                    READ_ONE4: begin 
                        memSel_reg     <= 2'b10;
                        compSel_reg    <= 4'b0100;
                        state          <= READ_ONE5;
                    end

                    READ_ONE5: begin 
                        memSel_reg     <= 2'b11;
                        compSel_reg    <= 4'b1000;
                        state          <= COMPARE_ONE;
                    end

                    COMPARE_ONE: begin 
                        compare_EN_reg <= 1;
                        captureData_reg <= 0;
                        if (addr_counter < 128) begin 
                            addr_counter <= addr_counter + 1;
                            state        <= READ_ONE1;
                            rstComp_reg  <= 1;
                        end else begin 
                            addr_counter <= 0;
                            compare_EN_reg <= 0;
                            state        <= DONE; 
                        end
                    end

                    DONE: begin 
                        iWrite_reg     <= 0;
                        iRead_reg      <= 0;
                        DATA_EN_reg    <= 0;
                        ADDR_EN_reg    <= 0;
                        state          <= DONE;
                    end

                    default: state <= IDLE; 
                endcase
            end else begin
                state <= IDLE;
            end
        end
    end

endmodule