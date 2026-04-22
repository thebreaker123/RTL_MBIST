`timescale 1ns/1ps
module mscan_tb();
    reg CLK;
    reg nRESET;
    reg algr_en;


    wire result_comp0, result_comp1, result_comp2, result_comp3;

    wire [7:0] data_OUT;
    wire [7:0] W_addr;
wrapMbist dut (
    .CLK(CLK),
    .nRESET(nRESET),
    .algr_en(algr_en),
    .data_OUT(data_OUT),
    .W_addr(W_addr),
    .result_comp0(result_comp0),
    .result_comp1(result_comp1),
    .result_comp2(result_comp2),
    .result_comp3(result_comp3)
);

initial begin 
    CLK = 0;
    nRESET = 0;
    algr_en = 0;
end


always #10 CLK = ~CLK;

initial begin 
    #100;
    nRESET = 1;
    #20;
  $display("Starting MSCAN check...");   
    @(posedge CLK);
    algr_en = 1; // Bắt đầu thuật toán MSCAN
    
    #50000;
    $display("Test done");
    #100;
    $finish;
end

initial begin
    $monitor("Time: %0t | W_addr: %d | result_comp0: %b | result_comp1: %b | result_comp2: %b | result_comp3: %b", $time, W_addr, result_comp0, result_comp1, result_comp2, result_comp3);
end

endmodule