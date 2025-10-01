module ExE_reg (
    input wire clk,
    input wire rst,
    input wire id_ready_go,
    input wire wb_ex,
    input wire wb_is_ertn,
    input wire exe_div_is_doing,
    input wire exe_allow_in,
    input wire mem_allow_in,
    input wire exe_ready_go,
    input wire exe_addr_shake_ok,
    input wire mem_data_shake_ok,
    input wire mem_need_and_data_ok,
    input wire[4:0] id_rd,
    input wire[31:0] id_src1,
    input wire[31:0] id_src2,
    input wire id_ref_we,
    input wire[4:0] id_alu_op,
    input wire id_dram_re,
    input wire id_dram_we,
    input wire [11:0] id_imm12,
    input wire id_src2_is_imm12,
    input wire id_src2_is_imm5,
    input wire [4:0] id_imm5,
    input wire [31:0] id_pc,
    input wire [15:0] id_imm16,
    input wire [25:0] id_imm26,
    input wire id_src2_is_imm26,
    input wire id_src2_is_imm16,
    input wire id_res_from_dram,
    input wire [31:0] id_dram_wdata,
    input wire[19:0] id_imm20,
    input wire id_src2_is_imm20,
    input wire id_zero_extend,
    input wire id_rdram_need_zero_extend,
    input wire id_rdram_need_signed_extend,
    input wire [1:0] id_rdram_num,
    input wire[1:0] id_wdram_num,
    input wire [13:0] id_csr_num,
    input wire id_csr_we,
    input wire id_is_ertn,
    input wire id_is_syscall,
    input wire id_res_from_csr,
    input wire [31:0] id_csr_wmask,
    input wire [31:0] id_csr_wdata,
    input wire id_ex_adef,
    input wire id_ex_brk,
    input wire id_ex_ine,
    input wire id_ex_ale_h,
    input wire id_ex_ale_w,
    input wire id_has_int,
    input wire [4:0]id_rj,
    input wire [31:0]id_res_of_cnt,
    input wire id_res_is_rj,
    input wire id_res_from_cnt,
    input wire id_res_from_tid,
    input wire id_need_data_sram, 
    input wire id_need_cancel,
    input wire id_inst_tlbrd,
    input wire id_inst_tlbsrch,
    input wire id_tlb_wr_en,
    input wire id_tlb_we,
    input wire id_tlb_fill_en,
    input wire [9:0] id_invtlb_asid,
    input wire [4:0] id_invtlb_op,
    input wire [18:0] id_invtlb_va,
    input wire id_invtlb_valid,
    input wire id_is_st,
    input wire id_is_ld,
    input wire id_tlb_or_csr_we,
    input wire [1:0]id_inst_tlb_ex,

    //input wire [31:0]id_csr_rdata,

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
    output reg [31:0] exe_rf_src2,
    output reg exe_zero_extend,
    output reg exe_rdram_need_zero_extend,
    output reg exe_rdram_need_signed_extend,
    output reg [1:0]exe_rdram_num,
    output reg [1:0]exe_wdram_num,
    output reg [13:0] exe_csr_num,
    output reg exe_csr_we,
    output reg exe_is_ertn,
    output reg exe_is_syscall,
    output reg exe_res_from_csr,
    output reg [31:0] exe_csr_wmask,
    output reg [31:0] exe_csr_wdata,
    output reg exe_ex_adef,
    output reg exe_ex_brk,
    output reg exe_ex_ine,
    output reg exe_ex_ale_h,
    output reg exe_ex_ale_w,
    output reg exe_has_int,
    output reg [4:0]exe_rj,
    output reg [31:0]exe_res_of_cnt,
    output reg exe_res_is_rj,
    output reg exe_res_from_cnt,
    output reg exe_res_from_tid,
    output reg exe_need_data_sram,
    output reg exe_need_cancel,
    output reg exe_inst_tlbrd,
    output reg exe_inst_tlbsrch,
    output reg exe_tlb_wr_en,
    output reg exe_tlb_we,
    output reg exe_tlb_fill_en,
    output reg [9:0] exe_invtlb_asid,
    output reg [4:0] exe_invtlb_op,
    output reg [18:0] exe_invtlb_va,
    output reg exe_invtlb_valid,
    output reg exe_is_st,
    output reg exe_is_ld,
    output reg exe_tlb_or_csr_we,
    output reg [1:0]exe_inst_tlb_ex
);

