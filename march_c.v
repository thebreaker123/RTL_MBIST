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

    // FSM States
    localparam IDLE          = 4'd0,
               M0_WRITE      = 4'd1, 
               READ_INIT     = 4'd2, 
               CAPTURE       = 4'd3, 
               COMPARE       = 4'd4, 
               RST_COMP      = 4'd5, 
               WRITE_ACTION  = 4'd6,
               WRITE_WAIT    = 4'd7,
               WRITE_DONE    = 4'd10,
               NEXT_ADDR     = 4'd8,
               DONE_STATE    = 4'd9;

    reg [3:0] state;
    reg [7:0] addr_counter;
    reg [2:0] march_step; // Theo dõi 7 bước của March C (11N)

    // --- LOGIC ĐIỀU HƯỚNG 11N MARCH C ---
    // M2 (r1,w0), M5 (r1,w0) kỳ vọng đọc 1. Các bước M1, M3, M4, M6 kỳ vọng đọc 0.
    wire expected_data_is_1 = (march_step == 3'd2) || (march_step == 3'd5);
    
    // Các bước có hành động ghi đè: M1, M2, M4, M5. (M3 và M6 chỉ đọc để kiểm tra)
    wire has_write_action   = (march_step == 3'd1) || (march_step == 3'd2) || 
                              (march_step == 3'd4) || (march_step == 3'd5);
    
    // M1 (r0,w1), M4 (r0,w1) ghi mức 1. M2, M5 ghi mức 0.
    wire write_data_is_1    = (march_step == 3'd1) || (march_step == 3'd4);
    
    // M4, M5 quét ngược (DOWN). Còn lại quét xuôi (UP).
    wire is_down_dir        = (march_step == 3'd4) || (march_step == 3'd5);

    // Turn 1 tương ứng 00h, Turn 3 tương ứng FFh
    wire [3:0] turn_read  = expected_data_is_1 ? 4'd3 : 4'd1; 
    wire [3:0] turn_write = write_data_is_1    ? 4'd3 : 4'd1;

    assign march_addr = addr_counter;

    always @(posedge CLK or negedge nRESET) begin
        if (!nRESET) begin
            state <= IDLE; addr_counter <= 0; march_step <= 0;
            {iWrite_reg, iRead_reg, writeAll_reg, march_done} <= 4'b0000;
            {DATA_EN_reg, ADDR_EN_reg, ADDR_RST_reg} <= 3'b000;
            {compare_EN_reg, captureData_reg, rstComp_reg} <= 3'b000;
            compSel_reg <= 4'b0000; memSel_reg <= 2'b00; PAT_SEL_reg <= 3'd0; 
        end else if (march_en) begin
            case (state)
                IDLE: begin
                    ADDR_RST_reg <= 1; DATA_EN_reg <= 1;
                    addr_counter <= 0; march_step <= 0; march_done <= 0;
                    PAT_SEL_reg  <= 3'd0; // Nền Solid kiểm tra SAF/TF
                    state        <= M0_WRITE;
                end

                // M0: Khởi tạo toàn bộ RAM mức 0
                M0_WRITE: begin
                    iWrite_reg <= 1; iRead_reg <= 0; writeAll_reg <= 1; 
                    ADDR_EN_reg <= 1; ADDR_RST_reg <= 0; gen_Turn_reg <= 4'd1; 
                    if (addr_counter < 127) addr_counter <= addr_counter + 1;
                    else begin
                        addr_counter <= 0; march_step <= 1; state <= READ_INIT;
                    end
                end

                READ_INIT: begin
                    iWrite_reg <= 0; iRead_reg <= 1; ADDR_EN_reg <= 0; 
                    memSel_reg <= 2'b00; rstComp_reg <= 1; gen_Turn_reg <= turn_read; 
                    state <= CAPTURE;
                end

                CAPTURE: begin
                    rstComp_reg <= 0; captureData_reg <= 1; 
                    compSel_reg <= (4'b0001 << memSel_reg); // Lần lượt nạp dữ liệu từ 4 bank
                    if (memSel_reg < 2'b11) memSel_reg <= memSel_reg + 1;
                    else state <= COMPARE;
                end

                COMPARE: begin
                    captureData_reg <= 0; 
                    compare_EN_reg  <= 1; 
                    // FIX: Bật đồng loạt 4 Bank để chân result_comp sáng đều cùng lúc
                    compSel_reg     <= 4'b1111; 
                    state           <= RST_COMP;
                end

                RST_COMP: begin
                    compare_EN_reg <= 0; rstComp_reg <= 1; 
                    if (has_write_action) begin
                        // Nạp trước dữ liệu ghi để tránh lỗi Setup Time
                        gen_Turn_reg <= turn_write; 
                        state <= WRITE_ACTION;
                    end else state <= NEXT_ADDR; // M3 và M6 không ghi đè, nhảy luôn sang NEXT_ADDR
                end

                WRITE_ACTION: begin
                    iWrite_reg <= 1; iRead_reg <= 0; writeAll_reg <= 1;
                    state <= WRITE_WAIT;
                end

                WRITE_WAIT: begin
                    state <= WRITE_DONE; // Chờ RAM ổn định
                end

                WRITE_DONE: begin
                    iWrite_reg <= 0; writeAll_reg <= 0; state <= NEXT_ADDR;
                end

                NEXT_ADDR: begin
                    if (!is_down_dir) begin // Hướng quét XUÔI
                        if (addr_counter < 127) begin
                            addr_counter <= addr_counter + 1; ADDR_EN_reg <= 1; state <= READ_INIT;
                        end else begin
                            march_step <= march_step + 1;
                            // Chuẩn bị địa chỉ: Sau M3 (xuôi) là M4 (ngược) nên mốc bắt đầu phải là 127
                            addr_counter <= (march_step == 3) ? 127 : 0;
                            state <= (march_step == 6) ? DONE_STATE : READ_INIT;
                        end
                    end else begin // Hướng quét NGƯỢC
                        if (addr_counter > 0) begin
                            addr_counter <= addr_counter - 1; ADDR_EN_reg <= 1; state <= READ_INIT;
                        end else begin
                            march_step <= march_step + 1;
                            // Chuẩn bị địa chỉ: Sau M4 (ngược) là M5 (ngược) -> bắt đầu 127. M5 sang M6 (xuôi) -> 0.
                            addr_counter <= (march_step == 4) ? 127 : 0;
                            state <= READ_INIT;
                        end
                    end
                end

                DONE_STATE: begin
                    iWrite_reg <= 0; iRead_reg <= 0; compare_EN_reg <= 0; rstComp_reg <= 0;
                    march_done <= 1; state <= DONE_STATE; // Hoàn tất bài test
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule