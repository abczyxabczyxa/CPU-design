module ID_stage(
    input  wire [31:0] id_inst,          // 32 位指令输�???
    input wire [31:0] id_rf_rdata1,
    input wire [31:0] id_rf_rdata2,
    input wire [31:0] id_pc,
    output wire [4:0]  id_rj,            // 寄存�??? rj 编号
    output wire [4:0]  id_rk,            // 寄存�??? rk 编号
    output wire [4:0]  id_rd,            // 目标寄存�??? rd 编号 
    output wire [31:0] id_src1,          // 源操作数1（来�??? rj�???
    output wire [31:0] id_src2,          // 源操作数2（来�??? rk 或立即数�???
    output  wire  id_ref_we,        // 寄存器写使能（是否写�??? rd�???
    output wire [4:0]  id_alu_op,        // ALU 操作�???
    output   wire     id_dram_we,       // 数据存储器写使能（store 指令�???
    output   wire   id_dram_re,       // 数据存储器读使能（load 指令�???
     output  wire      id_src2_is_imm12, // src2 �??? 12 位立即数
    output wire [11:0] id_imm12,         // 12 位立即数
    output  wire      id_src2_is_imm5,  // src2 �??? 5 位立即数
    output wire [4:0]  id_imm5,          // 5 位立即数 */
    output   wire     id_src2_is_rd,    // src2 �??? rd 寄存器（某些特殊指令�???
    output wire [15:0] id_imm16,         // 16 位立即数（用�??? B/Bl 等）
    output wire [25:0] id_imm26,         // 26 位立即数（长跳转�???
    output   wire     id_src2_is_imm26, // src2 �??? 26 位立即数
    output     wire   id_src2_is_imm16, // src2 �??? 16 位立即数
    output     wire   id_res_from_dram, // 结果来自数据存储器（load 指令�???
    output  wire      id_src2_is_imm20, // src2 �??? 20 位立即数
    output wire [19:0] id_imm20,      // 20 位立即数
    //output wire id_cancel,
    output wire id_br_taken,
    output wire [31:0]id_br_target,
    output wire id_src1_from_ref,
    output wire id_src2_from_ref
);

    wire [ 5:0] op_31_26;
    wire [ 3:0] op_25_22;
    wire [ 1:0] op_21_20;
    wire [ 4:0] op_19_15;
    wire [63:0] op_31_26_d;
    wire [15:0] op_25_22_d;
    wire [ 3:0] op_21_20_d;
    wire [31:0] op_19_15_d;

    wire        inst_add_w;
    wire        inst_sub_w;
    wire        inst_slt;
    wire        inst_sltu;
    wire        inst_nor;
    wire        inst_and;
    wire        inst_or;
    wire        inst_xor;
    wire        inst_slli_w;
    wire        inst_srli_w;
    wire        inst_srai_w;
    wire        inst_addi_w;
    wire        inst_ld_w;
    wire        inst_st_w;
    wire        inst_jirl;
    wire        inst_b;
    wire        inst_bl;
    wire        inst_beq;
    wire        inst_bne;
    wire        inst_lu12i_w;

    //指令字段提取 
    assign op_31_26  = id_inst[31:26];
    assign op_25_22  = id_inst[25:22];
    assign op_21_20  = id_inst[21:20];
    assign op_19_15  = id_inst[19:15];

    assign id_rd = inst_bl? 5'd1:id_inst[4:0];         
    assign id_rj = id_inst[9:5];         
    assign id_rk = id_inst[14:10];       

    // 立即数提�???
    assign id_imm5  = id_inst[14:10];    
    assign id_imm12 = id_inst[21:10];   
    assign id_imm16 = id_inst[25:10];    
    assign id_imm20 = id_inst[24:5];     
    assign id_imm26 = {id_inst[ 9: 0], id_inst[25:10]};    

    decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
    decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
    decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
    decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

    assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
    assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
    assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
    assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
    assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
    assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
    assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
    assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
    assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
    assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
    assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
    assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
    assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
    assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
    assign inst_jirl   = op_31_26_d[6'h13];
    assign inst_b      = op_31_26_d[6'h14];
    assign inst_bl     = op_31_26_d[6'h15];
    assign inst_beq    = op_31_26_d[6'h16];
    assign inst_bne    = op_31_26_d[6'h17];
    assign inst_lu12i_w= op_31_26_d[6'h05] & ~id_inst[25];

   assign id_alu_op = inst_sub_w    ? 5'd1  :
                   inst_slt      ? 5'd2  :
                   inst_sltu     ? 5'd3  :
                   inst_and      ? 5'd4  :
                   inst_or       ? 5'd5  :
                   inst_nor      ? 5'd6  :
                   inst_xor      ? 5'd7  :
                   inst_slli_w   ? 5'd8  :
                   inst_srli_w   ? 5'd9  :
                   inst_srai_w   ? 5'd10 :
                   inst_beq      ? 5'd11 :
                   inst_bne      ? 5'd12 :
                   (inst_b  || inst_bl) ? 5'd13 :
                   inst_jirl       ? 5'd14 :
                   inst_lu12i_w  ? 5'd15 :
                   // Ĭ��ֵ�������� add.w, addi.w, ld.w, st.w ��
                   5'd0;


    assign id_src2_is_imm5   =  inst_slli_w | inst_srli_w | inst_srai_w;
    assign id_src2_is_imm12  =  inst_addi_w | inst_ld_w | inst_st_w;
    assign id_src2_is_imm16  =  inst_jirl | inst_beq | inst_bne;
    assign id_src2_is_imm20  =  inst_lu12i_w;
    assign id_src2_is_imm26  =  inst_b | inst_bl;
   
    assign id_ref_we = (inst_add_w | inst_sub_w | inst_slt | inst_sltu | inst_nor | 
                      inst_and | inst_or | inst_xor | inst_slli_w | inst_srli_w | 
                      inst_srai_w | inst_addi_w | inst_ld_w | inst_lu12i_w | inst_jirl | inst_bl)&&(id_inst!=32'h02800000);

    assign id_dram_we = inst_st_w;
    assign id_dram_re = inst_ld_w;
    assign id_res_from_dram = inst_ld_w;
    assign id_src2_is_rd = inst_beq | inst_bne | inst_st_w;

    wire [31:0] id_offset;
    wire [17:0] id_imm16_extend;
    wire [27:0] id_imm26_extend;
    assign id_imm16_extend={id_imm16,2'b00};
    assign id_imm26_extend={id_imm26,2'b00};
    
    
    assign id_offset = id_src2_is_imm12  ? {{20{id_imm12[11]}}, id_imm12} :
                  id_src2_is_imm5   ? {{27{id_imm5[4]}}, id_imm5} :
                  id_src2_is_imm26  ?  {{4{id_imm26_extend[27]}}, id_imm26_extend}:
                  id_src2_is_imm16  ?  {{14{id_imm16_extend[17]}}, id_imm16_extend} :
                  id_src2_is_imm20  ? id_imm20 :
                                       id_src2;

    assign id_br_taken = (inst_beq&&(id_rf_rdata1==id_rf_rdata2))||(inst_bne&&(id_rf_rdata1!=id_rf_rdata2))||(inst_b)||(inst_bl)||(inst_jirl);
    assign id_br_target = (inst_beq||inst_bne||inst_b||inst_bl) ?   id_pc + id_offset :
                            inst_jirl?             id_rf_rdata1+id_offset :32'h00000000;
    

    assign id_src1_from_ref = inst_add_w | inst_sub_w | inst_addi_w | inst_slt |inst_sltu|inst_or|inst_nor|inst_and|inst_xor|inst_slli_w|inst_srai_w|inst_srli_w|inst_beq|inst_bne|inst_jirl|inst_ld_w|inst_st_w;
    assign id_src2_from_ref = inst_add_w |inst_sub_w|inst_lu12i_w| inst_slt|inst_sltu|inst_or|inst_nor|inst_and|inst_xor|inst_beq|inst_bne|inst_lu12i_w;

endmodule