always @(posedge clk) begin
    if (rst ||wb_ex===1'b1||wb_is_ertn===1'b1) begin
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
        exe_rf_src1 <= 32'b0;
        exe_rf_src2 <= 32'b0;
        exe_zero_extend<=1'b0;
        exe_rdram_need_zero_extend<=1'b0;
        exe_rdram_need_signed_extend<=1'b0;
        exe_rdram_num<=2'b0;
        exe_wdram_num<=2'b0;
        exe_csr_num<=14'b0;
        exe_csr_we<=1'b0;
        exe_is_ertn<=1'b0;
        exe_is_syscall<=1'b0;
        exe_res_from_csr<=1'b0;
        exe_csr_wmask<=32'b0;
        exe_csr_wdata<=32'b0;
        exe_ex_adef<=1'b0;
        exe_ex_ale_h<=1'b0;
        exe_ex_ale_w<=1'b0;
        exe_ex_brk<=1'b0;
        exe_ex_ine<=1'b0;
        exe_has_int<=1'b0;
        exe_rj<=5'b0;
        exe_res_of_cnt<=32'b0;
        exe_res_is_rj<=1'b0;
        exe_res_from_cnt<=1'b0;
        exe_res_from_tid<=1'b0;
        exe_need_data_sram<=1'b0;
        exe_need_cancel <= 1'b0;
        exe_inst_tlbrd <= 1'b0;
        exe_inst_tlbsrch <= 1'b0;
        exe_tlb_wr_en <= 1'b0;
        exe_tlb_we <= 1'b0;
        exe_tlb_fill_en <= 1'b0;
        exe_invtlb_asid <= 10'b0;
        exe_invtlb_op <= 5'b0;
        exe_invtlb_va <= 19'b0;
        exe_invtlb_valid <= 1'b0;
        exe_is_st <= 1'b0;
        exe_is_ld <= 1'b0;
        exe_tlb_or_csr_we <= 1'b0;
        exe_inst_tlb_ex <= 2'b0;
        //exe_csr_rdata<=32'b0;
    end else begin
        casez (!(id_ready_go===1'b0)&&exe_allow_in)

            1'b0: begin  // �??? ready，保持原�???
                if(!(exe_ready_go===1'b0)&&mem_allow_in==1'b1)
                begin
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
                exe_rf_src1 <= 32'b0;
                exe_rf_src2 <= 32'b0;
                exe_zero_extend<=1'b0;
                exe_rdram_need_zero_extend<=1'b0;
                exe_rdram_need_signed_extend<=1'b0;
                exe_rdram_num<=2'b0;
                exe_wdram_num<=2'b0;
                exe_csr_num<=14'b0;
                exe_csr_we<=1'b0;
                exe_is_ertn<=1'b0;
                exe_is_syscall<=1'b0;
                exe_res_from_csr<=1'b0;
                exe_csr_wmask<=32'b0;
                exe_csr_wdata<=32'b0;
                exe_ex_adef<=1'b0;
                exe_ex_ale_h<=1'b0;
                exe_ex_ale_w<=1'b0;
                exe_ex_brk<=1'b0;
                exe_ex_ine<=1'b0;
                exe_has_int<=1'b0;
                exe_rj<=5'b0;
                exe_res_of_cnt<=32'b0;
                exe_res_is_rj<=1'b0;
                exe_res_from_cnt<=1'b0;
                exe_res_from_tid<=1'b0;
                exe_need_data_sram<=1'b0;
                exe_need_cancel <= 1'b0;
                exe_inst_tlbrd <= 1'b0;
                exe_inst_tlbsrch <= 1'b0;
                exe_tlb_wr_en <= 1'b0;
                exe_tlb_we <= 1'b0;
                exe_tlb_fill_en <= 1'b0;
                exe_invtlb_asid <= 10'b0;
                exe_invtlb_op <= 5'b0;
                exe_invtlb_va <= 19'b0;
                exe_invtlb_valid <= 1'b0;
                exe_is_st <= 1'b0;
                exe_is_ld <= 1'b0;
                exe_tlb_or_csr_we <= 1'b0;
                exe_inst_tlb_ex <= 2'b0;
                end
                else if(exe_addr_shake_ok===1'b0 || mem_data_shake_ok===1'b0 || mem_need_and_data_ok==1'b1 || exe_div_is_doing)
                begin
                exe_rd <= exe_rd;
                exe_src1 <= exe_src1;
                exe_src2 <= exe_src2;
                exe_ref_we <= exe_ref_we;
                exe_alu_op <= exe_alu_op;
                exe_dram_re <= exe_dram_re;
                exe_dram_we <= exe_dram_we;
                exe_imm12 <= exe_imm12;
                exe_src2_is_imm12 <= exe_src2_is_imm12;
                exe_src2_is_imm5 <= exe_src2_is_imm5;
                exe_imm5 <= exe_imm5;
                exe_pc <= exe_pc;
                exe_imm16 <= exe_imm16;
                exe_imm26 <= exe_imm26;
                exe_src2_is_imm26 <= exe_src2_is_imm26;
                exe_src2_is_imm16 <= exe_src2_is_imm16;
                exe_res_from_dram <= exe_res_from_dram;
                exe_dram_wdata <= exe_dram_wdata;
                exe_imm20 <= exe_imm20;
                exe_src2_is_imm20 <= exe_src2_is_imm20;
                exe_rf_src1 <= exe_src1;
                exe_rf_src2 <= exe_src2;
                exe_zero_extend<=exe_zero_extend;
                exe_rdram_need_zero_extend<=exe_rdram_need_zero_extend;
                exe_rdram_need_signed_extend<=exe_rdram_need_signed_extend;
                exe_rdram_num<=exe_rdram_num;
                exe_wdram_num<=exe_wdram_num;
                exe_csr_num<=exe_csr_num;
                exe_csr_we<=exe_csr_we;
                exe_is_ertn<=exe_is_ertn;
                exe_is_syscall<=exe_is_syscall;
                exe_res_from_csr<=exe_res_from_csr;
                exe_csr_wmask<=exe_csr_wmask;
                exe_csr_wdata<=exe_csr_wdata;
                exe_ex_adef<=exe_ex_adef;
                exe_ex_ale_h<=exe_ex_ale_h;
                exe_ex_ale_w<=exe_ex_ale_w;
                exe_ex_brk<=exe_ex_brk;
                exe_ex_ine<=exe_ex_ine;
                exe_has_int<=exe_has_int;
                exe_rj<=exe_rj;
                exe_res_of_cnt<=exe_res_of_cnt;
                exe_res_is_rj<=exe_res_is_rj;
                exe_res_from_cnt<=exe_res_from_cnt;
                exe_res_from_tid<=exe_res_from_tid;
                exe_need_data_sram<=exe_need_data_sram; 
                exe_need_cancel <= exe_need_cancel;
                exe_inst_tlbrd <= exe_inst_tlbrd;
                exe_inst_tlbsrch <= exe_inst_tlbsrch;
                exe_tlb_wr_en <= exe_tlb_wr_en;
                exe_tlb_we <= exe_tlb_we;
                exe_tlb_fill_en <= exe_tlb_fill_en;
                exe_invtlb_asid <= exe_invtlb_asid;
                exe_invtlb_op <= exe_invtlb_op;
                exe_invtlb_va <= exe_invtlb_va;
                exe_invtlb_valid <= exe_invtlb_valid;
                exe_is_st <= exe_is_st;
                exe_is_ld <= exe_is_ld;
                exe_tlb_or_csr_we <= exe_tlb_or_csr_we;
                exe_inst_tlb_ex <= exe_inst_tlb_ex;
                end
                else
                begin
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
                exe_rf_src1 <= 32'b0;
                exe_rf_src2 <= 32'b0;
                exe_zero_extend<=1'b0;
                exe_rdram_need_zero_extend<=1'b0;
                exe_rdram_need_signed_extend<=1'b0;
                exe_rdram_num<=2'b0;
                exe_wdram_num<=2'b0;
                exe_csr_num<=14'b0;
                exe_csr_we<=1'b0;
                exe_is_ertn<=1'b0;
                exe_is_syscall<=1'b0;
                exe_res_from_csr<=1'b0;
                exe_csr_wmask<=32'b0;
                exe_csr_wdata<=32'b0;
                exe_ex_adef<=1'b0;
                exe_ex_ale_h<=1'b0;
                exe_ex_ale_w<=1'b0;
                exe_ex_brk<=1'b0;
                exe_ex_ine<=1'b0;
                exe_has_int<=1'b0;
                exe_rj<=5'b0;
                exe_res_of_cnt<=32'b0;
                exe_res_is_rj<=1'b0;
                exe_res_from_cnt<=1'b0;
                exe_res_from_tid<=1'b0;
                exe_need_data_sram<=1'b0;
                exe_need_cancel <= 1'b0;
                exe_inst_tlbrd <= 1'b0;
                exe_inst_tlbsrch <= 1'b0;
                exe_tlb_wr_en <= 1'b0;
                exe_tlb_we <= 1'b0;
                exe_tlb_fill_en <= 1'b0;
                exe_invtlb_asid <= 10'b0;
                exe_invtlb_op <= 5'b0;
                exe_invtlb_va <= 19'b0;
                exe_invtlb_valid <= 1'b0;
                exe_is_st <= 1'b0;
                exe_is_ld <= 1'b0;
                exe_tlb_or_csr_we <= 1'b0;
                exe_inst_tlb_ex <= 2'b0;
                end
            end
            default: begin  // ready 或不确定时都更新
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
                exe_rf_src1 <= id_src1;
                exe_rf_src2 <= id_src2;
                exe_zero_extend<=id_zero_extend;
                exe_rdram_need_zero_extend<=id_rdram_need_zero_extend;
                exe_rdram_need_signed_extend<=id_rdram_need_signed_extend;
                exe_rdram_num<=id_rdram_num;
                exe_wdram_num<=id_wdram_num;
                exe_csr_num<=id_csr_num;
                exe_csr_we<=id_csr_we;
                exe_is_ertn<=id_is_ertn;
                exe_is_syscall<=id_is_syscall;
                exe_res_from_csr<=id_res_from_csr;
                exe_csr_wmask<=id_csr_wmask;
                exe_csr_wdata<=id_csr_wdata;
                exe_ex_adef<=id_ex_adef;
                exe_ex_ale_h<=id_ex_ale_h;
                exe_ex_ale_w<=id_ex_ale_w;
                exe_ex_brk<=id_ex_brk;
                exe_ex_ine<=id_ex_ine;
                exe_has_int<=id_has_int;
                exe_rj<=id_rj;
                exe_res_of_cnt<=id_res_of_cnt;
                exe_res_is_rj<=id_res_is_rj;
                exe_res_from_cnt<=id_res_from_cnt;
                exe_res_from_tid<=id_res_from_tid;
                exe_need_data_sram<=id_need_data_sram;
                exe_need_cancel <= id_need_cancel;
                exe_inst_tlbrd <= id_inst_tlbrd;
                exe_inst_tlbsrch <= id_inst_tlbsrch;
                exe_tlb_wr_en <= id_tlb_wr_en;
                exe_tlb_we <= id_tlb_we;
                exe_tlb_fill_en <= id_tlb_fill_en;
                exe_invtlb_asid <= id_invtlb_asid;
                exe_invtlb_op <= id_invtlb_op;
                exe_invtlb_va <= id_invtlb_va;
                exe_invtlb_valid <= id_invtlb_valid;
                exe_is_st <= id_is_st;
                exe_is_ld <= id_is_ld;
                exe_tlb_or_csr_we <= id_tlb_or_csr_we;
                exe_inst_tlb_ex <= id_inst_tlb_ex;
               //exe_csr_rdata<=id_csr_rdata;
            end
        endcase
    end
end


endmodule
