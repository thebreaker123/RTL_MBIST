`timescale 1ns/1ps

module march_c_tb();
    reg CLK;
    reg nRESET;
    reg mscan_en; 
    reg cb_en; 
    reg march_en; // Khai báo thêm biến điều khiển March C-

    // Khai báo đầu ra từ module Top (Đã bỏ data_OUT chung để dùng 4 đường song song)
    wire [7:0] W_addr; 
    wire result_comp0, result_comp1, result_comp2, result_comp3; 

    // Kết nối với module Top (DUT)
    topMbist dut (
        .CLK(CLK),
        .nRESET(nRESET),
        .mscan_en(mscan_en), 
        .cb_en(cb_en),
        .march_en(march_en), // Kết nối tín hiệu March C-
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
        CLK = 0; nRESET = 0; 
        mscan_en = 0; cb_en = 0; march_en = 0; 

        #100 nRESET = 1; // Nhả Reset 
        #40;
        
        $display("---------------------------------------");
        $display("BAT DAU CHAY MARCH C- (FULL COVERAGE)");
        $display("---------------------------------------");

        // 2. Kích hoạt thuật toán
        @(posedge CLK); 
        march_en = 1; // Kích hoạt chạy March C-

        // 3. Đợi thuật toán chạy xong 
        // March C- có 6 bước (M1->M6) quét qua 128 địa chỉ nên cần khoảng 120,000ns - 150,000ns
        #150000; 
        
        $display("---------------------------------------");
        $display("KET THUC MO PHONG TAI THOI DIEM %t", $time); 
        $display("---------------------------------------");
        
        #100 $stop; 
    end

    // Màn hình Console theo dõi
    initial begin
        $monitor("Time=%0t | Addr=%d | Comp(3210)=%b%b%b%b", 
                 $time, W_addr, result_comp3, result_comp2, result_comp1, result_comp0);
    end

endmodule