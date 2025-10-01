module Wb_reg (
    input wire clk,
    input wire rst,
input wire
    input mem_ready_go,

    input wire [31:0] mem_alu_result,
    input wire mem_ref_we,
    input wire [4:0] mem_rd,
    input wire mem_br_taken,
    input wire [31:0] mem_br_target,
    input wire [31:0] mem_dram_rdata,
    input wire mem_res_from_dram,
    input wire [31:0] mem_dram_wdata,
    input wire [31:0] mem_dram_waddr,
    input wire mem_dram_we,
    input wire [31:0] mem_pc,
    input wire [1:0]mem_rdram_num,
    input wire mem_rdram_need_signed_extend,
    input wire mem_rdram_need_zero_extend,

    output reg wb_rf_we,
    output reg [31:0] wb_alu_result,
    output reg [4:0] wb_rd,
    output reg wb_br_taken,
    output reg [31:0] wb_br_target,
    output reg [31:0] wb_dram_rdata,
    output reg wb_res_from_dram,
    output reg [31:0] wb_dram_waddr,
    output reg [31:0] wb_dram_wdata,
    output reg wb_dram_we,
    output reg [31:0] wb_pc,
    output reg [1:0]wb_rdram_num,
    output reg wb_rdram_need_signed_extend,
    output reg wb_rdram_need_zero_extend 
);

always @(posedge clk ) begin
    if (rst) begin
        wb_rf_we <= 1'b0;
        wb_alu_result <= 32'd0;
        wb_rd <= 5'd0;
        wb_br_taken <= 1'b0;
        wb_br_target <= 32'd0;
        wb_dram_rdata <= 32'd0;
        wb_res_from_dram <= 1'b0;
        wb_dram_waddr <= 32'd0;
        wb_dram_wdata <= 32'd0;
        wb_dram_we <= 1'b0;
        wb_pc<=32'b0;
        wb_rdram_num<=2'b0;
        wb_rdram_need_signed_extend<=1'b0;
        wb_rdram_need_zero_extend<=1'b0;
    end else if(mem_ready_go)begin
        wb_rf_we <= mem_ref_we;
        wb_alu_result <= mem_alu_result;
        wb_rd <= mem_rd;
        wb_br_taken <= mem_br_taken;
        wb_br_target <= mem_br_target;
        wb_dram_rdata <= mem_dram_rdata;
        wb_res_from_dram <= mem_res_from_dram;
        wb_dram_waddr <= mem_dram_waddr;
        wb_dram_wdata <= mem_dram_wdata;
        wb_dram_we <= mem_dram_we;
        wb_pc<=mem_pc;
        wb_rdram_num<=mem_rdram_num;
        wb_rdram_need_signed_extend<=mem_rdram_need_signed_extend;
        wb_rdram_need_zero_extend<=mem_rdram_need_zero_extend;
    end
    else
    begin
        wb_rf_we <= wb_rf_we;
        wb_alu_result <= wb_alu_result;
        wb_rd <= wb_rd;
        wb_br_taken <= wb_br_taken;
        wb_br_target <= wb_br_target;
        wb_dram_rdata <= wb_dram_rdata;
        wb_res_from_dram <= wb_res_from_dram;
        wb_dram_waddr <= wb_dram_waddr;
        wb_dram_wdata <= wb_dram_wdata;
        wb_dram_we <= wb_dram_we;
        wb_pc<=wb_pc;
        wb_rdram_num<=wb_rdram_num;
        wb_rdram_need_signed_extend<=wb_rdram_need_signed_extend;
        wb_rdram_need_zero_extend<=wb_rdram_need_zero_extend;
    end
end

endmodule
