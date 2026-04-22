module comparator (CLK, nRESET, rstComp ,dataMem, ExpDATA, RESULT, captureData, compSel, compare_EN);
    input wire CLK;
    input wire nRESET;
    input wire rstComp;

    input wire [7:0] dataMem;
    input wire [7:0] ExpDATA;
    input wire captureData;
    input wire compSel;
    input wire compare_EN;
    output wire RESULT;

    reg [7:0] dataComp;
    reg [7:0] exp_data;

    assign RESULT = (compare_EN & (dataComp == exp_data)) ? 1'b1 : 1'b0;


    always @(posedge CLK or negedge nRESET) begin
        if (!nRESET) begin
            dataComp <= 0;
            exp_data <= 0;
        end else if (rstComp) begin
            dataComp <= 0;
            exp_data <= 0;
        end else if (captureData && compSel) begin
            dataComp <= dataMem;
            exp_data <= ExpDATA;
        end
    end

endmodule