`timescale 1ns/1ps

module checkerboard_tb();
    reg CLK;
    reg nRESET;
    reg mscan_en; // Giữ lại để khớp với cổng của topMbist
    reg cb_en;    // Tín hiệu kích hoạt Checkerboard

    // Khai báo các tín hiệu đầu ra từ DUT (Wire)
    wire [7:0] data_OUT;
    wire [7:0] W_addr;
    wire result_comp0, result_comp1, result_comp2, result_comp3;

    // Kết nối với module Top (DUT)
    // Lưu ý: Đảm bảo tên module và tên cổng khớp với file topMbist.v của bạn
    topMbist dut (
        .CLK(CLK),
        .nRESET(nRESET),
        .mscan_en(mscan_en), 
        .cb_en(cb_en),       // Cổng mới để chạy Checkerboard
        .data_OUT(data_OUT),
        .W_addr(W_addr),
        .result_comp0(result_comp0),
        .result_comp1(result_comp1),
        .result_comp2(result_comp2),
        .result_comp3(result_comp3)
    );

    always #10 CLK = ~CLK;
    initial begin 
        CLK = 0;
        nRESET = 0;
        mscan_en = 0;
        cb_en = 0;

        #100;
        nRESET = 1;
        #20;
        $display("---------------------------------------");
        $display("Starting CHECKERBOARD Algorithm Check...");
        $display("---------------------------------------");
        
        @(posedge CLK);
        cb_en = 1; // Kích hoạt Checkerboard
        #100000; 
        $display("---------------------------------------");
        $display("Checkerboard Test Done at time %t", $time);
        $display("---------------------------------------");
        
        #100;
        $finish;
    end

    initial begin
        $monitor("Time=%0t | Addr=%d | DataOut=%h | Result=%b%b%b%b", 
                 $time, W_addr, data_OUT, result_comp0, result_comp1, result_comp2, result_comp3);
    end
    initial begin
        $dumpfile("checkerboard_test.vcd");
        $dumpvars(0, checkerboard_tb);
    end

endmodule