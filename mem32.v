`timescale 1ns/100fs
module mem (
        input        iClk,
        input  [7:0] iAddr,
        input        iWrite,
        input  [7:0] iWrData,
        input        iRead,
        output [7:0] oRdData
);

wire ram0_read, ram0_write;
wire ram1_read, ram1_write;
reg  ram_sel;
wire [7:0] ram0_rddata;
wire [7:0] ram1_rddata;

assign ram0_write = iWrite & ~iAddr[7];
assign ram1_write = iWrite &  iAddr[7];

assign ram0_read  = iRead  & ~iAddr[7];
assign ram1_read  = iRead  &  iAddr[7];

always@(posedge iClk) begin
        ram_sel <= ram1_read;
end
assign oRdData = (ram_sel) ? ram1_rddata : ram0_rddata;

wire sram0_csb = ~(ram0_read | ram0_write);
wire sram0_web = ~ram0_write;
wire sram0_oeb = ~ram0_read;

SRAM1RW128x8 singleRAM_32 (
    .CE     (iClk),
    .WEB    (sram0_web),
    .OEB    (sram0_oeb),
    .CSB    (sram0_csb),
    .A      (iAddr[6:0]),
    .I      (iWrData),
    .O      (ram0_rddata) 
);

wire sram1_csb1 = ~ram1_write; // Chanel 1: Kich hoat CS khi GHI
wire sram1_web1 = ~ram1_write; // Chanel 1: Kich hoat WE khi GHI
wire sram1_oeb1 = 1'b1;        // Chanel 1: Luon tat Output

wire sram1_csb2 = ~ram1_read;  // Chanel 2: Kich hoat CS khi  DOC
wire sram1_web2 = 1'b1;        // Chanel 2: Luon tat Write
wire sram1_oeb2 = ~ram1_read;  // Chenel 2: Kich hoat OE khi  DOC

SRAM2RW128x8 dualRAM_32 (
    //Chanel 1 ghi
    .A1     (iAddr[6:0]),
    .I1     (iWrData),
    .O1     (), // Ghi thi khong can dung output
    .CE1    (iClk),
    .CSB1   (sram1_csb1),
    .WEB1   (sram1_web1),
    .OEB1   (sram1_oeb1),
    
    //Chanel 2 doc
    .A2     (iAddr[6:0]),
    .I2     (), // Doc thi khong can dung input
    .O2     (ram1_rddata),
    .CE2    (iClk),
    .CSB2   (sram1_csb2),
    .WEB2   (sram1_web2),
    .OEB2   (sram1_oeb2)
        
);

endmodule

