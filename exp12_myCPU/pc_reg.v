module PC_Reg(
    input wire clk,
    input wire rst,
    input wire wb_ready_go,
    input wire pc_br_taken,
    input wire [31:0] pc_br_target,
    output reg [31:0] if_pc,
    output wire inst_en,
    output reg [31:0] inst_addr
);
    
    reg [31:0]nextpc;
    assign inst_en = rst? 1'b0 : 1'b1;
    
   // assign nextpc =pc_br_taken? pc_br_target: if_pc+4;
    always @(*) begin
    casez (pc_br_taken)
        1'b1: nextpc = pc_br_target;
        default: nextpc = if_pc + 4;  // 包含 1'b0�?1'bx�?1'bz
    endcase
    end
    
    //assign inst_addr=nextpc;

    always @(*) begin
    casez (wb_ready_go)
        1'b0: inst_addr = if_pc;
        default: inst_addr = nextpc;  // 包含 1'b1�?1'bx�?1'bz
    endcase
    end
    
    always @(posedge clk) begin
    if (inst_en == 0) begin
        if_pc <= 32'h1bfffffc;
    end
    else begin
        casez (wb_ready_go)
            1'b1: if_pc <= nextpc;   // 正常情况下更�?
            1'b0: if_pc <= if_pc;    // 不就绪时保持
            default: if_pc <= nextpc; // wb_ready_go �? x/z 时，更新
        endcase
    end
end
endmodule