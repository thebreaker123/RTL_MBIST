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
    output reg cb_done,
    output wire [7:0] cb_addr // Cổng mới: Xuất trực tiếp addr_counter ra ngoài
);

    // Định nghĩa các trạng thái FSM (Giữ nguyên cấu trúc nguyên bản)
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
                    ADDR_RST_reg <= 1; // Đảm bảo mạch đếm địa chỉ reset về 0
                    DATA_EN_reg  <= 1;
                    addr_counter <= 0;
                    cb_done      <= 0;
                    state        <= WRITE_P1;
                end

                // --- GIAI ĐOẠN 1: Ghi 55h (QUÉT XUÔI 0 -> 127) ---
                WRITE_P1: begin
                    iWrite_reg   <= 1;
                    iRead_reg    <= 0; 
                    writeAll_reg <= 1; 
                    ADDR_EN_reg  <= 1; // Bật liên tục để quét nhanh
                    ADDR_RST_reg <= 0; 
                    gen_Turn_reg <= 4'h0; // Mẫu 55h 
                    
                    if (addr_counter < 127) begin
                        addr_counter <= addr_counter + 1;
                    end else begin
                        addr_counter <= 0;
                        ADDR_RST_reg <= 1; // Chớp Reset để quay về địa chỉ 0 cho khâu Đọc
                        state        <= READ_P1_INIT;
                    end
                end

                // --- GIAI ĐOẠN 2: Đọc 55h (Cấu trúc so sánh 4 bước) ---
                READ_P1_INIT: begin
                    iWrite_reg      <= 0; 
                    iRead_reg       <= 1; 
                    ADDR_RST_reg    <= 0; // Tắt reset để bắt đầu đếm
                    ADDR_EN_reg     <= 0; // TẮT EN ĐỂ GIỮ ĐỊA CHỈ TRONG 4 NHỊP ĐỌC
                    memSel_reg      <= 2'b00;
                    rstComp_reg     <= 1; // GIỮ LẠI RESET Ở ĐÂY ĐỂ TRÁNH GLITCH (Vạch đỏ)
                    compare_EN_reg  <= 0;
                    state           <= CAPTURE_P1;
                end

                CAPTURE_P1: begin
                    rstComp_reg     <= 0; // TỚI ĐÂY MỚI NHẢ RESET (Dữ liệu đã sạch)
                    captureData_reg <= 1; 
                    compSel_reg     <= (4'b0001 << memSel_reg); 
                    if (memSel_reg < 2'b11) memSel_reg <= memSel_reg + 1;
                    else state <= COMPARE_P1;
                end

                COMPARE_P1: begin
                    captureData_reg <= 0;
                    compare_EN_reg  <= 1; 
                    state           <= RST_COMP_P1;
                end

                RST_COMP_P1: begin
                    compare_EN_reg  <= 0;
                    rstComp_reg     <= 1; 
                    if (addr_counter < 127) begin
                        addr_counter <= addr_counter + 1;
                        ADDR_EN_reg  <= 1; // Kích 1 nhịp để nhảy sang địa chỉ tiếp theo
                        state        <= READ_P1_INIT;
                    end else begin
                        addr_counter <= 127; // Giữ ở đỉnh 127 để chuẩn bị Quét Ngược
                        state        <= WRITE_P2;
                    end
                end

                // --- GIAI ĐOẠN 3: Ghi AAh (QUÉT NGƯỢC 127 -> 0) ---
                WRITE_P2: begin
                    iWrite_reg   <= 1;
                    iRead_reg    <= 0;
                    writeAll_reg <= 1;
                    ADDR_EN_reg  <= 1;
                    ADDR_RST_reg <= 0; // Không reset, ta đang muốn đếm lùi
                    gen_Turn_reg <= 4'hf; // Mẫu AAh 
                    
                    if (addr_counter > 0) begin
                        addr_counter <= addr_counter - 1; // ĐẾM LÙI
                    end else begin
                        addr_counter <= 127; // Quay lại đỉnh 127 để Đọc lùi
                        state        <= READ_P2_INIT;
                    end
                end

                // --- GIAI ĐOẠN 4: Đọc AAh (Quét ngược) ---
                READ_P2_INIT: begin
                    iWrite_reg      <= 0;
                    iRead_reg       <= 1;
                    ADDR_RST_reg    <= 0;
                    ADDR_EN_reg     <= 0; // Giữ địa chỉ
                    memSel_reg      <= 2'b00;
                    rstComp_reg     <= 1; // GIỮ LẠI RESET ĐỂ TRÁNH GLITCH
                    state           <= CAPTURE_P2;
                end

                CAPTURE_P2: begin
                    rstComp_reg     <= 0; // NHẢ RESET
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
                    if (addr_counter > 0) begin
                        addr_counter <= addr_counter - 1; // ĐẾM LÙI
                        ADDR_EN_reg  <= 1; // Nhảy địa chỉ
                        state        <= READ_P2_INIT;
                    end else state <= DONE;
                end

                DONE: begin
                    iWrite_reg <= 0; iRead_reg <= 0;
                    compare_EN_reg <= 0; rstComp_reg <= 0; ADDR_EN_reg <= 0;
                    cb_done <= 1;
                    state <= DONE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

    // Gán giá trị bộ đếm nội bộ ra cổng cb_addr để cấp trực tiếp cho hệ thống
    assign cb_addr = addr_counter;

endmodule