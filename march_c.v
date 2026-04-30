module march_c(
    input wire CLK,
    input wire nRESET,
    input wire march_en,
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
    output reg march_done,
    output wire [7:0] march_addr
);

    // Định nghĩa các trạng thái FSM
    localparam IDLE          = 4'd0,
               M1_WRITE      = 4'd1, 
               READ_INIT     = 4'd2, 
               CAPTURE       = 4'd3, 
               COMPARE       = 4'd4, 
               RST_COMP      = 4'd5, 
               WRITE_ACTION  = 4'd6,
               WRITE_WAIT    = 4'd7,
               NEXT_ADDR     = 4'd8,
               DONE_STATE    = 4'd9,
               WRITE_DONE    = 4'd10; // Đã thêm trạng thái hoàn tất ghi

    reg [3:0] state;
    reg [7:0] addr_counter;
    reg [2:0] march_step; // Đếm từ 1 đến 6 (Tương ứng M1 đến M6)

    // --- LOGIC ĐIỀU HƯỚNG THEO 6 BƯỚC CỦA MARCH C- ---
    wire expected_data_is_1 = (march_step == 3'd3) || (march_step == 3'd5);
    wire write_data_is_1    = (march_step == 3'd2) || (march_step == 3'd4);
    wire is_down_dir        = (march_step == 3'd4) || (march_step == 3'd5);

    // Quy ước: 1 là 00h, 3 là FFh
    wire [3:0] turn_read  = expected_data_is_1 ? 4'd3 : 4'd1; 
    wire [3:0] turn_write = write_data_is_1    ? 4'd3 : 4'd1;

    assign march_addr = addr_counter; // Xuất địa chỉ ra ngoài

    always @(posedge CLK or negedge nRESET) begin
        if (!nRESET) begin
            state <= IDLE;
            addr_counter <= 0;
            march_step <= 0;
            {iWrite_reg, iRead_reg, writeAll_reg, march_done} <= 4'b0000;
            {DATA_EN_reg, ADDR_EN_reg, ADDR_RST_reg} <= 3'b000;
            {compare_EN_reg, captureData_reg, rstComp_reg} <= 3'b000;
            compSel_reg <= 4'b0000; memSel_reg <= 2'b00; PAT_SEL_reg <= 3'd0; 
        end else if (march_en) begin
            case (state)
                IDLE: begin
                    ADDR_RST_reg <= 1; DATA_EN_reg <= 1;
                    addr_counter <= 0; march_step <= 1; march_done <= 0;
                    PAT_SEL_reg  <= 3'd0;
                    state        <= M1_WRITE;
                end

                // --- Bước M1: Quét xuôi, Ghi 0 vào toàn bộ ---
                M1_WRITE: begin
                    iWrite_reg   <= 1; iRead_reg <= 0; writeAll_reg <= 1; 
                    ADDR_EN_reg  <= 1; ADDR_RST_reg <= 0; 
                    gen_Turn_reg <= 4'd1; 
                    
                    if (addr_counter < 127) begin
                        addr_counter <= addr_counter + 1;
                    end else begin
                        addr_counter <= 0; 
                        march_step   <= 2; 
                        state        <= READ_INIT;
                    end
                end

                // --- Chu trình Đọc tuần tự 4 Bank ---
                READ_INIT: begin
                    iWrite_reg <= 0; iRead_reg <= 1; 
                    ADDR_EN_reg <= 0; memSel_reg <= 2'b00; rstComp_reg <= 1;
                    gen_Turn_reg <= turn_read; 
                    state <= CAPTURE;
                end

                CAPTURE: begin
                    rstComp_reg <= 0; captureData_reg <= 1; 
                    compSel_reg <= (4'b0001 << memSel_reg); 
                    if (memSel_reg < 2'b11) memSel_reg <= memSel_reg + 1;
                    else state <= COMPARE;
                end

                COMPARE: begin
                    captureData_reg <= 0; compare_EN_reg <= 1; 
                    state <= RST_COMP;
                end

                RST_COMP: begin
                    compare_EN_reg <= 0; rstComp_reg <= 1; 
                    if (march_step == 6) begin
                        state <= NEXT_ADDR; 
                    end else begin
                        // Nạp dữ liệu lên bus trước khi phát lệnh ghi
                        gen_Turn_reg <= turn_write; 
                        state <= WRITE_ACTION;              
                    end
                end

                // --- Lệnh Ghi Đè Ổn Định ---
                WRITE_ACTION: begin
                    iWrite_reg   <= 1; iRead_reg <= 0; writeAll_reg <= 1;
                    state        <= WRITE_WAIT;
                end

                WRITE_WAIT: begin
                    // Giữ nguyên iWrite=1 thêm 1 chu kỳ để RAM chắc chắn lưu thành công
                    state      <= WRITE_DONE;
                end

                WRITE_DONE: begin
                    iWrite_reg   <= 0; // Tắt lệnh ghi
                    writeAll_reg <= 0; 
                    state        <= NEXT_ADDR;
                end

                // --- Logic Tăng/Giảm Địa Chỉ & Chuyển Bước ---
                NEXT_ADDR: begin
                    if (!is_down_dir) begin 
                        // QUÉT XUÔI
                        if (addr_counter < 127) begin
                            addr_counter <= addr_counter + 1;
                            ADDR_EN_reg  <= 1;
                            state <= READ_INIT;
                        end else begin
                            march_step <= march_step + 1;
                            if (march_step == 2) addr_counter <= 0;        
                            else if (march_step == 3) addr_counter <= 127; 
                            else if (march_step == 6) state <= DONE_STATE; 
                            state <= (march_step == 6) ? DONE_STATE : READ_INIT;
                        end
                    end else begin 
                        // QUÉT NGƯỢC
                        if (addr_counter > 0) begin
                            addr_counter <= addr_counter - 1;
                            ADDR_EN_reg  <= 1;
                            state <= READ_INIT;
                        end else begin
                            march_step <= march_step + 1;
                            if (march_step == 4) addr_counter <= 127; 
                            else if (march_step == 5) addr_counter <= 0; 
                            state <= READ_INIT;
                        end
                    end
                end

                DONE_STATE: begin
                    iWrite_reg <= 0; iRead_reg <= 0; compare_EN_reg <= 0; rstComp_reg <= 0;
                    march_done <= 1; state <= DONE_STATE;
                end
            endcase
        end
    end
endmodule