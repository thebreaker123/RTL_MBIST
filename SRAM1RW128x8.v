`timescale 1ns/100fs

`define numAddr 7
`define numWords 128
`define wordLength 8


module SRAM1RW128x8 (A,CE,WEB,OEB,CSB,I,O);

input                           CE;
input                           WEB;
input                           OEB;
input                           CSB;

input   [`numAddr-1:0]          A;
input   [`wordLength-1:0]       I;
output  [`wordLength-1:0]       O;

/*reg   [`wordLength-1:0]       memory[`numWords-1:0];*/
/*reg   [`wordLength-1:0]       data_out;*/
wire    [`wordLength-1:0]       O;

wire                            RE;
wire                            WE;

SRAM1RW128x8_1bit sram_IO0 ( CE, WEB,  A, OEB, CSB, I[0], O[0]);
SRAM1RW128x8_1bit sram_IO1 ( CE, WEB,  A, OEB, CSB, I[1], O[1]);
SRAM1RW128x8_1bit sram_IO2 ( CE, WEB,  A, OEB, CSB, I[2], O[2]);
SRAM1RW128x8_1bit sram_IO3 ( CE, WEB,  A, OEB, CSB, I[3], O[3]);
SRAM1RW128x8_1bit sram_IO4 ( CE, WEB,  A, OEB, CSB, I[4], O[4]);
SRAM1RW128x8_1bit sram_IO5 ( CE, WEB,  A, OEB, CSB, I[5], O[5]);
SRAM1RW128x8_1bit sram_IO6 ( CE, WEB,  A, OEB, CSB, I[6], O[6]);
SRAM1RW128x8_1bit sram_IO7 ( CE, WEB,  A, OEB, CSB, I[7], O[7]);


endmodule

module SRAM1RW128x8_1bit (CE_i, WEB_i,  A_i, OEB_i, CSB_i, I_i, O_i);

input CSB_i;
input OEB_i;
input CE_i;
input WEB_i;

input   [`numAddr-1:0]  A_i;
input   [0:0] I_i;

output  [0:0] O_i;

reg     [0:0]O_i;
reg     [0:0]   memory[`numWords-1:0];
reg     [0:0]   data_out;


// Write Mode
and u1 (RE, ~CSB_i,  WEB_i);
and u2 (WE, ~CSB_i, ~WEB_i);


always @ (posedge CE_i)
        if (RE)
                data_out = memory[A_i];
always @ (posedge CE_i)
        if (WE)
                memory[A_i] = I_i;


always @ (data_out or OEB_i)
        if (!OEB_i)
                O_i = data_out;
        else
                O_i =  1'bz;


endmodule

