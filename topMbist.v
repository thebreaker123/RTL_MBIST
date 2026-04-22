// `timescale 1ns/1ps
module topMbist(
    input wire CLK,
    input wire nRESET,
    input wire mscan_en,   // Kích hoạt thuật toán MSCAN
    input wire cb_en,      // Kích hoạt thuật toán Checkerboard
    output wire [7:0] data_OUT,
    output wire [7:0] W_addr,
    output wire result_comp0,
    output wire result_comp1,
    output wire result_comp2,
    output wire result_comp3
);

    // --- Tín hiệu điều khiển sau MUX (Dùng chung cho hệ thống) ---
    wire iWrite_ctrl, iRead_ctrl, writeAll_ctrl;
    wire DATA_EN_ctrl, ADDR_EN_ctrl, ADDR_RST_ctrl;
    wire compare_EN_ctrl, captureData_ctrl, rstComp_ctrl;
    wire [1:0] memSel_ctrl;
    wire [3:0] compSel_ctrl, gen_Turn_ctrl;
    wire [2:0] PAT_SEL_ctrl;
    wire [7:0] W_data_bus, expData_bus;

    // --- Tín hiệu điều khiển nội bộ từ MSCAN ---
    wire iw_m, ir_m, wa_m, de_m, ae_m, ar_m, ce_m, cd_m, rc_m;
    wire [1:0] ms_m;
    wire [3:0] cs_m, gt_m;
    wire [2:0] ps_m;

    // --- Tín hiệu điều khiển nội bộ từ Checkerboard ---
    wire iw_c, ir_c, wa_c, de_c, ae_c, ar_c, ce_c, cd_c, rc_c;
    wire [1:0] ms_c;
    wire [3:0] cs_c, gt_c;
    wire [2:0] ps_c;

    // 1. Khối điều khiển MSCAN (MSCAN Controller)
    mscan u_mscan (
        .CLK(CLK), .nRESET(nRESET), .algr_en(mscan_en),
        .iWrite_reg(iw_m), .iRead_reg(ir_m), .memSel_reg(ms_m),
        .writeAll_reg(wa_m), .DATA_EN_reg(de_m), .ADDR_EN_reg(ae_m),
        .ADDR_RST_reg(ar_m), .gen_Turn_reg(gt_m), .PAT_SEL_reg(ps_m),
        .compare_EN_reg(ce_m), .captureData_reg(cd_m), .compSel_reg(cs_m), .rstComp_reg(rc_m)
    );

    // 2. Khối điều khiển Checkerboard (Checkerboard Controller)
    checkerboard u_checkerboard (
        .CLK(CLK), .nRESET(nRESET), .cb_en(cb_en),
        .iWrite_reg(iw_c), .iRead_reg(ir_c), .memSel_reg(ms_c),
        .writeAll_reg(wa_c), .DATA_EN_reg(de_c), .ADDR_EN_reg(ae_c),
        .ADDR_RST_reg(ar_c), .gen_Turn_reg(gt_c), .PAT_SEL_reg(ps_c),
        .compare_EN_reg(ce_c), .captureData_reg(cd_c), .compSel_reg(cs_c), .rstComp_reg(rc_c)
    );

    // 3. Hệ thống MUX (Algorithm Checker)
    // Ưu tiên Checkerboard nếu cb_en = 1, nếu không sẽ chạy MSCAN
    assign iWrite_ctrl      = (cb_en) ? iw_c : (mscan_en ? iw_m : 1'b0);
    assign iRead_ctrl       = (cb_en) ? ir_c : (mscan_en ? ir_m : 1'b0);
    assign memSel_ctrl      = (cb_en) ? ms_c : (mscan_en ? ms_m : 2'b00);
    assign writeAll_ctrl    = (cb_en) ? wa_c : (mscan_en ? wa_m : 1'b0);
    assign DATA_EN_ctrl     = (cb_en) ? de_c : (mscan_en ? de_m : 1'b0);
    assign ADDR_EN_ctrl     = (cb_en) ? ae_c : (mscan_en ? ae_m : 1'b0);
    assign ADDR_RST_ctrl    = (cb_en) ? ar_c : (mscan_en ? ar_m : 1'b1);
    assign gen_Turn_ctrl    = (cb_en) ? gt_c : (mscan_en ? gt_m : 4'd0);
    assign PAT_SEL_ctrl     = (cb_en) ? ps_c : (mscan_en ? ps_m : 3'd0);
    assign compare_EN_ctrl  = (cb_en) ? ce_c : (mscan_en ? ce_m : 1'b0);
    assign captureData_ctrl = (cb_en) ? cd_c : (mscan_en ? cd_m : 1'b0);
    assign compSel_ctrl     = (cb_en) ? cs_c : (mscan_en ? cs_m : 4'b0000);
    assign rstComp_ctrl     = (cb_en) ? rc_c : (mscan_en ? rc_m : 1'b0);

    addr_gen u_addr_gen (
        .CLK(CLK), .nRESET(nRESET), .ADDR_EN(ADDR_EN_ctrl), 
        .ADDR_RST(ADDR_RST_ctrl), .gen_Turn(gen_Turn_ctrl), 
        .PAT_SEL(PAT_SEL_ctrl), .ADDR_MBIST(W_addr)
    );

    data_gen u_data_gen (
        .CLK(CLK), .nRESET(nRESET), .DATA_EN(DATA_EN_ctrl), 
        .gen_Turn(gen_Turn_ctrl), .PAT_SEL(PAT_SEL_ctrl), 
        .DATA_MBIST(W_data_bus), .DATA_comp(expData_bus)
    );

    memBank u_memBank (
        .iClk(CLK), .iAddr(W_addr), .iWrite(iWrite_ctrl), 
        .iWrData(W_data_bus), .iRead(iRead_ctrl), .memSel(memSel_ctrl), 
        .writeAll(writeAll_ctrl), .data_OUT(data_OUT)
    );


    comparator u_c0 (.CLK(CLK), .nRESET(nRESET), .rstComp(rstComp_ctrl), .dataMem(data_OUT), .ExpDATA(expData_bus), .RESULT(result_comp0), .captureData(captureData_ctrl), .compSel(compSel_ctrl[0]), .compare_EN(compare_EN_ctrl));
    comparator u_c1 (.CLK(CLK), .nRESET(nRESET), .rstComp(rstComp_ctrl), .dataMem(data_OUT), .ExpDATA(expData_bus), .RESULT(result_comp1), .captureData(captureData_ctrl), .compSel(compSel_ctrl[1]), .compare_EN(compare_EN_ctrl));
    comparator u_c2 (.CLK(CLK), .nRESET(nRESET), .rstComp(rstComp_ctrl), .dataMem(data_OUT), .ExpDATA(expData_bus), .RESULT(result_comp2), .captureData(captureData_ctrl), .compSel(compSel_ctrl[2]), .compare_EN(compare_EN_ctrl));
    comparator u_c3 (.CLK(CLK), .nRESET(nRESET), .rstComp(rstComp_ctrl), .dataMem(data_OUT), .ExpDATA(expData_bus), .RESULT(result_comp3), .captureData(captureData_ctrl), .compSel(compSel_ctrl[3]), .compare_EN(compare_EN_ctrl));

endmodule