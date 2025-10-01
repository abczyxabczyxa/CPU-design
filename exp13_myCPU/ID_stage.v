module ID_stage(
    input  wire [31:0] id_inst,          // 32位指令输入
    input  wire [31:0] id_pc,            // 当前指令的PC值
    input  wire [12:0] csr_estat_is,     // 中断状态寄存器输入
    input  wire [12:0] csr_ecfg_lie,     // 中断使能配置寄存器输入
    input  wire        csr_crmd_ie,      // 全局中断使能位
    input  wire [63:0] csr_timer_64,     // 64位计数器数值
    //input  wire [31:0] csr_tid_tid,      // 64位计数器编号
    input  wire [31:0] id_rf_rdata1,     // 从寄存器文件读取的第一个操作数
    input  wire [31:0] id_rf_rdata2,     // 从寄存器文件读取的第二个操作数
    
    output wire [4:0]  id_rj,            // 寄存器rj的编号
    output wire [4:0]  id_rk,            // 寄存器rk的编号
    output wire [4:0]  id_rd,            // 目标寄存器rd的编号
    output wire        id_ref_we,         // 寄存器写使能(是否写rd)
    output wire [4:0]  id_alu_op,        // ALU操作码
    output wire        id_dram_we,       // 数据存储器写使能(store指令)
    output wire        id_dram_re,       // 数据存储器读使能(load指令)
    output wire [31:0] id_src1,          // ALU操作数1(来自rj)
    output wire [31:0] id_src2,          // ALU操作数2(来自rk或立即数)
    output wire        id_src2_is_imm12, // src2是12位立即数
    output wire [11:0] id_imm12,         // 12位立即数
    output wire [4:0]  id_imm5,          // 5位立即数
    output wire        id_src2_is_imm5,  // src2是5位立即数
    output wire        id_src2_is_rd,    // src2是rd寄存器(某些特殊指令)
    output wire [15:0] id_imm16,         // 16位立即数(用于B/Bl等)
    output wire [25:0] id_imm26,         // 26位立即数(长跳转)
    output wire        id_src2_is_imm26, // src2是26位立即数
    output wire        id_src2_is_imm16, // src2是16位立即数
    output wire        id_res_from_dram, // 结果来自数据存储器(load指令)
    output wire        id_src2_is_imm20, // src2是20位立即数
    output wire [19:0] id_imm20,         // 20位立即数
    output wire        id_br_taken,      // 是否需要跳转
    output wire [31:0] id_br_target,     // 跳转目标地址
    output wire        id_src1_from_ref, // src1操作数是否来自寄存器堆
    output wire        id_src2_from_ref, // src2操作数是否来自寄存器堆
    output wire        id_zero_extend,   // src2是立即数时，需要零扩展为1
    output wire        id_rdram_need_zero_extend,  // load指令需要零扩展
    output wire        id_rdram_need_signed_extend,// load指令需要符号扩展
    output wire [1:0]  id_rdram_num,     // load指令类型: ld.w=0, ld.b/ld.bu=1, ld.h/ld.hu=2
    output wire [1:0]  id_wdram_num,     // store指令类型: st.w=0, st.b/st.bu=1, st.h/st.hu=2
    
    // 新增CSR相关输出
    output wire [13:0] id_csr_num,       // csr读地址或者写地址
    output wire        id_csr_we,        // csr写使能
    output wire        id_is_ertn,       // 是否是ertn指令
    output wire        id_is_syscall,    // 是否是系统调用异常
    output wire        id_res_from_csr,  // 结果来自CSR寄存器
    output wire        id_csr_mask_all_one, // csrxchg指令是0，其余是1
    output wire        id_ex_adef,       // 取指令地址错误异常(最低两位不是00)
    output wire        id_ex_brk,        // break指令异常
    output wire        id_ex_ine,        // 非法指令异常
    output wire        id_ex_ale_h,      // 半字地址不对齐异常
    output wire        id_ex_ale_w,      // 字地址不对齐异常
    output wire        id_has_int,       // 检测到中断
    output wire        id_res_is_rj,     // 只对应rdcntid指令，写寄存器的地址是rj
    output wire [31:0] id_res_of_cnt,    // 对应三个将counter64相关数据写入寄存器的指令
    output wire        id_res_from_cnt ,  // 结果来自计数器
    output wire         id_res_from_tid
);


    wire [5:0] op_31_26;
    wire [3:0] op_25_22;
    wire [1:0] op_21_20;
    wire [4:0] op_19_15;
    // 处理csrrd、csrwr、csrxchg指令新加字段
    wire [1:0] op_25_24;    
    wire [4:0] op_9_5;
    // 处理ertn指令新加字段
    wire [4:0] op_14_10;
    wire [4:0] op_4_0;

    wire [63:0] op_31_26_d;
    wire [15:0] op_25_22_d;
    wire [3:0] op_21_20_d;
    wire [31:0] op_19_15_d;
    // 处理csrrd、csrwr、csrxchg指令新加字段
    wire [3:0]  op_25_24_d;
    wire [31:0] op_9_5_d;
    // 处理ertn指令新加字段
    wire [31:0] op_14_10_d;
    wire [31:0] op_4_0_d;



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
    // 新增的算术逻辑运算类指令
    wire        inst_slti;     // 立即数有符号比较
    wire        inst_sltui;    // 立即数无符号比较
    wire        inst_andi;     // 立即数与运算
    wire        inst_ori;      // 立即数或运算
    wire        inst_xori;     // 立即数异或运算
    wire        inst_sll;      // 寄存器移位(左移)
    wire        inst_srl;      // 寄存器移位(逻辑右移)
    wire        inst_sra;      // 寄存器移位(算术右移)
    wire        inst_pcaddu12i; // PC相对地址计算    
    // 新增的乘除运算类指令
    wire        inst_mul_w;    // 乘法(低32位)
    wire        inst_mulh_w;   // 乘法(高32位，有符号)
    wire        inst_mulh_wu;  // 乘法(高32位，无符号)
    wire        inst_div_w;    // 有符号除法
    wire        inst_mod_w;    // 有符号取模
    wire        inst_div_wu;   // 无符号除法
    wire        inst_mod_wu;   // 无符号取模    
    // 新增的转移指令
    wire        inst_blt;      // 有符号小于跳转
    wire        inst_bge;      // 有符号大于等于跳转
    wire        inst_bltu;     // 无符号小于跳转
    wire        inst_bgeu;     // 无符号大于等于跳转    
    // 新增的访存指令
    wire        inst_ld_b;     // 加载字节
    wire        inst_ld_h;     // 加载半字
    wire        inst_ld_bu;    // 加载无符号字节
    wire        inst_ld_hu;    // 加载无符号半字
    wire        inst_st_b;     // 存储字节
    wire        inst_st_h;     // 存储半字

    // CSR操作指令 
    wire        inst_csrrd;    // CSR读指令
    wire        inst_csrwr;    // CSR写指令
    wire        inst_csrxchg;  // CSR原子修改指令
    wire        inst_ertn;     // 异常返回指令
    // 计数器指令
    wire        inst_rdcntvl_w;  // 读取计数器低32位
    wire        inst_rdcntvh_w;  // 读取计数器高32位
    wire        inst_rdcntid;    // 读取计数器ID
    //系统指令
    wire        inst_syscall;
    wire        inst_break;

    // 指令字段提取
    assign op_31_26 = id_inst[31:26];  
    assign op_25_22 = id_inst[25:22];  
    assign op_25_24 = id_inst[25:24];  
    assign op_21_20 = id_inst[21:20];  
    assign op_19_15 = id_inst[19:15];  
    assign op_14_10 = id_inst[14:10];  // 新增：rk字段
    assign op_9_5   = id_inst[9:5];    // 新增：rj字段
    assign op_4_0   = id_inst[4:0];    // 新增：rd字段
    assign id_rd = inst_rdcntid ? id_inst[9:5] :  // rdcntid使用rj作为目标
              inst_bl ? 5'd1 :               // bl指令固定使用r1
              id_inst[4:0];                  // 默认使用rd字段
    assign id_rj = id_inst[9:5];
    assign id_rk = id_inst[14:10];
    // 立即数提取
    assign id_imm5  = id_inst[14:10];
    assign id_imm12 = id_inst[21:10];
    assign id_imm16 = id_inst[25:10];
    assign id_imm20 = id_inst[24:5];
    assign id_imm26 = {id_inst[9:0], id_inst[25:10]};
    // CSR相关字段提取
    assign id_csr_num = id_inst[23:10];           // 14位CSR寄存器编号

                          

    // 解码器实例化
    decoder_6_64 u_dec0(.in(op_31_26), .out(op_31_26_d));    
    decoder_4_16 u_dec1(.in(op_25_22), .out(op_25_22_d));    
    decoder_2_4  u_dec2(.in(op_21_20), .out(op_21_20_d));    
    decoder_5_32 u_dec3(.in(op_19_15), .out(op_19_15_d));    
    decoder_2_4  u_dec4(.in(op_25_24), .out(op_25_24_d));   
    decoder_5_32 u_dec5(.in(op_14_10), .out(op_14_10_d));    // rk字段
    decoder_5_32 u_dec6(.in(op_9_5), .out(op_9_5_d));        // rj字段
    decoder_5_32 u_dec7(.in(op_4_0), .out(op_4_0_d));        // rd字段

    // 指令解码
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
    // 新增算术逻辑运算类指令解码
    assign inst_slti   = op_31_26_d[6'h00] & op_25_22_d[4'h8];       // slti
    assign inst_sltui  = op_31_26_d[6'h00] & op_25_22_d[4'h9];       // sltui
    assign inst_andi   = op_31_26_d[6'h00] & op_25_22_d[4'hd];       // andi
    assign inst_ori    = op_31_26_d[6'h00] & op_25_22_d[4'he];       // ori
    assign inst_xori   = op_31_26_d[6'h00] & op_25_22_d[4'hf];       // xori
    assign inst_sll    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0e]; // sll
    assign inst_srl    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f]; // srl
    assign inst_sra    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10]; // sra
    assign inst_pcaddu12i = op_31_26_d[6'h07] & ~id_inst[25];        // pcaddu12i    
    // 新增乘除运算类指令解码
    assign inst_mul_w   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18]; // mul.w
    assign inst_mulh_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h19]; // mulh.w
    assign inst_mulh_wu = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h1a]; // mulh.wu
    assign inst_div_w   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h00]; // div.w
    assign inst_mod_w   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h01]; // mod.w
    assign inst_div_wu  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h02]; // div.wu
    assign inst_mod_wu  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h03]; // mod.wu    
    // 新增转移指令解码
    assign inst_blt     = op_31_26_d[6'h18];  // blt
    assign inst_bge     = op_31_26_d[6'h19];  // bge
    assign inst_bltu    = op_31_26_d[6'h1a];  // bltu
    assign inst_bgeu    = op_31_26_d[6'h1b];  // bgeu    
    // 新增访存指令解码
    assign inst_ld_b    = op_31_26_d[6'h0a] & op_25_22_d[4'h0];  // ld.b
    assign inst_ld_h    = op_31_26_d[6'h0a] & op_25_22_d[4'h1];  // ld.h
    assign inst_ld_bu   = op_31_26_d[6'h0a] & op_25_22_d[4'h8];  // ld.bu
    assign inst_ld_hu   = op_31_26_d[6'h0a] & op_25_22_d[4'h9];  // ld.hu
    assign inst_st_b    = op_31_26_d[6'h0a] & op_25_22_d[4'h4];  // st.b
    assign inst_st_h    = op_31_26_d[6'h0a] & op_25_22_d[4'h5];  // st.h
    // 新增CSR指令解码
    assign inst_csrrd   = op_31_26_d[6'h01] & op_25_24_d[2'h0] & op_9_5_d[5'h00];  // csrrd
    assign inst_csrwr   = op_31_26_d[6'h01] & op_25_24_d[2'h0] & op_9_5_d[5'h01];  // csrwr
    assign inst_csrxchg = op_31_26_d[6'h01] & op_25_24_d[2'h0] & ~op_9_5_d[5'h00] & ~op_9_5_d[5'h01];// csrxchg
    assign inst_ertn    = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & op_14_10_d[5'h0e] & op_9_5_d[5'h00] & op_4_0_d[5'h00]; // ertn
    // 新增计数器指令解码
    assign inst_rdcntvl_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & op_14_10_d[5'h18] & op_9_5_d[5'h00]; // rdcntvl.w
    assign inst_rdcntvh_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & op_14_10_d[5'h19] & op_9_5_d[5'h00]; // rdcntvh.w
    assign inst_rdcntid   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & op_14_10_d[5'h18] & op_4_0_d[5'h00]; // rdcntid
    // 新增系统指令解码
    assign inst_syscall = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h16]; // syscall
    assign inst_break = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h14]; // break

    


// ALU操作码生成
assign id_alu_op = 
    inst_sub_w      ? 5'd1  :   // 1: src1-src2 (sub.w)
    (inst_slt || inst_slti)     ? 5'd2  :   // 2: 有符号比较 (slt, slti)
    (inst_sltu || inst_sltui)   ? 5'd3  :   // 3: 无符号比较 (sltu, sltui)
    (inst_and || inst_andi)     ? 5'd4  :   // 4: 与运算 (and, andi)
    (inst_or || inst_ori)       ? 5'd5  :   // 5: 或运算 (or, ori)
    inst_nor        ? 5'd6  :   // 6: 或非运算 (nor)
    (inst_xor || inst_xori)     ? 5'd7  :   // 7: 异或运算 (xor, xori)
    (inst_slli_w || inst_sll)   ? 5'd8  :   // 8: 逻辑左移 (slli.w, sll)
    (inst_srli_w || inst_srl)   ? 5'd9  :   // 9: 逻辑右移 (srli.w, srl)
    (inst_srai_w || inst_sra)   ? 5'd10 :   // 10: 算术右移 (srai.w, sra)
    inst_beq        ? 5'd11 :   // 11: 相等跳转 (beq)
    inst_bne        ? 5'd12 :   // 12: 不等跳转 (bne)
    (inst_b || inst_bl) ? 5'd13 :   // 13: 无条件跳转 (b, bl)
    inst_jirl       ? 5'd14 :   // 14: 跳转并链接 (jirl)
    inst_lu12i_w    ? 5'd15 :   // 15: 立即数加载高位 (lu12i.w)
    inst_pcaddu12i  ? 5'd16 :   // 16: PC相对地址计算 (pcaddu12i)
    inst_mul_w      ? 5'd17 :   // 17: 乘法低32位 (mul.w)
    inst_mulh_w     ? 5'd18 :   // 18: 有符号乘法高32位 (mulh.w)
    inst_mulh_wu    ? 5'd19 :   // 19: 无符号乘法高32位 (mulh.wu)
    inst_div_w      ? 5'd20 :   // 20: 有符号除法 (div.w)
    inst_div_wu     ? 5'd21 :   // 21: 无符号除法 (div.wu)
    inst_mod_w      ? 5'd22 :   // 22: 有符号取模 (mod.w)
    inst_mod_wu     ? 5'd23 :   // 23: 无符号取模 (mod.wu)
    5'd0;                      // 0: src1+src2 (add.w, addi.w, ld.w, st.w等)

    // 立即数类型判断
    assign id_src2_is_imm5   = inst_slli_w | inst_srli_w | inst_srai_w ;
    assign id_src2_is_imm12  = inst_addi_w | inst_ld_w | inst_st_w | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu | 
                         inst_st_b | inst_st_h | inst_slti | inst_sltui | inst_andi | inst_ori | inst_xori;
    assign id_src2_is_imm16  = inst_jirl | inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu;
    assign id_src2_is_imm20  = inst_lu12i_w | inst_pcaddu12i;
    assign id_src2_is_imm26  = inst_b | inst_bl;
   
    // 寄存器写使能（新增CSR和计数器指令）
    assign id_ref_we = (inst_add_w | inst_sub_w | inst_slt | inst_sltu | inst_nor | 
                    inst_and | inst_or | inst_xor | inst_slli_w | inst_srli_w | 
                    inst_srai_w | inst_addi_w | inst_ld_w | inst_lu12i_w | inst_jirl | inst_bl |
                    inst_slti | inst_sltui | inst_andi | inst_ori | inst_xori |
                    inst_sll | inst_srl | inst_sra | inst_pcaddu12i |
                    inst_mul_w | inst_mulh_w | inst_mulh_wu | inst_div_w | inst_mod_w | 
                    inst_div_wu | inst_mod_wu |
                    inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu |
                    // 新增指令
                    inst_rdcntvl_w | inst_rdcntvh_w | inst_rdcntid |
                    inst_csrrd | inst_csrwr | inst_csrxchg) && id_ex_adef!=1'b1 ;

    // 存储器访问控制（保持不变）
    assign id_dram_we = (inst_st_w | inst_st_b | inst_st_h)&&id_ex_adef!=1'b1;
    assign id_dram_re = inst_ld_w | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu;
    assign id_res_from_dram = inst_ld_w | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu;
    // 新增结果来源选择
    assign id_res_from_csr = inst_csrrd | inst_csrwr | inst_csrxchg;
    assign id_res_from_cnt = inst_rdcntvl_w | inst_rdcntvh_w ;
    assign id_res_from_tid = inst_rdcntid;
    // 计数器结果选择
    assign id_res_of_cnt = inst_rdcntvl_w ? csr_timer_64[31:0] :
                          inst_rdcntvh_w ? csr_timer_64[63:32] :
                          32'b0;

    assign id_res_is_rj = 0;  // 只有rdcntid使用rj作为目标

    // CSR控制信号
    assign id_csr_we = inst_csrwr | inst_csrxchg | inst_ertn;
    assign id_is_ertn = inst_ertn;
    assign id_is_syscall = inst_syscall;
    assign id_csr_mask_all_one = ~inst_csrxchg; // csrxchg为0，其他CSR操作为1
   

    assign id_src2_is_rd = inst_beq | inst_bne | inst_st_w | inst_st_b | inst_st_h | 
                     inst_blt | inst_bge | inst_bltu | inst_bgeu | inst_csrwr | inst_csrxchg ;


    // 偏移量计算
    wire [31:0] id_offset;
    wire [17:0] id_imm16_extend;
    wire [27:0] id_imm26_extend;
    assign id_imm16_extend = {id_imm16, 2'b00};
    assign id_imm26_extend = {id_imm26, 2'b00};
    
    assign id_offset = id_src2_is_imm12  ? {{20{id_imm12[11]}}, id_imm12} :
                  id_src2_is_imm5   ? {{27{id_imm5[4]}}, id_imm5} :
                  id_src2_is_imm26  ?  {{4{id_imm26_extend[27]}}, id_imm26_extend}:
                  id_src2_is_imm16  ?  {{14{id_imm16_extend[17]}}, id_imm16_extend} :
                  id_src2_is_imm20  ? id_imm20 :
                                       id_src2;

    // 分支控制
    assign id_br_taken = (inst_beq  && (id_rf_rdata1 == id_rf_rdata2)) ||
                (inst_bne  && (id_rf_rdata1 != id_rf_rdata2)) ||
                (inst_blt  && ($signed(id_rf_rdata1) < $signed(id_rf_rdata2))) ||
                (inst_bge  && ($signed(id_rf_rdata1) >= $signed(id_rf_rdata2))) ||
                (inst_bltu && (id_rf_rdata1 < id_rf_rdata2)) ||
                (inst_bgeu && (id_rf_rdata1 >= id_rf_rdata2)) ||
                inst_b || inst_bl || inst_jirl; 
    
    assign id_br_target = (inst_b || inst_bl || inst_beq || inst_bne || 
                    inst_blt || inst_bge || inst_bltu || inst_bgeu) ? id_pc + id_offset :
                    inst_jirl ? id_rf_rdata1 + id_offset :
                    32'h0;

    // 操作数来源判断
    assign id_src1_from_ref = inst_add_w | inst_sub_w | inst_addi_w | inst_slt | inst_sltu | 
                        inst_or | inst_nor | inst_and | inst_xor | inst_slli_w | inst_srai_w | 
                        inst_srli_w | inst_beq | inst_bne | inst_jirl | inst_ld_w | inst_st_w |
                        inst_slti | inst_sltui | inst_andi | inst_ori | inst_xori |
                        inst_sll | inst_srl | inst_sra |
                        inst_mul_w | inst_mulh_w | inst_mulh_wu | inst_div_w | inst_mod_w |
                        inst_div_wu | inst_mod_wu |
                        inst_blt | inst_bge | inst_bltu | inst_bgeu |
                        inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu | 
                        inst_st_b | inst_st_h |
                        inst_csrxchg;  // 需要读取rj寄存器

    assign id_src2_from_ref = inst_add_w | inst_sub_w | inst_lu12i_w | inst_slt | inst_sltu |
                        inst_or | inst_nor | inst_and | inst_xor | inst_beq | inst_bne | 
                        inst_lu12i_w | inst_st_w | inst_ld_w |
                        inst_sll | inst_srl | inst_sra |
                        inst_mul_w | inst_mulh_w | inst_mulh_wu | inst_div_w | inst_mod_w |
                        inst_div_wu | inst_mod_wu |
                        inst_blt | inst_bge | inst_bltu | inst_bgeu |
                        inst_st_b | inst_st_h | inst_csrwr | inst_csrxchg;
                

    // 立即数零扩展指令
    assign id_zero_extend = inst_andi | inst_ori | inst_xori | inst_pcaddu12i;

    // 存储器访问扩展控制
    assign id_rdram_need_zero_extend = inst_ld_bu | inst_ld_hu;
    assign id_rdram_need_signed_extend = inst_ld_b | inst_ld_h;
    
    // load/store指令类型编码
    assign id_rdram_num = inst_ld_w ? 2'b00 : 
                         (inst_ld_b | inst_ld_bu) ? 2'b10 :
                         (inst_ld_h | inst_ld_hu) ? 2'b01 :  
                         2'b11; //其他情况
    assign id_wdram_num = inst_st_w ? 2'b00 : 
                         (inst_st_b ) ? 2'b01 :
                         (inst_st_h ) ? 2'b10 :  
                         2'b11; //其他情况

    assign id_ex_adef = (id_pc[1:0] != 2'b00);
    // 半字地址不对齐异常（最低位不为0）
    assign id_ex_ale_h = (inst_ld_h | inst_ld_hu | inst_st_h) ;
    // 字地址不对齐异常（最低两位不为00） 
    assign id_ex_ale_w = (inst_ld_w | inst_st_w);
    assign id_ex_brk = inst_break;// 异常检测信号
    assign id_ex_ine = ~(
    // 基本算术逻辑指令
    inst_add_w | inst_sub_w | inst_slt | inst_sltu |
    inst_nor | inst_and | inst_or | inst_xor |    
    // 移位指令
    inst_slli_w | inst_srli_w | inst_srai_w |
    inst_sll | inst_srl | inst_sra |    
    // 立即数指令
    inst_addi_w | inst_slti | inst_sltui |
    inst_andi | inst_ori | inst_xori |    
    // 乘除指令
    inst_mul_w | inst_mulh_w | inst_mulh_wu |
    inst_div_w | inst_mod_w | inst_div_wu | inst_mod_wu |    
    // 转移指令
    inst_jirl | inst_b | inst_bl |
    inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu |    
    // 访存指令
    inst_ld_w | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu |
    inst_st_w | inst_st_b | inst_st_h |    
    // 特殊指令
    inst_lu12i_w | inst_pcaddu12i |    
    // CSR指令
    inst_csrrd | inst_csrwr | inst_csrxchg | inst_ertn |    
    // 计数器指令
    inst_rdcntvl_w | inst_rdcntvh_w | inst_rdcntid |    
    // 系统指令
    inst_syscall | inst_break)&&(id_pc!=32'h1bfffffc);// 非法指令异常
    assign id_has_int = ((csr_estat_is[12:0] & csr_ecfg_lie[12:0]) != 13'b0)
                    && (csr_crmd_ie == 1'b1); // 检测中断


endmodule