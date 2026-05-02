`timescale 1ns/1ps

module march_c_tb();
    reg CLK;
    reg nRESET;
    reg mscan_en; 
    reg cb_en; 
    reg march_en;

    // Khai báo đầu ra từ module Top
    wire [7:0] W_addr;
    wire result_comp0, result_comp1, result_comp2, result_comp3; 

    // Kết nối với module Top (DUT)
    topMbist dut (
        .CLK(CLK),
        .nRESET(nRESET),
        .mscan_en(mscan_en), 
        .cb_en(cb_en),
        .march_en(march_en), 
        .W_addr(W_addr), 
        .result_comp0(result_comp0), 
        .result_comp1(result_comp1), 
        .result_comp2(result_comp2), 
        .result_comp3(result_comp3) 
    );

    // Tạo xung Clock (Chu kỳ 20ns)
    always #10 CLK = ~CLK;

    initial begin 
        // 1. Khởi tạo
        CLK = 0;
        nRESET = 0; 
        mscan_en = 0; cb_en = 0; march_en = 0; 

        #100 nRESET = 1; // Nhả Reset 
        #40;
        
        $display("---------------------------------------------------------");
        $display("BAT DAU CHAY MARCH-CHECKERBOARD (DETECT NPSF & COUPLING)");
        $display("---------------------------------------------------------");

        // 2. Kích hoạt thuật toán
        @(posedge CLK); 
        march_en = 1; // Kích hoạt FSM đã được nâng cấp

        // 3. Đợi thuật toán chạy xong 
        // Vẫn giữ thời gian chờ 150,000ns để FSM hoàn tất 6 bước (M1->M6) trên 128 địa chỉ
        #150000;
        
        $display("---------------------------------------------------------");
        $display("KET THUC MO PHONG TAI THOI DIEM %t", $time); 
        $display("---------------------------------------------------------");
        
        #100 $stop;
    end

    // Màn hình Console theo dõi
    initial begin
        // Thêm định dạng tab (\t) để dễ nhìn hơn trên Console
        $monitor("Time=%0t \t| Addr=%d \t| Comp(Bank 3-0)=%b%b%b%b", 
                 $time, W_addr, result_comp3, result_comp2, result_comp1, result_comp0);
    end

endmodule