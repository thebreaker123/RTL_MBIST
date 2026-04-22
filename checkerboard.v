module checkerboard(
    input wire CLK,
    input wire nRESET,
    input wire cb_en,
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
    output reg rstComp_reg,
    output reg cb_done          
);

    // Định nghĩa các trạng thái FSM
    localparam IDLE          = 4'd0;
    localparam WRITE_P1      = 4'd1; 
    localparam READ_P1_INIT  = 4'd2; 
    localparam CAPTURE_P1    = 4'd3; 
    localparam COMPARE_P1    = 4'd4; 
    localparam RST_COMP_P1   = 4'd5; 
    localparam WRITE_P2      = 4'd6; 
    localparam READ_P2_INIT  = 4'd7;
    localparam CAPTURE_P2    = 4'd8; 
    localparam COMPARE_P2    = 4'd9; 
    localparam RST_COMP_P2   = 4'd10;
    localparam DONE          = 4'd11;

    reg [3:0] state;
    reg [7:0] addr_counter;

    always @(posedge CLK or negedge nRESET) begin
        if (!nRESET) begin
            state <= IDLE;
            addr_counter <= 0;
            iWrite_reg <= 0; iRead_reg <= 0; writeAll_reg <= 0;
            DATA_EN_reg <= 0; ADDR_EN_reg <= 0; ADDR_RST_reg <= 0;
            compare_EN_reg <= 0; captureData_reg <= 0; rstComp_reg <= 0;
            cb_done <= 0; compSel_reg <= 4'b0000; memSel_reg <= 2'b00;
            PAT_SEL_reg <= 3'd1; 
        end else if (cb_en) begin
            case (state)
                IDLE: begin
                    ADDR_RST_reg <= 1;
                    DATA_EN_reg  <= 1;
                    addr_counter <= 0;
                    cb_done      <= 0;
                    state        <= WRITE_P1;
                end
ư
                WRITE_P1: begin
                    iWrite_reg   <= 1;
                    iRead_reg    <= 0; // Tắt đọc khi đang ghi 
                    writeAll_reg <= 1; // Ghi vào tất cả bộ nhớ
                    ADDR_EN_reg  <= 1;
                    gen_Turn_reg <= 4'h0; // Mẫu 55h từ Data Generator 
                    if (addr_counter < 127) addr_counter <= addr_counter + 1;
                    else begin
                        addr_counter <= 0;
                        ADDR_RST_reg <= 0; 
                        state        <= READ_P1_INIT;
                    end
                end

                READ_P1_INIT: begin
                    iWrite_reg      <= 0; // Dừng ghi tuyệt đối
                    iRead_reg       <= 1; // Bật đọc 
                    ADDR_RST_reg    <= 1;
                    memSel_reg      <= 2'b00;
                    rstComp_reg     <= 0; // Giải phóng Reset cho bộ so sánh
                    compare_EN_reg  <= 0;
                    state           <= CAPTURE_P1;
                end

                CAPTURE_P1: begin
                    captureData_reg <= 1; // Cho phép bộ so sánh capture data 
                    compSel_reg     <= (4'b0001 << memSel_reg); // Chọn comparator 
                    if (memSel_reg < 2'b11) memSel_reg <= memSel_reg + 1;
                    else state <= COMPARE_P1;
                end

                COMPARE_P1: begin
                    captureData_reg <= 0;
                    compare_EN_reg  <= 1; // Thực hiện so sánh 
                    state           <= RST_COMP_P1;
                end

                RST_COMP_P1: begin
                    compare_EN_reg  <= 0;
                    rstComp_reg     <= 1; // Reset data cũ sau khi so sánh xong 
                    if (addr_counter < 127) begin
                        addr_counter <= addr_counter + 1;
                        state        <= READ_P1_INIT;
                    end else begin
                        addr_counter <= 0;
                        ADDR_RST_reg <= 0;
                        state        <= WRITE_P2;
                    end
                end

                // --- Giai đoạn 2: Ghi và Kiểm tra mẫu AAh (1010) ---
                WRITE_P2: begin
                    iWrite_reg   <= 1;
                    iRead_reg    <= 0;
                    writeAll_reg <= 1;
                    ADDR_EN_reg  <= 1;
                    ADDR_RST_reg <= 1;
                    gen_Turn_reg <= 4'hf; // Mẫu AAh từ Data Generator 
                    if (addr_counter < 127) addr_counter <= addr_counter + 1;
                    else begin
                        addr_counter <= 0;
                        ADDR_RST_reg <= 0;
                        state        <= READ_P2_INIT;
                    end
                end

                READ_P2_INIT: begin
                    iWrite_reg      <= 0;
                    iRead_reg       <= 1;
                    ADDR_RST_reg    <= 1;
                    memSel_reg      <= 2'b00;
                    rstComp_reg     <= 0;
                    state           <= CAPTURE_P2;
                end

                CAPTURE_P2: begin
                    captureData_reg <= 1;
                    compSel_reg     <= (4'b0001 << memSel_reg);
                    if (memSel_reg < 2'b11) memSel_reg <= memSel_reg + 1;
                    else state <= COMPARE_P2;
                end

                COMPARE_P2: begin
                    captureData_reg <= 0;
                    compare_EN_reg  <= 1;
                    state           <= RST_COMP_P2;
                end

                RST_COMP_P2: begin
                    compare_EN_reg  <= 0;
                    rstComp_reg     <= 1;
                    if (addr_counter < 127) begin
                        addr_counter <= addr_counter + 1;
                        state        <= READ_P2_INIT;
                    end else state <= DONE;
                end

                DONE: begin
                    iWrite_reg <= 0; iRead_reg <= 0;
                    compare_EN_reg <= 0; rstComp_reg <= 0;
                    cb_done <= 1;
                    state <= DONE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule