module comparator (
    input wire CLK,
    input wire nRESET,
    input wire rstComp,
    input wire [7:0] dataMem,
    input wire [7:0] ExpDATA,
    input wire captureData,
    input wire compSel,
    input wire compare_EN,
    output reg RESULT // Chuyển thành reg để chốt giá trị
);

    reg [7:0] dataComp;
    reg [7:0] exp_data;

    // Khối điều khiển nạp dữ liệu và reset (Giữ nguyên logic cũ của bạn)
    always @(posedge CLK or negedge nRESET) begin
        if (!nRESET) begin
            dataComp <= 8'b0;
            exp_data <= 8'b0;
            RESULT   <= 1'b0; // Đảm bảo không bị đỏ (StX) khi mới bắt đầu
        end else if (rstComp) begin
            dataComp <= 8'b0;
            exp_data <= 8'b0;
            RESULT   <= 1'b0; // Reset kết quả về 0 sau mỗi lần so sánh xong
        end else begin
            // Bước 1: Nạp dữ liệu vào thanh ghi đệm
            if (captureData && compSel) begin
                dataComp <= dataMem;
                exp_data <= ExpDATA;
            end
            
            // Bước 2: Chốt kết quả so sánh khi có lệnh cho phép
            if (compare_EN && compSel) begin
                RESULT <= (dataComp == exp_data);
            end
        end
    end

endmodule