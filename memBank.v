module memBank (    input        iClk,
                    input  [7:0] iAddr,
                    input        iWrite,
                    input  [7:0] iWrData,
                    input        iRead,
                    input  [1:0] memSel,
                    input        writeAll,
                    output [7:0] data_OUT);

wire [7:0] dataMem0, dataMem1, dataMem2, dataMem3;
wire enableWrite0, enableWrite1, enableWrite2, enableWrite3;

assign data_OUT =   (iRead & ~memSel[0] & ~memSel[1]) ? dataMem0 :
                    (iRead &  memSel[0] & ~memSel[1]) ? dataMem1 :
                    (iRead & ~memSel[0] &  memSel[1]) ? dataMem2 : 
                    (iRead &  memSel[0] &  memSel[1]) ? dataMem3 : 8'b0;

assign enableWrite0 = (iWrite & ~memSel[0] & ~memSel[1]) | (iWrite & writeAll);
assign enableWrite1 = (iWrite &  memSel[0] & ~memSel[1]) | (iWrite & writeAll);
assign enableWrite2 = (iWrite & ~memSel[0] &  memSel[1]) | (iWrite & writeAll);
assign enableWrite3 = (iWrite &  memSel[0] &  memSel[1]) | (iWrite & writeAll);

mem mem0 (
    .iClk   (iClk),
    .iAddr  (iAddr),
    .iWrite (enableWrite0),
    .iWrData(iWrData),
    .iRead  (iRead),
    .oRdData(dataMem0)
);

mem mem1 (
    .iClk   (iClk),
    .iAddr  (iAddr),
    .iWrite (enableWrite1),
    .iWrData(iWrData),
    .iRead  (iRead),
    .oRdData(dataMem1)
);

mem mem2 (
    .iClk   (iClk),
    .iAddr  (iAddr),
    .iWrite (enableWrite2),
    .iWrData(iWrData),
    .iRead  (iRead),
    .oRdData(dataMem2)
);

mem mem3 (
    .iClk   (iClk),
    .iAddr  (iAddr),
    .iWrite (enableWrite3),
    .iWrData(iWrData),
    .iRead  (iRead),
    .oRdData(dataMem3)
);

endmodule