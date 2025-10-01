module ExE_reg (
    input clk,
    input rst,

    input [4:0] id_rd,
    input [31:0] id_src1,
    input [31:0] id_src2,
    input id_ref_we,
    input [4:0] id_alu_op,
    input id_dram_re,
    input id_dram_we,
    input [11:0] id_imm12,
    input id_src2_is_imm12,
    input id_src2_is_imm5,
    input [4:0] id_imm5,
    input [31:0] id_pc,
    input [15:0] id_imm16,
    input [25:0] id_imm26,
    input id_src2_is_imm26,
    input id_src2_is_imm16,
    input id_res_from_dram,
    input [31:0] id_dram_wdata,
    input [19:0] id_imm20,
    input id_src2_is_imm20,

    output reg [4:0] exe_rd,
    output reg [31:0] exe_src1,
    output reg [31:0] exe_src2,
    output reg exe_ref_we,
    output reg [4:0] exe_alu_op,
    output reg exe_dram_re,
    output reg exe_dram_we,
    output reg [11:0] exe_imm12,
    output reg exe_src2_is_imm12,
    output reg exe_src2_is_imm5,
    output reg [4:0] exe_imm5,
    output reg [31:0] exe_pc,
    output reg [15:0] exe_imm16,
    output reg [25:0] exe_imm26,
    output reg exe_src2_is_imm26,
    output reg exe_src2_is_imm16,
    output reg exe_res_from_dram,
    output reg [31:0] exe_dram_wdata,
    output reg [19:0] exe_imm20,
    output reg exe_src2_is_imm20,
    output reg [31:0] exe_rf_src1,
    output reg [31:0] exe_rf_src2
);

always @(posedge clk) begin
    if (rst) begin
        exe_rd <= 5'd0;
        exe_src1 <= 32'd0;
        exe_src2 <= 32'd0;
        exe_ref_we <= 1'b0;
        exe_alu_op <= 4'd0;
        exe_dram_re <= 1'b0;
        exe_dram_we <= 1'b0;
        exe_imm12 <= 12'd0;
        exe_src2_is_imm12 <= 1'b0;
        exe_src2_is_imm5 <= 1'b0;
        exe_imm5 <= 5'd0;
        exe_pc <= 32'd0;
        exe_imm16 <= 16'd0;
        exe_imm26 <= 26'd0;
        exe_src2_is_imm26 <= 1'b0;
        exe_src2_is_imm16 <= 1'b0;
        exe_res_from_dram <= 1'b0;
        exe_dram_wdata <= 32'd0;
        exe_imm20 <= 20'd0;
        exe_src2_is_imm20 <= 1'b0;
        exe_rf_src1<=32'b0;
        exe_rf_src2<=32'b0;
    end else begin
        exe_rd <= id_rd;
        exe_src1 <= id_src1;
        exe_src2 <= id_src2;
        exe_ref_we <= id_ref_we;
        exe_alu_op <= id_alu_op;
        exe_dram_re <= id_dram_re;
        exe_dram_we <= id_dram_we;
        exe_imm12 <= id_imm12;
        exe_src2_is_imm12 <= id_src2_is_imm12;
        exe_src2_is_imm5 <= id_src2_is_imm5;
        exe_imm5 <= id_imm5;
        exe_pc <= id_pc;
        exe_imm16 <= id_imm16;
        exe_imm26 <= id_imm26;
        exe_src2_is_imm26 <= id_src2_is_imm26;
        exe_src2_is_imm16 <= id_src2_is_imm16;
        exe_res_from_dram <= id_res_from_dram;
        exe_dram_wdata <= id_dram_wdata;
        exe_imm20 <= id_imm20;
        exe_src2_is_imm20 <= id_src2_is_imm20;
        exe_rf_src1<=id_src1;
        exe_rf_src2<=id_src2;
    end
end

endmodule
