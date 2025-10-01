module Wb_reg (
    input wire clk,
    input wire rst,

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
    output reg [31:0] wb_pc
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
    end else begin
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
    end
end

endmodule
