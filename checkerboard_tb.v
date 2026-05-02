`timescale 1ns/1ps

module checkerboard_tb();
    reg CLK;
    reg nRESET;
    reg mscan_en; 
    reg cb_en;
    reg march_en; // FIX 1: Khai báo thêm chân march_en

    // Khai báo đầu ra từ module Top
    wire [7:0] W_addr;
    wire result_comp0, result_comp1, result_comp2, result_comp3; 

    // Kết nối với module Top (DUT)
    topMbist dut (
        .CLK(CLK),
        .nRESET(nRESET),
        .mscan_en(mscan_en), 
        .cb_en(cb_en),
        .march_en(march_en), // FIX 2: Nối chân march_en vào module Top
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
        mscan_en = 0; 
        cb_en = 0; 
        march_en = 0; // FIX 3: Khởi tạo giá trị 0 để tránh lỗi Z/X

        #100 nRESET = 1;
        // Nhả Reset
        #40;
        
        $display("---------------------------------------");
        $display("BAT DAU CHAY CHECKERBOARD");
        $display("---------------------------------------");

        // 2. Kích hoạt thuật toán
        @(posedge CLK); 
        cb_en = 1;

        // 3. Đợi thuật toán chạy xong 
        #100000;
        
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