module ID_Reg (
    input wire clk,
    input wire rst,
    input wire [31:0] if_pc,
    input wire [31:0] if_inst,
    output reg [31:0] id_pc,
    output reg [31:0] id_inst
);
    always @(posedge clk)
    begin
        if(rst)
        begin
            id_pc<=32'h1bfffffc;
            id_inst<=32'h0;
        end
        else
        begin
            id_pc<=if_pc;
            id_inst<=if_inst;
        end
    end
endmodule