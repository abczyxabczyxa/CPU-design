module PC_Reg(
    input wire clk,
    input wire rst,
    input wire pc_br_taken,
    input wire [31:0] pc_br_target,
    output reg [31:0] if_pc,
    output wire inst_en,
    output wire [31:0] inst_addr
);
    reg [31:0] if_pc;
    wire [31:0]nextpc;
    assign inst_en = rst? 1'b0 : 1'b1;
    assign nextpc =pc_br_taken? pc_br_target: if_pc+4;
    assign inst_addr=nextpc;
    always @(posedge clk)
    begin
        if(inst_en==0)
        begin
            if_pc<=32'h1bfffffc;
        end
        else
        begin
            if_pc<=nextpc;
        end
    end
endmodule