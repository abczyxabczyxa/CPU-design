module Mem_reg (
    input wire clk,
    input wire rst,
    input wire exe_ready_go,
    input wire [31:0] exe_alu_result,
    input wire exe_ref_we,
    input wire exe_dram_re,
    input wire exe_dram_we,
    input wire [4:0] exe_rd,
    input wire exe_br_taken,
    input wire [31:0] exe_br_target,
    input wire exe_res_from_dram,
    input wire [31:0] exe_dram_waddr,
    input wire [31:0] exe_dram_wdata,
    input wire [31:0] exe_pc,
    output reg mem_ref_we,
    output reg [31:0] mem_alu_result,
    output reg mem_dram_re,
    output reg mem_dram_we,
    output reg [4:0] mem_rd,
    output reg mem_br_taken,
    output reg [31:0] mem_br_target,
    output reg mem_res_from_dram,
    output reg [31:0] mem_dram_wdata,
    output reg [31:0] mem_dram_waddr,
    output reg [31:0] mem_pc
);

always @(posedge clk) begin
    if (rst) begin
        mem_ref_we       <= 1'b0;
        mem_alu_result   <= 32'd0;
        mem_dram_re      <= 1'b0;
        mem_dram_we      <= 1'b0;
        mem_rd           <= 5'd0;
        mem_br_taken     <= 1'b0;
        mem_br_target    <= 32'd0;
        mem_res_from_dram<= 1'b0;
        mem_dram_wdata   <= 32'd0;
        mem_dram_waddr   <= 32'd0;
        mem_pc           <= 32'd0;
    end else begin
        casez (exe_ready_go)
            1'b1, 1'bx, 1'bz: begin // ready 或不确定都更新
                mem_ref_we       <= exe_ref_we;
                mem_alu_result   <= exe_alu_result;
                mem_dram_re      <= exe_dram_re;
                mem_dram_we      <= exe_dram_we;
                mem_rd           <= exe_rd;
                mem_br_taken     <= exe_br_taken;
                mem_br_target    <= exe_br_target;
                mem_res_from_dram<= exe_res_from_dram;
                mem_dram_wdata   <= exe_dram_wdata;
                mem_dram_waddr   <= exe_dram_waddr;
                mem_pc           <= exe_pc;
            end
            1'b0: begin // 不 ready，保持当前值
                mem_ref_we       <= mem_ref_we;
                mem_alu_result   <= mem_alu_result;
                mem_dram_re      <= mem_dram_re;
                mem_dram_we      <= mem_dram_we;
                mem_rd           <= mem_rd;
                mem_br_taken     <= mem_br_taken;
                mem_br_target    <= mem_br_target;
                mem_res_from_dram<= mem_res_from_dram;
                mem_dram_wdata   <= mem_dram_wdata;
                mem_dram_waddr   <= mem_dram_waddr;
                mem_pc           <= mem_pc;
            end
        endcase
    end
end

endmodule
