module mycpu_top(
    input  wire        aclk,
    input  wire        aresetn,  // low active

    // AXI Read Address Channel
    output wire [3:0]  arid,
    output wire [31:0] araddr,
    output wire [7:0]  arlen,
    output wire [2:0]  arsize,
    output wire [1:0]  arburst,
    output wire [1:0]  arlock,
    output wire [3:0]  arcache,
    output wire [2:0]  arprot,
    output wire        arvalid,
    input  wire        arready,

    // AXI Read Data Channel
    input  wire [3:0]  rid,
    input  wire [31:0] rdata,
    input  wire [1:0]  rresp,
    input  wire        rlast,
    input  wire        rvalid,
    output wire        rready,

    // AXI Write Address Channel
    output wire [3:0]  awid,
    output wire [31:0] awaddr,
    output wire [7:0]  awlen,
    output wire [2:0]  awsize,
    output wire [1:0]  awburst,
    output wire [1:0]  awlock,
    output wire [3:0]  awcache,
    output wire [2:0]  awprot,
    output wire        awvalid,
    input  wire        awready,

    // AXI Write Data Channel
    output wire [3:0]  wid,
    output wire [31:0] wdata,
    output wire [3:0]  wstrb,
    output wire        wlast,
    output wire        wvalid,
    input  wire        wready,

    // AXI Write Response Channel
    input  wire [3:0]  bid,
    input  wire [1:0]  bresp,
    input  wire        bvalid,
    output wire        bready,

    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    wire        inst_sram_req;
    wire        inst_sram_wr;
    wire [1:0]  inst_sram_size;
    wire [3:0]  inst_sram_wstrb;
    wire [31:0] inst_sram_addr;
    wire [31:0] inst_sram_wdata;
    wire        inst_sram_data_ok;
    wire        inst_sram_addr_ok;
    wire [31:0] inst_sram_rdata;
    wire        data_sram_req;
    wire        data_sram_wr;
    wire [1:0]  data_sram_size;
    wire [3:0]  data_sram_wstrb;
    wire [31:0] data_sram_addr;
    wire [31:0] data_sram_wdata;
    wire        data_sram_data_ok;
    wire        data_sram_addr_ok;
    wire [31:0] data_sram_rdata;
    wire clk;
    wire [4:0] rf_raddr1;
    wire [4:0] rf_raddr2;
    wire [31:0] rf_wdata;
    wire [31:0] rf_rdata1;
    wire [31:0] rf_rdata2;

    assign clk = aclk;


    assign inst_sram_wr=1'b0;
    assign inst_sram_size=2'd2;
    assign inst_sram_wdata=32'b0;
    assign inst_sram_wstrb=4'b0;
    assign inst_sram_req= if_allow_in & inst_req_valid & pc_inst_en & (~pipline_is_not_stalled===1'b0);
  
    wire if_allow_in;
    wire id_allow_in;
    wire exe_allow_in;
    wire mem_allow_in;
    wire wb_allow_in;
    wire [31:0]csr_era_pc;
    wire rst;
    wire [31:0] pc_br_target;
    wire pc_br_taken;
    wire [31:0]pc_inst_addr;
    wire pc_inst_en;
    wire [31:0] if_pc;
    assign rst = ~aresetn;
    wire inst_req_valid;//1表示还没给inst_dram发�?�请求，1表示已经给inst_dram发�?�请求，但还没有返回
    wire wb_ready_go;
    wire if_ready_go;
    wire id_ready_go;
    wire exe_ready_go;
    wire mem_ready_go; 
    wire pre_if_ready_go;
    wire [1:0]id_need_cancel;          //下一条流入id_stage的指令需要取�?
    //wire if_allow_in;
    wire pipline_is_not_stalled;
    wire id_inst_cancel;
    wire exe_addr_shake_ok;
    wire mem_data_shake_ok;
    wire IF_ready_go;
    wire ID_ready_go;
    wire EXE_ready_go;
    wire mem_need_and_data_ok;
    
    PC_Reg pc_reg(
        .clk(clk),
        .rst(rst),
        .if_allow_in(if_allow_in),
        .wb_ready_go(wb_ready_go),
        .pre_if_ready_go(pre_if_ready_go),
        .pipline_is_not_stalled(pipline_is_not_stalled),
        .if_pc(if_pc),
        .inst_en(pc_inst_en),
        .wb_ex(wb_ex),
        .pc_br_taken(pc_br_taken),
        .pc_br_target(pc_br_target),
        .inst_addr(inst_sram_addr)
    );

  
        
    

    wire [31:0] id_inst;
    wire [31:0] id_pc;
    wire [31:0] if_inst;
    wire ID_need_cancel;
    ID_Reg id_reg(
        .clk(clk),
        .rst(rst),
        .wb_is_ertn(wb_is_ertn),
        .if_ready_go(if_ready_go),
        .exe_allow_in(exe_allow_in),
        .exe_addr_shake_ok(exe_addr_shake_ok),
        .exe_data_ram_req(data_sram_req),
        .exe_data_ram_addr_ok(data_sram_addr_ok),
        .id_inst_cancel(id_inst_cancel),
        .pipline_is_not_stalled(pipline_is_not_stalled),
        .id_allow_in(id_allow_in),
        .id_need_cancel(id_need_cancel),
        .if_pc(if_pc),
        .if_inst(if_inst),
        .id_inst(id_inst),
        .id_pc(id_pc),
        .wb_ex(wb_ex),
        .ID_need_cancel(ID_need_cancel)
    );
    reg [31:0] inst_sram_rdata_reg;
    assign if_inst = inst_sram_rdata_reg;

    always @(*) begin
         casez (id_br_taken)
                 1'b1: inst_sram_rdata_reg = inst_sram_rdata;
                1'b0, 1'bx, 1'bz: inst_sram_rdata_reg = inst_sram_rdata; // 保持原�??
         endcase
    end

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
   // wire id_cancel;   //跳转的话，需要置�?????1
    wire id_br_taken;
    wire [31:0]id_br_target;
    wire id_src1_from_ref;
    wire id_src2_from_ref;
    wire id_zero_extend; //如果第二个操作数是立即数，�?�且�??要零扩展，是的话�??1，否则的话为0
    wire id_rdram_need_zero_extend;
    wire id_rdram_need_signed_extend;
    wire [1:0]id_rdram_num; //如果是ld类指令，ld.w�??0，ld.b,ld.bu�??1，ld.h,ld.hu�??2
    wire [1:0]id_wdram_num; //如果是st类指令，st.w�??0，ld.b,ld.bu�??1，ld.h,ld.hu�??2

    wire [13:0] id_csr_num;
    wire id_csr_we;
    wire id_is_ertn;
    wire id_is_syscall;
    wire id_res_from_csr;
    wire [31:0]id_csr_wdata;
    wire [31:0]id_csr_wmask;
    wire id_csr_mask_all_one;
    wire id_ex_adef;
    wire id_ex_brk;
    wire id_ex_ine;
    wire id_ex_ale_h;
    wire id_ex_ale_w;
    wire id_has_int;
    wire [63:0] csr_tid_tid;
    wire [63:0] csr_timer_64;
    wire [31:0] id_res_of_cnt;
    wire id_res_from_cnt;
    //wire [31:0]id_csr_rdata;
    wire id_res_from_tid;
    wire id_need_data_sram;

    ID_stage id_stage(
        .id_inst(id_inst),    //Input:输入的指�??
        .id_pc(id_pc),        //Input:当前指令的pc
        .csr_estat_is(csr_estat_is),       //新增
        .csr_ecfg_lie(csr_ecfg_lie),       //新增
        .csr_crmd_ie(csr_crmd_ie),         //新增
        .csr_timer_64(csr_timer_64),       //新增�??64位计数器的数�??
       // .csr_tid_tid(csr_tid_tid),         //新增�??64位计数器的编�??
        .id_rj(id_rj),        //output：寄存器rj的地�??
        .id_rk(id_rk),        //output：rk的地�??
        .id_rd(id_rd),        //output：rd的地�??，记得指令为bl时将id_rd设置�??1(已实�??)
        .id_rf_rdata1(rf_rdata1),     //Input：从寄存器读到的源操作数1�??
        .id_rf_rdata2(rf_rdata2),     //Input:从寄存器读到的源操作�??2,
        .id_ref_we(id_ref_we),        //Output:是否�??要写寄存�??
        .id_alu_op(id_alu_op),        //Output:alu的op信号，对照表在word�??
        .id_dram_we(id_dram_we),      //Output(下边的都是output):是否�??要写dram
        .id_dram_re(id_dram_re),      //是否�??要读dram
        // .id_src1(id_src1),              //可以先不�??
        // .id_src2(id_src2),          //可以先不�??
        .id_src2_is_imm12(id_src2_is_imm12),         //以下为立即数的控制信�??
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
        .id_imm20(id_imm20),      
        .id_br_taken(id_br_taken),                //是否�??要跳�??
        .id_br_target(id_br_target),              //跳转的地�??，（由于流水线要处理冒险，故我把跳转模块从exe_stage挪到了id_stage�??)
        .id_src1_from_ref(id_src1_from_ref),      //�??1个源操作数是否来自寄存器堆，
        .id_src2_from_ref(id_src2_from_ref),      //�??2个源操作数是否来自寄存器堆，这个和id_src1_from_ref的生成方法要看下"exp8-9"word,
        .id_zero_extend(id_zero_extend),          //src2是立即数的话，是�??要符号扩展还是零扩展，零扩展的话�??1
        .id_rdram_need_zero_extend(id_rdram_need_zero_extend),
        .id_rdram_need_signed_extend(id_rdram_need_signed_extend),  //�??3个信号是ld类指令，�??要将dada_ram数据写入寄存器堆时，对data_ram中读到的数据的处理信�??
        .id_rdram_num(id_rdram_num),             //如果是ld类指令，ld.w�??0，ld.b,ld.bu�??1，ld.h,ld.hu�??2
        .id_wdram_num(id_wdram_num),              //如果是st类指令，st.w�??0，ld.b,ld.bu�??1，ld.h,ld.hu�??2

        .id_csr_num(id_csr_num),                   //csr读地�??或�?�写地址
        .id_csr_we(id_csr_we),                     //csr写使�??
        .id_is_ertn(id_is_ertn) ,                 //是否是ertn
        .id_is_syscall(id_is_syscall) ,           //是否是系统调用异�??
        .id_res_from_csr(id_res_from_csr),     //与id_res_from_dram类似，这里最后要写回通用寄存器的数据可能来自csr寄存器，是的话置1
        .id_csr_mask_all_one(id_csr_mask_all_one),       //csrxchg指令�??0，其余是1
        .id_ex_adef(id_ex_adef),                         //�??测取指令的地�??错了没？即最低两位不�??00的话赋�?�为1
        .id_ex_brk(id_ex_brk),                          //与syscall指令类似，只要译码出来是break指令，就�??1
        .id_ex_ine(id_ex_ine),                           //指令地址虽然正确，但取出来的指令不存�??,不是任何�??条指�??
        .id_ex_ale_h(id_ex_ale_h),                       //ld.h,ld.hu,st.h时置1
        .id_ex_ale_w(id_ex_ale_w),                      // ld.w,st.w时置1，这两条信号是为了方便之后exe级检测地�??不对齐异�??
        .id_has_int(id_has_int),                       //�??测中断，在书�??7.2.1节有示例，注意前边多�??3个来自csr的输入信号需要补�??
        .id_res_is_rj(id_res_is_rj),                   //只对应rdcntid指令，写寄存器的地址是rj
        .id_res_of_cnt(id_res_of_cnt),                  //对应三个将counter64相关数据写入寄存器的指令，如果是那三个指令，就输出要写入寄存器堆的数�??
        .id_res_from_cnt(id_res_from_cnt),              //对应上边三个指令时为1
        .id_res_from_tid(id_res_from_tid),
        .id_need_data_sram(id_need_data_sram)          //对应load,store类指�?
    );
    assign id_dram_wdata=id_src2;
    assign pc_br_taken=id_br_taken|(wb_ex===1'b1)|(wb_is_ertn==1'b1);
    //assign pc_br_target=id_br_target|({32{wb_ex===1'b1}}&csr_rvalue)|({32{wb_is_ertn===1'b1}}&csr_era_pc);
    assign pc_br_target =    wb_is_ertn===1'b1  ?   csr_era_pc  :  
                            wb_ex===1'b1      ?   csr_rvalue  :  id_br_target;
    assign id_csr_wdata=id_src2;
    assign id_csr_wmask = id_csr_mask_all_one? 32'hffffffff : id_src1;
    //assign id_csr_rdata=csr_rvalue;

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
    wire [19:0] exe_imm20;
    wire exe_src2_is_imm20;
    wire [31:0] exe_dram_waddr;
    wire [31:0] exe_rf_src1;
    wire [31:0] exe_rf_src2;
    wire exe_zero_extend;
    wire exe_rdram_need_zero_extend;
    wire exe_rdram_need_signed_extend;
    wire [1:0]exe_rdram_num;
    wire [1:0]exe_wdram_num;

    wire [13:0] exe_csr_num;
    wire exe_csr_we;
    wire exe_is_ertn;
    wire exe_is_syscall;
    wire exe_res_from_csr;
    wire [31:0] exe_csr_wmask;
    wire [31:0] exe_csr_wdata;
    wire exe_ex_ale_h;
    wire exe_ex_ale_w;
    wire exe_ex_ale;
    wire exe_ex_adef;
    wire exe_ex_brk;
    wire exe_ex_ine;
    wire exe_has_int;
    wire [4:0]exe_rj;
    wire [31:0]exe_res_of_cnt;
    wire exe_res_is_rj;
    wire exe_res_from_cnt;
    wire exe_res_from_tid;
    wire exe_need_data_sram;
    wire exe_need_cancel;
    //wire [31:0]exe_csr_rdata;
    ExE_reg exe_reg(
        .clk(clk),
        .rst(rst),
        .wb_ex(wb_ex),
        .wb_is_ertn(wb_is_ertn),
        .id_ready_go(id_ready_go),
        .exe_ready_go(exe_ready_go),
        .mem_allow_in(mem_allow_in),
        .exe_allow_in(exe_allow_in),
        .exe_addr_shake_ok(exe_addr_shake_ok),
        .mem_data_shake_ok(mem_data_shake_ok),
        .mem_need_and_data_ok(mem_need_and_data_ok),
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
        .id_zero_extend(id_zero_extend),
        .id_rdram_need_zero_extend(id_rdram_need_zero_extend),
        .id_rdram_need_signed_extend(id_rdram_need_signed_extend),
        .id_rdram_num(id_rdram_num),
        .id_wdram_num(id_wdram_num),
        .id_csr_num(id_csr_num),
        .id_csr_we(id_csr_we),
        .id_is_ertn(id_is_ertn),
        .id_is_syscall(id_is_syscall),
        .id_res_from_csr(id_res_from_csr),
        .id_csr_wmask(id_csr_wmask),
        .id_csr_wdata(id_csr_wdata),
        .id_ex_adef(id_ex_adef),                        
        .id_ex_brk(id_ex_brk),                         
        .id_ex_ine(id_ex_ine),                           
        .id_ex_ale_h(id_ex_ale_h),                       
        .id_ex_ale_w(id_ex_ale_w),
        .id_has_int(id_has_int),
        .id_rj(id_rj),
        .id_res_of_cnt(id_res_of_cnt),
        .id_res_is_rj(id_res_is_rj),
        .id_res_from_cnt(id_res_from_cnt),
        .id_res_from_tid(id_res_from_tid),
        .id_need_data_sram(id_need_data_sram),
        .id_need_cancel(ID_need_cancel),
        //.id_csr_rdata(id_csr_rdata),
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
        .exe_rf_src2(exe_rf_src2),
        .exe_zero_extend(exe_zero_extend),   
        .exe_rdram_need_zero_extend(exe_rdram_need_zero_extend),
        .exe_rdram_need_signed_extend(exe_rdram_need_signed_extend),
        .exe_rdram_num(exe_rdram_num),
        .exe_wdram_num(exe_wdram_num) ,
        .exe_csr_num(exe_csr_num),
        .exe_csr_we(exe_csr_we),
        .exe_is_ertn(exe_is_ertn),
        .exe_is_syscall(exe_is_sycall),
        .exe_res_from_csr(exe_res_from_csr),
        .exe_csr_wmask(exe_csr_wmask),
        .exe_csr_wdata(exe_csr_wdata),
        .exe_ex_adef(exe_ex_adef),                        
        .exe_ex_brk(exe_ex_brk),                         
        .exe_ex_ine(exe_ex_ine),                           
        .exe_ex_ale_h(exe_ex_ale_h),                       
        .exe_ex_ale_w(exe_ex_ale_w),
        .exe_has_int(exe_has_int),
        .exe_rj(exe_rj),
        .exe_res_of_cnt(exe_res_of_cnt),
        .exe_res_is_rj(exe_res_is_rj),
        .exe_res_from_cnt(exe_res_from_cnt),
        .exe_res_from_tid(exe_res_from_tid),
        .exe_need_data_sram(exe_need_data_sram),
        .exe_need_cancel(exe_need_cancel)
        
    );

    wire [31:0] exe_alu_result;
    wire [31:0] alu_src1;
    wire [31:0] alu_src2;
    wire [31:0]exe_br_target;
    wire exe_br_taken;
    wire [17:0]exe_imm16_extend;
    wire [27:0]exe_imm26_extend;
    assign exe_imm16_extend={exe_imm16,2'b00};
    assign exe_imm26_extend={exe_imm26,2'b00};
    
    assign alu_src1=exe_src1;
    assign alu_src2 = exe_src2_is_imm12  ?  exe_zero_extend?     {20'b0,exe_imm12} :{{20{exe_imm12[11]}}, exe_imm12} :
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
        .alu_rf_src2(exe_rf_src2),
        .exe_ex_ale_h(exe_ex_ale_h),
        .exe_ex_ale_w(exe_ex_ale_w),
        .exe_ex_ale(exe_ex_ale)       //exe_ex_ale_h�??1时，�??测运算结果最低位是否�??0，不是的话置1；exe_ex_ale_w�??0时，�??测运算结果低两位是否�??0，不是就�??1
    );//
    assign exe_dram_waddr = exe_alu_result;
    wire [31:0] mem_alu_result;
    wire  mem_ref_we;
    wire [4:0] mem_rd;
    wire mem_dram_re;
    wire mem_dram_we;
    //wire mem_br_taken;
    //wire [31:0] mem_br_target;
    wire mem_res_from_dram;
    wire [31:0] mem_dram_wdata;
    wire [31:0] mem_dram_waddr;
    wire [31:0] mem_pc;
    wire mem_rdram_need_zero_extend;
    wire mem_rdram_need_signed_extend;
    wire [1:0]mem_rdram_num;
    wire [1:0] mem_wdram_num;
    wire [31:0] mem_dram_rdata;
    wire [13:0] mem_csr_num;
    wire mem_csr_we;
    wire mem_is_ertn;
    wire mem_is_syscall;
    wire mem_res_from_csr;
    wire [31:0] mem_csr_wmask;
    wire [31:0] mem_csr_wdata;
    wire mem_ex_adef;
    wire mem_ex_ale;
    wire mem_ex_brk;
    wire mem_ex_ine;
    wire mem_has_int;
    wire [4:0]mem_rj;
    wire [31:0]mem_res_of_cnt;
    wire mem_res_is_rj;
    wire mem_res_from_cnt;
    wire mem_res_from_tid;
    wire data_req_valid;
    wire mem_need_data_sram;//
    wire mem_ex_ale_h;
    wire mem_ex_ale_w;
    wire [31:0] exe_dram_rdata;
    wire [31:0] exe_data_addr;
    wire [31:0] mem_data_addr;
    wire mem_need_cancel;
    assign exe_data_addr = data_sram_addr ;
   // wire [31:0] mem_csr_rdata;
    Mem_reg mem_reg(
        .clk(clk),
        .rst(rst),
        .wb_ex(wb_ex),
        .wb_is_ertn(wb_is_ertn),
        .exe_ready_go(exe_ready_go),
        .mem_allow_in(mem_allow_in),
        .mem_data_shake_ok(mem_data_shake_ok),
        .exe_alu_result(exe_alu_result),
        .exe_ref_we(exe_ref_we),
        .exe_dram_re(exe_dram_re),
        .exe_dram_we(exe_dram_we),
        .exe_data_addr(exe_data_addr),
        .exe_rd(exe_rd),
        //.exe_br_taken(exe_br_taken),
        //.exe_br_target(exe_br_target),
        .exe_res_from_dram(exe_res_from_dram),
        .exe_dram_waddr(exe_dram_waddr),
        .exe_dram_wdata(exe_dram_wdata),
        .exe_pc(exe_pc),
        .exe_rdram_need_zero_extend(exe_rdram_need_zero_extend),
        .exe_rdram_need_signed_extend(exe_rdram_need_signed_extend),
        .exe_rdram_num(exe_rdram_num),
        .exe_wdram_num(exe_wdram_num),
        .exe_csr_num(exe_csr_num),
        .exe_csr_we(exe_csr_we),
        .exe_is_ertn(exe_is_ertn),
        .exe_is_syscall(exe_is_sycall),
        .exe_res_from_csr(exe_res_from_csr),
        .exe_csr_wmask(exe_csr_wmask),
        .exe_csr_wdata(exe_csr_wdata),
        .exe_ex_adef(exe_ex_adef),                        
        .exe_ex_brk(exe_ex_brk),                         
        .exe_ex_ine(exe_ex_ine),                           
        .exe_ex_ale(exe_ex_ale),   
        .exe_has_int(exe_has_int), 
        .exe_rj(exe_rj),
        .exe_res_of_cnt(exe_res_of_cnt),
        .exe_res_is_rj(exe_res_is_rj),
        .exe_res_from_cnt(exe_res_from_cnt),  
        .exe_res_from_tid(exe_res_from_tid),
        .exe_need_data_sram(exe_need_data_sram),
        .exe_ex_ale_h(exe_ex_ale_h),
        .exe_ex_ale_w(exe_ex_ale_w),
        .exe_need_cancel(exe_need_cancel),
        //.exe_csr_rdata(exe_csr_rdata),                 
        .mem_ref_we(mem_ref_we),
        .mem_alu_result(mem_alu_result),
        .mem_dram_re(mem_dram_re),
        .mem_dram_we(mem_dram_we),
        .mem_rd(mem_rd),
        //.mem_br_taken(mem_br_taken),
        //.mem_br_target(mem_br_target),
        .mem_res_from_dram(mem_res_from_dram),
        .mem_dram_wdata(mem_dram_wdata),
        .mem_dram_waddr(mem_dram_waddr),
        .mem_pc(mem_pc),
        .mem_rdram_need_zero_extend(mem_rdram_need_zero_extend),
        .mem_rdram_need_signed_extend(mem_rdram_need_signed_extend),
        .mem_rdram_num(mem_rdram_num),
        .mem_wdram_num(mem_wdram_num),
        .mem_csr_num(mem_csr_num),
        .mem_csr_we(mem_csr_we),
        .mem_is_ertn(mem_is_ertn),
        .mem_is_syscall(mem_is_syscall),
        .mem_res_from_csr(mem_res_from_csr),
        .mem_csr_wmask(mem_csr_wmask),
        .mem_csr_wdata(mem_csr_wdata),
        .mem_ex_adef(mem_ex_adef),                        
        .mem_ex_brk(mem_ex_brk),                         
        .mem_ex_ine(mem_ex_ine),                           
        .mem_ex_ale(mem_ex_ale),
        .mem_has_int(mem_has_int),
        .mem_rj(mem_rj),
        .mem_res_of_cnt(mem_res_of_cnt),
        .mem_res_is_rj(mem_res_is_rj),
        .mem_res_from_cnt(mem_res_from_cnt),
        .mem_res_from_tid(mem_res_from_tid),
        .mem_need_data_sram(mem_need_data_sram),
        .mem_ex_ale_h(mem_ex_ale_h),
        .mem_ex_ale_w(mem_ex_ale_w),
        .mem_data_addr(mem_data_addr),
        .mem_need_cancel(mem_need_cancel)
    );
    //assign data_sram_addr=mem_alu_result;

    assign mem_dram_rdata=data_sram_rdata;
    assign data_sram_wstrb=(wb_ex===1'b1||exe_ex_ale===1'b1||wb_is_ertn===1'b1)?    4'b0000:
                        (exe_dram_we&&exe_wdram_num==0)? 4'b1111:
                        (exe_dram_we&&exe_wdram_num==1&&data_sram_addr[1:0]==2'b00)?  4'b0001:
                        (exe_dram_we&&exe_wdram_num==1&&data_sram_addr[1:0]==2'b01)?4'b0010:
                        (exe_dram_we&&exe_wdram_num==1&&data_sram_addr[1:0]==2'b10)? 4'b0100:
                        (exe_dram_we&&exe_wdram_num==1&&data_sram_addr[1:0]==2'b11)? 4'b1000:
                        (exe_dram_we&&exe_wdram_num==2&&data_sram_addr[1:0]==2'b00)?4'b0011:
                        (exe_dram_we&&exe_wdram_num==2&&data_sram_addr[1:0]==2'b01)?4'b0110:
                        (exe_dram_we&&exe_wdram_num==2&&data_sram_addr[1:0]==2'b10)?4'b1100:   4'b0000;

    assign data_sram_req=  data_req_valid & exe_need_data_sram & mem_allow_in &&(wb_ex!=1'b1);
    assign data_sram_size = exe_ex_ale_h ? 2'b1 :
                            exe_ex_ale_w ? 2'b10 :  2'b0;
    assign exe_addr_shake_ok = exe_need_data_sram ?  data_sram_req&&(data_sram_addr_ok===1'b1) :  1'b1;
    assign mem_data_shake_ok = mem_need_data_sram ?  (data_sram_data_ok===1'b1) : 1'b1;
    assign data_sram_wr = exe_dram_we;
    assign mem_need_and_data_ok = mem_need_data_sram && (data_sram_data_ok===1'b1);
   // assign data_sram_en=1'b1;
    //assign data_sram_wdata=mem_dram_wdata;
    assign data_sram_wdata =  exe_wdram_num==0?  exe_dram_wdata:
                             exe_wdram_num==1?   {4{exe_dram_wdata[7:0]}} :{2{exe_dram_wdata[15:0]}} ;
    assign data_sram_addr=exe_dram_we? exe_dram_waddr: exe_alu_result;

    wire  wb_rf_we;
    wire [31:0] wb_alu_result;
    wire [4:0] wb_rd;
    //wire [31:0] wb_br_target;
    //wire wb_br_taken;
    wire [31:0]wb_dram_rdata;
    wire wb_res_from_dram;
    wire [31:0] wb_dram_wdata;
    wire [31:0] wb_dram_waddr;
    wire wb_dram_we;
    wire [31:0] wb_pc;
    wire [1:0]wb_rdram_num;
    wire wb_rdram_need_zero_extend;
    wire wb_rdram_need_signed_extend;
    wire [31:0] wb_data_addr;
    wire [13:0] wb_csr_num;
    wire wb_csr_we;
    wire wb_is_ertn;
    wire wb_is_syscall;
    wire wb_res_from_csr;
    wire [31:0] csr_rvalue;
    wire [31:0] wb_csr_wmask;
    wire [31:0] wb_csr_wdata;
    wire wb_ex_adef;
    wire wb_ex_ale;
    wire wb_ex_brk;
    wire wb_ex_ine;
    wire wb_has_int;
    wire wb_res_from_tid;
    wire wb_need_cancel;
    wire [4:0] wb_rj;
    wire [31:0] wb_res_of_cnt;
    
    
   // wire [31:0] wb_csr_rdata;

    Wb_reg wb_reg(
        .clk(clk),
        .rst(rst),
        .wb_ex(wb_ex),
        .mem_ready_go(mem_ready_go),
        .mem_alu_result(mem_alu_result),
        .mem_ref_we(mem_ref_we),
        .mem_rd(mem_rd),
       // .mem_br_taken(mem_br_taken),
        //.mem_br_target(mem_br_target),
        .mem_dram_rdata(mem_dram_rdata),
        .mem_res_from_dram(mem_res_from_dram),
        .mem_dram_wdata(mem_dram_wdata),
        .mem_dram_waddr(mem_dram_waddr),
        .mem_dram_we(mem_dram_we),
        .mem_pc(mem_pc),
        .mem_rdram_num(mem_rdram_num),
        .mem_rdram_need_zero_extend(mem_rdram_need_zero_extend),
        .mem_rdram_need_signed_extend(mem_rdram_need_signed_extend),
        .mem_data_addr(mem_data_addr),
        .mem_csr_num(mem_csr_num),
        .mem_csr_we(mem_csr_we),
        .mem_is_ertn(mem_is_ertn),
        .mem_is_syscall(mem_is_syscall),
        .mem_res_from_csr(mem_res_from_csr),
        .mem_csr_wmask(mem_csr_wmask),
        .mem_csr_wdata(mem_csr_wdata),
        .mem_ex_adef(mem_ex_adef),                        
        .mem_ex_brk(mem_ex_brk),                         
        .mem_ex_ine(mem_ex_ine),                           
        .mem_ex_ale(mem_ex_ale),
        .mem_has_int(mem_has_int),
        .mem_rj(mem_rj),
        .mem_res_of_cnt(mem_res_of_cnt),
        .mem_res_is_rj(mem_res_is_rj),
        .mem_res_from_cnt(mem_res_from_cnt),
        .mem_res_from_tid(mem_res_from_tid),
        .mem_need_cancel(mem_need_cancel),
        //.mem_csr_rdata(mem_csr_rdata),
        .wb_rf_we(wb_rf_we),
        .wb_alu_result(wb_alu_result),
        .wb_rd(wb_rd),
        //.wb_br_taken(wb_br_taken),
        //.wb_br_target(wb_br_target),
        .wb_dram_rdata(wb_dram_rdata),
        .wb_res_from_dram(wb_res_from_dram),
        .wb_dram_waddr(wb_dram_waddr),
        .wb_dram_wdata(wb_dram_wdata),
        .wb_dram_we(wb_dram_we),
        .wb_pc(wb_pc),
        .wb_rdram_num(wb_rdram_num),
        .wb_rdram_need_signed_extend(wb_rdram_need_signed_extend),
        .wb_rdram_need_zero_extend(wb_rdram_need_zero_extend),
        .wb_data_addr(wb_data_addr),
        .wb_csr_num(wb_csr_num),
        .wb_csr_we(wb_csr_we),
        .wb_is_ertn(wb_is_ertn),
        .wb_is_syscall(wb_is_syscall),
        .wb_res_from_csr(wb_res_from_csr),
        .wb_csr_wmask(wb_csr_wmask),
        .wb_csr_wdata(wb_csr_wdata),
        .wb_ex_adef(wb_ex_adef),                        
        .wb_ex_brk(wb_ex_brk),                         
        .wb_ex_ine(wb_ex_ine),                           
        .wb_ex_ale(wb_ex_ale),
        .wb_has_int(wb_has_int),
        .wb_rj(wb_rj),
        .wb_res_of_cnt(wb_res_of_cnt),
        .wb_res_is_rj(wb_res_is_rj),
        .wb_res_from_cnt(wb_res_from_cnt),
        .wb_res_from_tid(wb_res_from_tid),
        .wb_need_cancel(wb_need_cancel)
        
    );
    


    wire [31:0] mem_to_rf_data;
    wire rf_we;
    assign rf_we = (wb_ex_ale===1'b1) ? 1'b0  :  wb_rf_we;
    assign mem_to_rf_data = wb_rdram_num==0 ?   wb_dram_rdata :
                            (wb_rdram_num==1&&wb_data_addr[1:0]==2'b00&&wb_rdram_need_signed_extend) ?  {{16{wb_dram_rdata[15]}},wb_dram_rdata[15:0]}   :
                            (wb_rdram_num==1&&wb_data_addr[1:0]==2'b00&&wb_rdram_need_zero_extend) ?  {{16{1'b0}},wb_dram_rdata[15:0]}   :
                            (wb_rdram_num==1&&wb_data_addr[1:0]==2'b01&&wb_rdram_need_signed_extend) ?  {{16{wb_dram_rdata[23]}},wb_dram_rdata[23:8]}   :
                            (wb_rdram_num==1&&wb_data_addr[1:0]==2'b01&&wb_rdram_need_zero_extend) ?  {{16{1'b0}},wb_dram_rdata[23:8]}   :
                            (wb_rdram_num==1&&wb_data_addr[1:0]==2'b10&&wb_rdram_need_signed_extend) ?  {{16{wb_dram_rdata[31]}},wb_dram_rdata[31:16]}   :
                            (wb_rdram_num==1&&wb_data_addr[1:0]==2'b10&&wb_rdram_need_zero_extend) ?  {{16{1'b0}},wb_dram_rdata[31:16]}   :                   
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b00&&wb_rdram_need_signed_extend) ?  {{24{wb_dram_rdata[7]}},wb_dram_rdata[7:0]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b00&&wb_rdram_need_zero_extend) ?  {{24{1'b0}},wb_dram_rdata[7:0]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b01&&wb_rdram_need_signed_extend) ?  {{24{wb_dram_rdata[15]}},wb_dram_rdata[15:8]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b01&&wb_rdram_need_zero_extend) ?  {{24{1'b0}},wb_dram_rdata[15:8]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b10&&wb_rdram_need_signed_extend) ?  {{24{wb_dram_rdata[23]}},wb_dram_rdata[23:16]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b10&&wb_rdram_need_zero_extend) ?  {{24{1'b0}},wb_dram_rdata[23:16]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b11&&wb_rdram_need_signed_extend) ?  {{24{wb_dram_rdata[31]}},wb_dram_rdata[31:24]}   :
                            (wb_rdram_num==2&&wb_data_addr[1:0]==2'b11&&wb_rdram_need_zero_extend) ?  {{24{1'b0}},wb_dram_rdata[31:24]}   : 32'b0;

    assign rf_raddr1 = id_rj;
    assign rf_raddr2 = id_src2_is_rd? id_rd: id_rk;
    assign rf_wdata = wb_res_from_dram? mem_to_rf_data: 
                      (wb_res_from_csr|wb_res_from_tid)? csr_rvalue :
                      wb_res_from_cnt?  wb_res_of_cnt:wb_alu_result;  
    
    wire [4:0]rf_waddr;
    assign rf_waddr = wb_res_is_rj? wb_rj : wb_rd;
    regfile rf(
        .raddr1(rf_raddr1),
        .raddr2(rf_raddr2),
        .rdata1(rf_rdata1),
        .rdata2(rf_rdata2),
        .clk(clk),
        .waddr(rf_waddr),
        .wdata(rf_wdata),
        .we(rf_we)
    );

    assign id_src1=rf_rdata1;
    assign id_src2=rf_rdata2;
    assign debug_wb_pc = wb_pc;
    assign debug_wb_rf_we ={4{rf_we}};
    assign debug_wb_rf_wnum=wb_rd;
    assign debug_wb_rf_wdata=rf_wdata;
    

    //assign if_allow_in = inst_sram_data_ok==1'b0;
    assign exe_ready_go=    (if_pc!=32'h1bfffffc && exe_pc==32'b0) ?                  1'b0:
                            (wb_ex===1'b1)?                                            1'b0:
                            (EXE_ready_go == 1'b1) ?                                  1'b1 :
                            exe_need_data_sram ? (data_sram_addr_ok===1'b1 && data_sram_req) : 1'b1;
    assign mem_ready_go=     (if_pc != 32'h1c000000&& if_pc!= 32'h1c000004 &&if_pc!=32'h1bfffffc && mem_pc==32'b0) ?       1'b0: 
                            (wb_ex===1'b1)?                                                 1'b0:
                            mem_need_data_sram ?  (data_sram_data_ok===1'b1) : 1'b1;
    assign pre_if_ready_go =inst_sram_addr_ok && inst_sram_req;
    //assign if_ready_go =1'b1;
    //assign id_ready_go =1'b1;
    //assign wb_ready_go=1'b1;
    assign if_ready_go = rst? 1'b1:
                         (IF_ready_go == 1'b1) ?     1'b1:
                        (if_pc!=32'h1bfffffc&&inst_sram_data_ok==1'b0)? 1'b0 :
                        (exe_ref_we&&exe_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe_rd))||(id_src2_from_ref&&(rf_raddr2==exe_rd))))? 1'b0 :
                        (mem_ref_we&&mem_rd!=0&&((id_src1_from_ref&&(rf_raddr1==mem_rd))||(id_src2_from_ref&&(rf_raddr2==mem_rd))))?  1'b0:
                        (wb_rf_we&&wb_rd!=0&&((id_src1_from_ref&&(rf_raddr1==wb_rd))||(id_src2_from_ref&&(rf_raddr2==wb_rd))))?  1'b0  : 1'b1;
                        // (exe_csr_we&&(exe_csr_num==14'h4||exe_csr_num==14'd5||exe_csr_num==14'b0)) ?       1'b0:
                        // (mem_csr_we&&(mem_csr_num==14'h4||mem_csr_num==14'd5||mem_csr_num==14'b0)) ?       1'b0:
                        // (wb_csr_we&&(wb_csr_num==14'h4||wb_csr_num==14'd5||wb_csr_num==14'b0)) ?       1'b0:   1'b1;
    assign id_ready_go = rst? 1'b1:
                        (ID_ready_go == 1'b1) ?      1'b1 :
                        (wb_ex===1'b1)? 1'b0:
                        //(wb_is_ertn===1'b1) ? 1'b1:
                        (id_pc==32'b0) ? 1'b0 :
                        (exe_ref_we&&exe_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe_rd))||(id_src2_from_ref&&(rf_raddr2==exe_rd))))? 1'b0 :
                        (mem_ref_we&&mem_rd!=0&&((id_src1_from_ref&&(rf_raddr1==mem_rd))||(id_src2_from_ref&&(rf_raddr2==mem_rd))))?  1'b0:
                        (wb_rf_we&&wb_rd!=0&&((id_src1_from_ref&&(rf_raddr1==wb_rd))||(id_src2_from_ref&&(rf_raddr2==wb_rd))))?  1'b0  : 1'b1;
                        // (exe_csr_we&&(exe_csr_num==14'h4||exe_csr_num==14'd5||exe_csr_num==14'b0)) ?       1'b0:
                        // (mem_csr_we&&(mem_csr_num==14'h4||mem_csr_num==14'd5||mem_csr_num==14'b0)) ?       1'b0:
                        // (wb_csr_we&&(wb_csr_num==14'h4||wb_csr_num==14'd5||wb_csr_num==14'b0)) ?       1'b0:   1'b1;
    assign wb_ready_go =rst? 1'b1:
                        (wb_ex===1'b1)? 1'b0:
                        //(wb_is_ertn===1'b1) ? 1'b1:
                        (inst_sram_data_ok==1'b0)? 1'b0 :
                        (exe_ref_we&&exe_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe_rd))||(id_src2_from_ref&&(rf_raddr2==exe_rd))))? 1'b0 :
                        (mem_ref_we&&mem_rd!=0&&((id_src1_from_ref&&(rf_raddr1==mem_rd))||(id_src2_from_ref&&(rf_raddr2==mem_rd))))?  1'b0:
                        (wb_rf_we&&wb_rd!=0&&((id_src1_from_ref&&(rf_raddr1==wb_rd))||(id_src2_from_ref&&(rf_raddr2==wb_rd))))?  1'b0  : 1'b1;
                        // (exe_csr_we&&(exe_csr_num==14'h4||exe_csr_num==14'd5||exe_csr_num==14'b0)) ?       1'b0:
                        // (mem_csr_we&&(mem_csr_num==14'h4||mem_csr_num==14'd5||mem_csr_num==14'b0)) ?       1'b0:
                        // (wb_csr_we&&(wb_csr_num==14'h4||wb_csr_num==14'd5||wb_csr_num==14'b0)) ?       1'b0:   1'b1;
    assign pipline_is_not_stalled =rst? 1'b1:
                       // (wb_ex===1'b1)? 1'b1:
                        (exe_ref_we&&exe_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe_rd))||(id_src2_from_ref&&(rf_raddr2==exe_rd))))? 1'b0 :
                        (mem_ref_we&&mem_rd!=0&&((id_src1_from_ref&&(rf_raddr1==mem_rd))||(id_src2_from_ref&&(rf_raddr2==mem_rd))))?  1'b0:
                        (wb_rf_we&&wb_rd!=0&&((id_src1_from_ref&&(rf_raddr1==wb_rd))||(id_src2_from_ref&&(rf_raddr2==wb_rd))))?  1'b0  : 1'b1;
                        // (exe_csr_we&&(exe_csr_num==14'h4||exe_csr_num==14'd5||exe_csr_num==14'b0)) ?       1'b0:
                        // (mem_csr_we&&(mem_csr_num==14'h4||mem_csr_num==14'd5||mem_csr_num==14'b0)) ?       1'b0:
                        // (wb_csr_we&&(wb_csr_num==14'h4||wb_csr_num==14'd5||wb_csr_num==14'b0)) ?       1'b0:   1'b1;
    assign wb_allow_in = 1'b1;
    // assign mem_allow_in = wb_allow_in && (~(mem_ready_go===1'b0));
    // assign exe_allow_in = mem_allow_in && (~(exe_ready_go===1'b0));
    // assign id_allow_in = exe_allow_in && (~(id_ready_go===1'b0));
    // assign if_allow_in = id_allow_in && (~(if_ready_go===1'b0));
    if_allow_in_state If_allow_in(
        .clk(clk),
        .rst(rst),
        .pre_if_ready_go(pre_if_ready_go),
        .if_ready_go(if_ready_go),
        .id_allow_in(id_allow_in),
        .if_allow_in(if_allow_in)
    );
    id_allow_in_state Id_allow_in(
        .clk(clk),
        .rst(rst),
        .if_ready_go(if_ready_go),
        .id_ready_go(id_ready_go),
        .exe_allow_in(exe_allow_in),
        .id_allow_in(id_allow_in)
    );
    exe_allow_in_state Exe_allow_in(
        .clk(clk),
        .rst(rst),
        .id_ready_go(id_ready_go),
        .exe_ready_go(exe_ready_go),
        .wb_ex(wb_ex),
        .mem_allow_in(mem_allow_in),
        .exe_allow_in(exe_allow_in)
    );
    mem_allow_in_state Mem_allow_in(
        .clk(clk),
        .rst(rst),
        .exe_ready_go(exe_ready_go),
        .mem_ready_go(mem_ready_go),
        .wb_allow_in(wb_allow_in),
        .mem_allow_in(mem_allow_in)
    );
                        
    wire wb_ex;//是否是异�??
    wire [5:0]wb_ecode;
    wire [7:0]wb_esubcode;//异常类型的编�??
    Wb_stage wb_stage(
        .wb_is_syscall(wb_is_syscall), //  Input，是否是调用异常�??1�??
        .wb_ecode(wb_ecode),          //   Output，异常编码，同下
        .wb_esubcode(wb_esubcode),    //   OutPut,异常编码，按照指令手册表7-7中，8�??
        .wb_ex(wb_ex),                // Output,是否触发异常,1�??
        .wb_is_ertn(wb_is_ertn),       //Input，是否是ertn指令�??1�??
        .wb_ex_adef(wb_ex_adef),       //Input，是否是取指令的地址错误�??1�??
        .wb_ex_ale(wb_ex_ale),         //Input，地�??非对齐错误，1�??
        .wb_ex_brk(wb_ex_brk),         //Input，是否是断点错误�??1�??
        .wb_ex_ine(wb_ex_ine),          //Input，指令不存在错误�??1�??
        .wb_need_cancel(wb_need_cancel),
        .wb_has_int(wb_has_int)          //Input,发生了中�??
    );

    wire [13:0]csr_num;
    wire [7:0]hw_int_in=8'b0;
    wire [31:0] coueid_in=32'b0;
    wire ipi_int_in=1'b0;
    wire [12:0] csr_estat_is;
    wire [12:0] csr_ecfg_lie;
    wire csr_crmd_ie;
    wire [31:0] wb_ex_ale_addr;
    wire csr_ex;
    assign csr_ex = (wb_ex===1'b1) && wb_is_ertn==1'b0 ;
    
    assign wb_ex_ale_addr=wb_data_addr;
    assign csr_num = (wb_ex&&wb_is_ertn==1'b0) ?           14'hc :
                    wb_res_from_tid?   14'h40:  wb_csr_num;  //中断的话，要去读中断程序入口地址，csr_rvalue即为入口地址
    CSR csr(
        .clk(clk),//
        .rst(rst),//
        .csr_num(csr_num),//
        .csr_we(wb_csr_we),//
        .csr_wmask(wb_csr_wmask),//
        .wb_ertn_flush(wb_is_ertn),//
        .wb_ex(csr_ex),//
        .wb_ecode(wb_ecode),//
        .wb_esubcode(wb_esubcode),//
        .hw_int_in(hw_int_in),
        .coreid_in(coreid_in),
        .ipi_int_in(ipi_int_in),
        .csr_rvalue(csr_rvalue),//
        .csr_wvalue(wb_csr_wdata),//
        .wb_pc(wb_pc),//
        .csr_era_pc(csr_era_pc),
        .wb_ex_ale(wb_ex_alw),
        .wb_ex_ale_addr(wb_ex_ale_addr),
        .csr_estat_is(csr_estat_is),
        .csr_ecfg_lie(csr_ecfg_lie),
        .csr_crmd_ie(csr_crmd_ie),
        .csr_timer_64(csr_timer_64),
        .csr_tid_tid(csr_tid_tid)
    );

    Inst_ram_state inst_ram_state(
        .clk(clk),
        .rst(rst),
        .req(inst_sram_req),
        .data_ok(inst_sram_data_ok),
        .addr_ok(inst_sram_addr_ok),
        .inst_req_valid(inst_req_valid)          //output,等于0表示�?1个请求已经发出，不能再发请求
    );

    If_to_id_need_cancel if_to_id_need_cancel(
        .clk(clk),
        .rst(rst),
        .wb_ex(wb_ex),
        .inst_sram_req(inst_sram_req),
        .inst_sram_data_ok(inst_sram_data_ok),
        .inst_sram_addr_ok(inst_sram_addr_ok),
        .if_ready_go(if_ready_go),
        .id_allow_in(id_allow_in),
        .id_br_taken(id_br_taken),
        .id_need_cancel(id_need_cancel)          //output;等于1表示if-id级的指令�?要取�?
    );

    Data_ram_state data_ram_state(
        .clk(clk),
        .rst(rst),
        .req(data_sram_req),
        .data_ok(data_sram_data_ok),
        .addr_ok(data_sram_addr_ok),
        .data_req_valid(data_req_valid)          //表示�?1个请求已经发出，不能再发请求
    );

    id_next_inst_cancel id_next_inst_cancel(
        .clk(clk),
        .rst(rst),
        .id_br_taken(id_br_taken),
        .if_ready_go(if_ready_go),
        .id_allow_in(id_allow_in),
        .pre_if_ready_go(pre_if_ready_go),
        .if_allow_in(if_allow_in),
        .id_next_inst_cancel(id_inst_cancel)
    );

    IF_readygo_state If_readygo_state(
        .rst(rst),
        .clk(clk),
        .id_allow_in(id_allow_in),
        .if_ready_go(if_ready_go),
        .IF_ready_go(IF_ready_go)
    );

    EXE_readygo_state Exe_readygo_state(
        .rst(rst),
        .clk(clk),
        .mem_allow_in(mem_allow_in),
        .exe_ready_go(exe_ready_go),
        .EXE_ready_go(EXE_ready_go)
    );

    ID_readygo_state Id_readygo_state(
        .rst(rst),
        .clk(clk),
        .id_ready_go(id_ready_go),
        .exe_allow_in(exe_allow_in),
        .ID_ready_go(ID_ready_go)
    );

    axi_bridge u_axi_bridge (
    .aclk(aclk),
    .aresetn(aresetn),

    .inst_sram_req(inst_sram_req),
    .inst_sram_wr(inst_sram_wr),
    .inst_sram_size(inst_sram_size),
    .inst_sram_wstrb(inst_sram_wstrb),
    .inst_sram_addr(inst_sram_addr),
    .inst_sram_wdata(inst_sram_wdata),
    .inst_sram_data_ok(inst_sram_data_ok),
    .inst_sram_addr_ok(inst_sram_addr_ok),
    .inst_sram_rdata(inst_sram_rdata),

    .data_sram_req(data_sram_req),
    .data_sram_wr(data_sram_wr),
    .data_sram_size(data_sram_size),
    .data_sram_wstrb(data_sram_wstrb),
    .data_sram_addr(data_sram_addr),
    .data_sram_wdata(data_sram_wdata),
    .data_sram_data_ok(data_sram_data_ok),
    .data_sram_addr_ok(data_sram_addr_ok),
    .data_sram_rdata(data_sram_rdata),

    .arid(arid),
    .araddr(araddr),
    .arlen(arlen),
    .arsize(arsize),
    .arburst(arburst),
    .arlock(arlock),
    .arcache(arcache),
    .arprot(arprot),
    .arvalid(arvalid),
    .arready(arready),

    .rid(rid),
    .rdata(rdata),
    .rvalid(rvalid),
    .rready(rready),

    .awid(awid),
    .awaddr(awaddr),
    .awlen(awlen),
    .awsize(awsize),
    .awburst(awburst),
    .awlock(awlock),
    .awcache(awcache),
    .awprot(awprot),
    .awvalid(awvalid),
    .awready(awready),

    .wid(wid),
    .wdata(wdata),
    .wstrb(wstrb),
    .wlast(wlast),
    .wvalid(wvalid),
    .wready(wready),

    .bvalid(bvalid),
    .bready(bready)
);


endmodule