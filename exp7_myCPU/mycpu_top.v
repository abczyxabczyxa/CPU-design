module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire [3:0]       inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    output wire inst_sram_en,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire  [3:0]      data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    output wire data_sram_en,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

    wire rst;
    wire [31:0] pc_br_target;
    wire pc_br_taken;
    wire [31:0]pc_inst_addr;
    wire pc_inst_en;
    wire [31:0] if_pc;
    assign rst = ~resetn;
    PC_Reg pc_reg(
        .clk(clk),
        .rst(rst),
        .if_pc(if_pc),
        .inst_en(pc_inst_en),
        .pc_br_taken(pc_br_taken),
        .pc_br_target(pc_br_target),
        .inst_addr(inst_sram_addr)
    );

    assign inst_sram_en = pc_inst_en;
    

    wire [31:0] id_inst;
    wire [31:0] id_pc;
    ID_Reg id_reg(
        .clk(clk),
        .rst(rst),
        .if_pc(if_pc),
        .if_inst(inst_sram_rdata),
        .id_inst(id_inst),
        .id_pc(id_pc)
    );

    wire [31:0]id_src1;
    wire [31:0]id_src2;
    wire id_ref_we;
    wire [4:0]id_alu_op;
    wire id_dram_we;
    wire id_dram_re;
    wire [4:0]id_rd;
    wire [4:0]id_rj;
    wire [4:0]id_rk;
    wire id_src2_is_imm12;
    wire [11:0]id_imm12;
    wire [4:0]id_imm5;
    wire id_src2_is_imm5;
    wire id_src2_is_rd;
    wire [15:0] id_imm16;
    wire [25:0] id_imm26;
    wire id_src2_is_imm26;
    wire id_src2_is_imm16;
    wire id_res_from_dram;
    wire [31:0] id_dram_wdata;
    wire [19:0] id_imm20;
    wire id_src2_is_imm20;
    ID_stage id_stage(
        .id_inst(id_inst),
        .id_rj(id_rj),
        .id_rk(id_rk),
        .id_rd(id_rd),
        .id_ref_we(id_ref_we),
        .id_alu_op(id_alu_op),
        .id_dram_we(id_dram_we),
        .id_dram_re(id_dram_re),
        .id_src2_is_imm12(id_src2_is_imm12),
        .id_imm12(id_imm12),
        .id_imm5(id_imm5),
        .id_src2_is_imm5(id_src2_is_imm5),
        .id_src2_is_rd(id_src2_is_rd),
        .id_imm16(id_imm16),
        .id_imm26(id_imm26),
        .id_src2_is_imm26(id_src2_is_imm26),
        .id_src2_is_imm16(id_src2_is_imm16),
        .id_res_from_dram(id_res_from_dram),
        .id_src2_is_imm20(id_src2_is_imm20),
        .id_imm20(id_imm20)
    );
    assign id_dram_wdata=id_src2;
    wire [31:0]exe_src1;
    wire [4:0]exe_rd;
    wire [31:0]exe_src2;
    wire exe_ref_we;
    wire [4:0]exe_alu_op;
    wire exe_dram_we;
    wire exe_dram_re;
    wire [11:0] exe_imm12;
    wire exe_src2_is_imm12;
    wire [4:0] exe_imm5;
    wire exe_src2_is_imm5;
    wire [31:0] exe_pc;
    wire [15:0] exe_imm16;
    wire exe_src2_is_imm26;
    wire [25:0]exe_imm26;
    wire exe_src2_is_imm16;
    wire exe_res_from_dram;
    wire [31:0] exe_dram_wdata;
    wire [20:0] exe_imm20;
    wire exe_src2_is_imm20;
    wire [31:0] exe_dram_waddr;
    wire [31:0] exe_rf_src1;
    wire [31:0] exe_rf_src2;
    ExE_reg exe_reg(
        .clk(clk),
        .rst(rst),
        .id_rd(id_rd),
        .id_src1(id_src1),
        .id_src2(id_src2),
        .id_ref_we(id_ref_we),
        .id_alu_op(id_alu_op),
        .id_dram_re(id_dram_re),
        .id_dram_we(id_dram_we),
        .id_imm12(id_imm12),
        .id_src2_is_imm12(id_src2_is_imm12),
        .id_src2_is_imm5(id_src2_is_imm5),
        .id_imm5(id_imm5),
        .id_pc(id_pc),
        .id_imm16(id_imm16),
        .id_imm26(id_imm26),
        .id_src2_is_imm26(id_src2_is_imm26),
        .id_src2_is_imm16(id_src2_is_imm16),
        .id_res_from_dram(id_res_from_dram),
        .id_dram_wdata(id_dram_wdata),
        .id_imm20(id_imm20),
        .id_src2_is_imm20(id_src2_is_imm20),
        .exe_rd(exe_rd),
        .exe_src1(exe_src1),
        .exe_src2(exe_src2),
        .exe_ref_we(exe_ref_we),
        .exe_alu_op(exe_alu_op),
        .exe_dram_re(exe_dram_re),
        .exe_dram_we(exe_dram_we),
        .exe_imm12(exe_imm12),
        .exe_src2_is_imm12(exe_src2_is_imm12),
        .exe_pc(exe_pc),
        .exe_imm16(exe_imm16),
        .exe_imm5(exe_imm5),
        .exe_src2_is_imm5(exe_src2_is_imm5),
        .exe_src2_is_imm26(exe_src2_is_imm26),
        .exe_imm26(exe_imm26),
        .exe_src2_is_imm16(exe_src2_is_imm16),
        .exe_res_from_dram(exe_res_from_dram),
        .exe_dram_wdata(exe_dram_wdata),
        .exe_imm20(exe_imm20),
        .exe_src2_is_imm20(exe_src2_is_imm20),
        .exe_rf_src1(exe_rf_src1),
        .exe_rf_src2(exe_rf_src2)
    );

    wire [31:0] exe_alu_result;
    wire [31:0] alu_src1;
    wire [31:0] alu_src2;
    wire exe_br_taken;
    wire [31:0]exe_br_target;
    
    
    wire [17:0]exe_imm16_extend;
    wire [27:0]exe_imm26_extend;
    assign exe_imm16_extend={exe_imm16,2'b00};
    assign exe_imm26_extend={exe_imm26,2'b00};
    
    assign alu_src1=exe_src1;
    assign alu_src2 = exe_src2_is_imm12  ? {{20{exe_imm12[11]}}, exe_imm12} :
                  exe_src2_is_imm5   ? {{27{exe_imm5[4]}}, exe_imm5} :
                  exe_src2_is_imm26  ?  {{4{exe_imm26_extend[27]}}, exe_imm26_extend}:
                  exe_src2_is_imm16  ?  {{14{exe_imm16_extend[17]}}, exe_imm16_extend} :
                  exe_src2_is_imm20  ? exe_imm20 :
                                       exe_src2;
    ALU alu(
        .src1(alu_src1),
        .src2(alu_src2),
        .alu_op(exe_alu_op),
        .exe_alu_result(exe_alu_result),
        .exe_pc(exe_pc),
        .exe_br_taken(exe_br_taken),
        .exe_br_target(exe_br_target),
        .alu_rf_src1(exe_rf_src1),
        .alu_rf_src2(exe_rf_src2)
    );
    assign exe_dram_waddr = exe_alu_result;
    wire [31:0] mem_alu_result;
    wire [31:0] mem_ref_we;
    wire [4:0] mem_rd;
    wire mem_dram_re;
    wire mem_dram_we;
    wire mem_br_taken;
    wire [31:0] mem_br_target;
    wire mem_res_from_dram;
    wire [31:0] mem_dram_wdata;
    wire [31:0] mem_dram_waddr;
    wire [31:0] mem_pc;
    Mem_reg mem_reg(
        .clk(clk),
        .rst(rst),
        .exe_alu_result(exe_alu_result),
        .exe_ref_we(exe_ref_we),
        .exe_dram_re(exe_dram_re),
        .exe_dram_we(exe_dram_we),
        .exe_rd(exe_rd),
        .exe_br_taken(exe_br_taken),
        .exe_br_target(exe_br_target),
        .exe_res_from_dram(exe_res_from_dram),
        .exe_dram_waddr(exe_dram_waddr),
        .exe_dram_wdata(exe_dram_wdata),
        .exe_pc(exe_pc),
        .mem_ref_we(mem_ref_we),
        .mem_alu_result(mem_alu_result),
        .mem_dram_re(mem_dram_re),
        .mem_dram_we(mem_dram_we),
        .mem_rd(mem_rd),
        .mem_br_taken(mem_br_taken),
        .mem_br_target(mem_br_target),
        .mem_res_from_dram(mem_res_from_dram),
        .mem_dram_wdata(mem_dram_wdata),
        .mem_dram_waddr(mem_dram_waddr),
        .mem_pc(mem_pc)
    );
    wire [31:0] mem_dram_rdata;
    //assign data_sram_addr=mem_alu_result;

    assign mem_dram_rdata=data_sram_rdata;
    assign data_sram_we=mem_dram_we? 4'b1111: 4'b0000;
    assign data_sram_en=1'b1;
    assign data_sram_wdata=mem_dram_wdata;
    assign data_sram_addr=mem_dram_we? mem_dram_waddr: mem_alu_result;

    wire  wb_rf_we;
    wire [31:0] wb_alu_result;
    wire [4:0] wb_rd;
    wire [31:0] wb_br_target;
    wire wb_br_taken;
   // wire [31:0]wb_dram_rdata;
    wire wb_res_from_dram;
    wire [31:0] wb_dram_wdata;
    wire [31:0] wb_dram_waddr;
    wire wb_dram_we;
    wire [31:0] wb_pc;
    Wb_reg wb_reg(
        .clk(clk),
        .rst(rst),
        .mem_alu_result(mem_alu_result),
        .mem_ref_we(mem_ref_we),
        .mem_rd(mem_rd),
        .mem_br_taken(mem_br_taken),
        .mem_br_target(mem_br_target),
       // .mem_dram_rdata(mem_dram_rdata),
        .mem_res_from_dram(mem_res_from_dram),
        .mem_dram_wdata(mem_dram_wdata),
        .mem_dram_waddr(mem_dram_waddr),
        .mem_dram_we(mem_dram_we),
        .mem_pc(mem_pc),
        .wb_rf_we(wb_rf_we),
        .wb_alu_result(wb_alu_result),
        .wb_rd(wb_rd),
        .wb_br_taken(wb_br_taken),
        .wb_br_target(wb_br_target),
       // .wb_dram_rdata(wb_dram_rdata),
        .wb_res_from_dram(wb_res_from_dram),
        .wb_dram_waddr(wb_dram_waddr),
        .wb_dram_wdata(wb_dram_wdata),
        .wb_dram_we(wb_dram_we),
        .wb_pc(wb_pc)
    );
    
    assign pc_br_taken=wb_br_taken;
    assign pc_br_target=wb_br_target;

    wire [31:0] rf_raddr1;
    wire [31:0] rf_raddr2;
    wire [31:0] rf_wdata;
    wire [31:0] rf_rdata1;
    wire [31:0] rf_rdata2;
    assign rf_raddr1 = id_rj;
    assign rf_raddr2 = id_src2_is_rd? id_rd: id_rk;
    assign rf_wdata = wb_res_from_dram? mem_dram_rdata: wb_alu_result;  
    
    
    
    regfile rf(
        .raddr1(rf_raddr1),
        .raddr2(rf_raddr2),
        .rdata1(rf_rdata1),
        .rdata2(rf_rdata2),
        .clk(clk),
        .waddr(wb_rd),
        .wdata(rf_wdata),
        .we(wb_rf_we)
    );

    assign id_src1=rf_rdata1;
    assign id_src2=rf_rdata2;
    assign debug_wb_pc = wb_pc;
    assign debug_wb_rf_we ={4{wb_rf_we}};
    assign debug_wb_rf_wnum=wb_rd;
    assign debug_wb_rf_wdata=rf_wdata;
    
endmodule