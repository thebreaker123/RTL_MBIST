module wrapMbist(CLK, nRESET, algr_en, data_OUT, W_addr, result_comp0, 
                result_comp1, result_comp2, result_comp3);

    input CLK;
    input nRESET;
    input algr_en;

    reg iWrite_reg;
    reg iRead_reg;
    reg [1:0] memSel_reg;
    reg writeAll_reg;

    reg DATA_EN_reg;
    reg ADDR_EN_reg;
    reg ADDR_RST_reg;
    reg [3:0] gen_Turn_reg;
    reg [2:0] PAT_SEL_reg;
    

    reg compare_EN_reg;
    reg captureData_reg;
    reg [3:0] compSel_reg;
    reg rstComp_reg;


// FSM states for MSCAN algorithm
    localparam IDLE = 5'd0;
    localparam WRITE_ZERO1 = 5'd1;
    localparam WRITE_ZERO2 = 5'd2;
    localparam READ_ZERO1 = 5'd3;
    localparam READ_ZERO2 = 5'd4;
    localparam READ_ZERO3 = 5'd5;
    localparam READ_ZERO4 = 5'd6;
    localparam READ_ZERO5 = 5'd7;
    localparam COMPARE_ZERO = 5'd8;
    localparam WRITE_ONE = 5'd9;
    localparam READ_ONE1 = 5'd10;
    localparam READ_ONE2 = 5'd11;
    localparam READ_ONE3 = 5'd12;
    localparam READ_ONE4 = 5'd13;
    localparam READ_ONE5 = 5'd14;
    localparam COMPARE_ONE = 5'd15;
    localparam DONE = 5'd16;

    reg [4:0] state;
    reg [7:0] addr_counter;

    output [7:0] data_OUT;
    output [7:0] W_addr;
    output result_comp0;
    output result_comp1;
    output result_comp2;
    output result_comp3;


    wire [7:0] W_data;
    wire [7:0] expData;

    always @(posedge CLK or negedge nRESET) begin
        if (!nRESET) begin
            iWrite_reg <= 0;
            iRead_reg <= 0;
            memSel_reg <= 0;
            writeAll_reg <= 0;
            DATA_EN_reg <= 0;
            ADDR_EN_reg <= 0;
            ADDR_RST_reg <= 0;
            gen_Turn_reg <= 0;
            PAT_SEL_reg <= 0;
            compare_EN_reg <= 0;
            captureData_reg <= 0;
            compSel_reg <= 0;
            rstComp_reg <= 0;
            state <= IDLE;
            addr_counter <= 0;
        end else begin
            if (algr_en) begin
                case (state)
                    IDLE: begin
                        // Initialize for MSCAN
                        iWrite_reg <= 0;
                        iRead_reg <= 0;
                        memSel_reg <= 0;
                        writeAll_reg <= 0;
                        DATA_EN_reg <= 1;
                        ADDR_EN_reg <= 0;
                        ADDR_RST_reg <= 1;
                        gen_Turn_reg <= 4'd1;
                        PAT_SEL_reg <= 3'd0;
                        compare_EN_reg <= 0;
                        captureData_reg <= 0;
                        compSel_reg <= 0;
                        rstComp_reg <= 0;
                        addr_counter <= 0;
                        state <= WRITE_ZERO1;
                    end
                    WRITE_ZERO1: begin
                        iWrite_reg <= 1;
                        iRead_reg <= 0;
                        writeAll_reg <= 1;
                        gen_Turn_reg <= 4'd1;
                        PAT_SEL_reg <= 3'd0;
                        if (addr_counter < 128) begin
                            addr_counter <= addr_counter + 1;
                            ADDR_EN_reg <= 1;
                            DATA_EN_reg <= 1;
                            // state <= WRITE_ZERO2;
                        end else begin
                            addr_counter <= 0;
                            ADDR_RST_reg <= 0;
                            state <= READ_ZERO1;
                            DATA_EN_reg <= 0;
                            writeAll_reg <= 0;
                        end
                    end
                    // WRITE_ZERO2: begin
                    //     iWrite_reg <= 0;
                    //     writeAll_reg <= 0;
                    //     ADDR_EN_reg <= 0;
                    //     state <= WRITE_ZERO1;
                    // end

                    READ_ZERO1: begin
                        ADDR_RST_reg <= 1;
                        rstComp_reg <= 0;
                        iWrite_reg <= 0;
                        iRead_reg <= 1;
                        DATA_EN_reg <= 1;
                        ADDR_EN_reg <= 0;
                        compare_EN_reg <= 0;
                        captureData_reg <= 0;
                        // compare_EN_reg <= 1;
                        
                        memSel_reg <= 2'b00;
                        state <= READ_ZERO2;
                        // compSel_reg <= 4'b0001; // Enable all comparators
                        // if (addr_counter < 127) begin
                        //     addr_counter <= addr_counter + 1;
                        // end else begin
                        //     addr_counter <= 0;
                        //     gen_Turn_reg <= 4'd3; // Switch to 1
                        //     state <= WRITE_ONE;
                        // end
                    end
                    READ_ZERO2:begin 
                        compSel_reg <= 4'b0001;
                        captureData_reg <= 1;
                        state <= READ_ZERO3;
                    end
                    READ_ZERO3:begin 
                        memSel_reg <= 2'b01;
                        compSel_reg <= {compSel_reg[2:0], 1'b0};
                        captureData_reg <= 1;
                        state <= READ_ZERO4;
                    end
                    READ_ZERO4:begin 
                        memSel_reg <= 2'b10;
                        compSel_reg <= {compSel_reg[2:0], 1'b0};
                        captureData_reg <= 1;
                        state <= READ_ZERO5;
                    end
                    READ_ZERO5:begin 
                        memSel_reg <= 2'b11;
                        compSel_reg <= {compSel_reg[2:0], 1'b0};
                        captureData_reg <= 1;
                        state <= COMPARE_ZERO;
                    end
                    COMPARE_ZERO: begin
                        compare_EN_reg <= 1;
                        if (addr_counter < 128) begin
                            addr_counter <= addr_counter + 1;
                            state <= READ_ZERO1;
                            ADDR_EN_reg <= 1;
                            rstComp_reg <= 1;
                        end else begin
                            addr_counter <= 0;
                            compare_EN_reg <= 0;
                            ADDR_RST_reg <= 0;
                            gen_Turn_reg <= 4'd3; // Switch to 1
                            state <= WRITE_ONE;
                        end
                    end
                    WRITE_ONE: begin
                        ADDR_RST_reg <= 1;
                        iWrite_reg <= 1;
                        iRead_reg <= 0;
                        writeAll_reg <= 1;
                        gen_Turn_reg <= 4'd3;
                        PAT_SEL_reg <= 3'd0;
                        if (addr_counter < 128) begin
                            addr_counter <= addr_counter + 1;
                            ADDR_EN_reg <= 1;
                            DATA_EN_reg <= 1;
                            
                            // state <= WRITE_ZERO2;
                        end else begin
                            addr_counter <= 0;
                            ADDR_RST_reg <= 0;
                            writeAll_reg <= 0;
                            state <= READ_ONE1;
                            DATA_EN_reg <= 0;
                        end
                    end
                    READ_ONE1: begin
                        ADDR_RST_reg <= 1;
                        rstComp_reg <= 0;
                        iWrite_reg <= 0;
                        iRead_reg <= 1;
                        DATA_EN_reg <= 1;
                        ADDR_EN_reg <= 0;
                        compare_EN_reg <= 0;
                        captureData_reg <= 0; 
                        // compare_EN_reg <= 1;
                        
                        memSel_reg <= 2'b00;
                        state <= READ_ONE2;
                        // compSel_reg <= 4'b0001; // Enable all comparators
                        // if (addr_counter < 127) begin
                        //     addr_counter <= addr_counter + 1;
                        // end else begin
                        //     addr_counter <= 0;
                        //     gen_Turn_reg <= 4'd3; // Switch to 1
                        //     state <= WRITE_ONE;
                        // end
                    end
                    READ_ONE2:begin 
                        compSel_reg <= 4'b0001;
                        captureData_reg <= 1;
                        state <= READ_ONE3;
                    end
                    READ_ONE3:begin 
                        memSel_reg <= 2'b01;
                        compSel_reg <= {compSel_reg[2:0], 1'b0};
                        captureData_reg <= 1;
                        state <= READ_ONE4;
                    end
                    READ_ONE4:begin 
                        memSel_reg <= 2'b10;
                        compSel_reg <= {compSel_reg[2:0], 1'b0};
                        captureData_reg <= 1;
                        state <= READ_ONE5;
                    end
                    READ_ONE5:begin 
                        memSel_reg <= 2'b11;
                        compSel_reg <= {compSel_reg[2:0], 1'b0};
                        captureData_reg <= 1;
                        state <= COMPARE_ONE;
                    end
                    COMPARE_ONE: begin
                        compare_EN_reg <= 1;
                        if (addr_counter < 128) begin
                            addr_counter <= addr_counter + 1;
                            state <= READ_ONE1;
                            ADDR_EN_reg <= 1;
                            rstComp_reg <= 1;
                        end else begin
                            addr_counter <= 0;
                            compare_EN_reg <= 0;
                            ADDR_RST_reg <= 0;
                            gen_Turn_reg <= 4'd3; // Switch to 1
                            state <= DONE;
                        end
                    end
                    DONE: begin
                        // Test completed
                        iWrite_reg <= 0;
                        iRead_reg <= 0;
                        DATA_EN_reg <= 0;
                        ADDR_EN_reg <= 0;
                        compare_EN_reg <= 0;
                        captureData_reg <= 0;
                        // Stay in DONE or reset
                    end
                endcase
            end else begin
                state <= IDLE;
            end
        end
    end


    data_gen u_data_gen0
    (
        .CLK(CLK),
        .nRESET(nRESET),
        .DATA_EN(DATA_EN_reg),
        .gen_Turn(gen_Turn_reg),
        .PAT_SEL(PAT_SEL_reg),
        .DATA_MBIST(W_data),
        .DATA_comp(expData)
    );

    addr_gen u_addr_gen0
    (
        .CLK(CLK),
        .nRESET(nRESET),
        .ADDR_EN(ADDR_EN_reg),
        .ADDR_RST(ADDR_RST_reg),
        .ADDR_MBIST(W_addr),
        .gen_Turn(gen_Turn_reg),
        .PAT_SEL(PAT_SEL_reg)
    );

    comparator u_comparator0
    (   
        .CLK(CLK),
        .nRESET(nRESET),
        .rstComp(rstComp_reg),
        .dataMem(data_OUT),
        .ExpDATA(expData),
        .RESULT(result_comp0),
        .compSel(compSel_reg[0]),
        .captureData(captureData_reg),
        .compare_EN(compare_EN_reg)
    );

    comparator u_comparator1
    (
        .CLK(CLK),
        .nRESET(nRESET),
        .rstComp(rstComp_reg),
        .dataMem(data_OUT),
        .ExpDATA(expData),
        .RESULT(result_comp1),
        .compSel(compSel_reg[1]),
        .captureData(captureData_reg),
        .compare_EN(compare_EN_reg)
    );

    comparator u_comparator2
    (
        .CLK(CLK),
        .nRESET(nRESET),
        .rstComp(rstComp_reg),
        .dataMem(data_OUT),
        .ExpDATA(expData),
        .RESULT(result_comp2),
        .compSel(compSel_reg[2]),
        .captureData(captureData_reg),
        .compare_EN(compare_EN_reg)
    );
    
    comparator u_comparator3
    (
        .CLK(CLK),
        .nRESET(nRESET),
        .rstComp(rstComp_reg),
        .dataMem(data_OUT),
        .ExpDATA(expData),
        .RESULT(result_comp3),
        .compSel(compSel_reg[3]),
        .captureData(captureData_reg),
        .compare_EN(compare_EN_reg)
    );    

    memBank u_memBank0
    (.iClk(CLK),
     .iAddr(W_addr),
     .iWrite(iWrite_reg),
     .iWrData(W_data),
     .iRead(iRead_reg),
     .memSel(memSel_reg),
     .writeAll(writeAll_reg),
     .data_OUT(data_OUT));





endmodule