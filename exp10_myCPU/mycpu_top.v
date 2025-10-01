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

    // in order to handle data maoxian(read after write),add these signals

  
    
    wire rst;
    wire [31:0] pc_br_target;
    wire pc_br_taken;
    wire [31:0]pc_inst_addr;
    wire pc_inst_en;
    wire [31:0] if_pc;
    assign rst = ~resetn;
    wire wb_ready_go;
    wire if_ready_go;
    wire id_ready_go;
    wire exe_ready_go;
    wire mem_ready_go; 
    PC_Reg pc_reg(
        .clk(clk),
        .rst(rst),
        .wb_ready_go(wb_ready_go),
        .if_pc(if_pc),
        .inst_en(pc_inst_en),
        .pc_br_taken(pc_br_taken),
        .pc_br_target(pc_br_target),
        .inst_addr(inst_sram_addr)
    );

    assign inst_sram_en = pc_inst_en;
        
    

    wire [31:0] id_inst;
    wire [31:0] id_pc;
    wire [31:0] if_inst;
    ID_Reg id_reg(
        .clk(clk),
        .rst(rst),
        .if_ready_go(if_ready_go),
        .if_pc(if_pc),
        .if_inst(if_inst),
        .id_inst(id_inst),
        .id_pc(id_pc)
    );
    reg [31:0] inst_sram_rdata_reg;
    assign if_inst = inst_sram_rdata_reg;

    always @(*) begin
         casez (id_br_taken)
                 1'b1: inst_sram_rdata_reg = 32'h02800000;
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
   // wire id_cancel;   //跳转的话，需要置�???1
    wire id_br_taken;
    wire [31:0]id_br_target;
    wire id_src1_from_ref;
    wire id_src2_from_ref;
    wire id_zero_extend; //如果第二个操作数是立即数，而且需要零扩展，是的话为1，否则的话为0
    wire id_rdram_need_zero_extend;
    wire id_rdram_need_signed_extend;
    wire [1:0]id_rdram_num; //如果是ld类指令，ld.w置0，ld.b,ld.bu置1，ld.h,ld.hu置2
    wire [1:0]id_wdram_num; //如果是st类指令，st.w置0，ld.b,ld.bu置1，ld.h,ld.hu置2

    ID_stage id_stage(
        .id_inst(id_inst),    //Input:输入的指令
        .id_pc(id_pc),        //Input:当前指令的pc
        .id_rj(id_rj),        //output：寄存器rj的地址
        .id_rk(id_rk),        //output：rk的地址
        .id_rd(id_rd),        //output：rd的地址，记得指令为bl时将id_rd设置为1(已实现)
        .id_rf_rdata1(rf_rdata1),     //Input：从寄存器读到的源操作数1，
        .id_rf_rdata2(rf_rdata2),     //Input:从寄存器读到的源操作数2,
        .id_ref_we(id_ref_we),        //Output:是否需要写寄存器
        .id_alu_op(id_alu_op),        //Output:alu的op信号，对照表在word里
        .id_dram_we(id_dram_we),      //Output(下边的都是output):是否需要写dram
        .id_dram_re(id_dram_re),      //是否需要读dram
        .id_src1(id_src1),              //可以先不管
        .id_src2(id_src2),          //可以先不管
        .id_src2_is_imm12(id_src2_is_imm12),         //以下为立即数的控制信号
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
        .id_br_taken(id_br_taken),                //是否需要跳转
        .id_br_target(id_br_target),              //跳转的地址，（由于流水线要处理冒险，故我把跳转模块从exe_stage挪到了id_stage中)
        .id_src1_from_ref(id_src1_from_ref),      //第1个源操作数是否来自寄存器堆，
        .id_src2_from_ref(id_src2_from_ref),      //第2个源操作数是否来自寄存器堆，这个和id_src1_from_ref的生成方法要看下"exp8-9"word,
        .id_zero_extend(id_zero_extend),          //src2是立即数的话，是需要符号扩展还是零扩展，零扩展的话置1
        .id_rdram_need_zero_extend(id_rdram_need_zero_extend),
        .id_rdram_need_signed_extend(id_rdram_need_signed_extend),  //这3个信号是ld类指令，需要将dada_ram数据写入寄存器堆时，对data_ram中读到的数据的处理信号
        .id_rdram_num(id_rdram_num),             //如果是ld类指令，ld.w置0，ld.b,ld.bu置1，ld.h,ld.hu置2
        .id_wdram_num(id_wdram_num)              //如果是st类指令，st.w置0，ld.b,ld.bu置1，ld.h,ld.hu置2
    );
    assign id_dram_wdata=id_src2;
    assign pc_br_taken=id_br_taken;
    assign pc_br_target=id_br_target;
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
    ExE_reg exe_reg(
        .clk(clk),
        .rst(rst),
        .id_ready_go(id_ready_go),
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
        .exe_wdram_num(exe_wdram_num) 
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
        .alu_rf_src2(exe_rf_src2)
    );
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
    Mem_reg mem_reg(
        .clk(clk),
        .rst(rst),
        .exe_ready_go(exe_ready_go),
        .exe_alu_result(exe_alu_result),
        .exe_ref_we(exe_ref_we),
        .exe_dram_re(exe_dram_re),
        .exe_dram_we(exe_dram_we),
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
        .mem_wdram_num(mem_wdram_num)
    );
    wire [31:0] mem_dram_rdata;
    //assign data_sram_addr=mem_alu_result;

    assign mem_dram_rdata=data_sram_rdata;
    assign data_sram_we=(mem_dram_we&&mem_wdram_num==0)? 4'b1111:
                        (mem_dram_we&&mem_wdram_num==1&&data_sram_addr[1:0]==00)?  4'b0001:
                        (mem_dram_we&&mem_wdram_num==1&&data_sram_addr[1:0]==01)?4'b0010:
                        (mem_dram_we&&mem_wdram_num==1&&data_sram_addr[1:0]==10)? 4'b0100:
                        (mem_dram_we&&mem_wdram_num==1&&data_sram_addr[1:0]==11)? 4'b1000:
                        (mem_dram_we&&mem_wdram_num==2&&data_sram_addr[1:0]==00)?4'b0011:
                        (mem_dram_we&&mem_wdram_num==2&&data_sram_addr[1:0]==01)?4'b0110:
                        (mem_dram_we&&mem_wdram_num==2&&data_sram_addr[1:0]==10)?4'b1100:   4'b0000;
    assign data_sram_en=1'b1;
    //assign data_sram_wdata=mem_dram_wdata;
    assign data_sram_wdata =  mem_wdram_num==0?  mem_dram_wdata:
                             mem_wdram_num==1?   {2{mem_dram_wdata[15:0]}} :{4{mem_dram_wdata[7:0]}} ;
    assign data_sram_addr=mem_dram_we? mem_dram_waddr: mem_alu_result;

    wire  wb_rf_we;
    wire [31:0] wb_alu_result;
    wire [4:0] wb_rd;
    //wire [31:0] wb_br_target;
    //wire wb_br_taken;
   // wire [31:0]wb_dram_rdata;
    wire wb_res_from_dram;
    wire [31:0] wb_dram_wdata;
    wire [31:0] wb_dram_waddr;
    wire wb_dram_we;
    wire [31:0] wb_pc;
    wire [1:0]wb_rdram_num;
    wire wb_rdram_need_zero_extend;
    wire wb_rdram_need_signed_extend;
    Wb_reg wb_reg(
        .clk(clk),
        .rst(rst),
        .mem_ready_go(mem_ready_go),
        .mem_alu_result(mem_alu_result),
        .mem_ref_we(mem_ref_we),
        .mem_rd(mem_rd),
       // .mem_br_taken(mem_br_taken),
        //.mem_br_target(mem_br_target),
       // .mem_dram_rdata(mem_dram_rdata),
        .mem_res_from_dram(mem_res_from_dram),
        .mem_dram_wdata(mem_dram_wdata),
        .mem_dram_waddr(mem_dram_waddr),
        .mem_dram_we(mem_dram_we),
        .mem_pc(mem_pc),
        .mem_rdram_num(mem_rdram_num),
        .mem_rdram_need_zero_extend(mem_rdram_need_zero_extend),
        .mem_rdram_need_signed_extend(mem_rdram_need_signed_extend),
        .wb_rf_we(wb_rf_we),
        .wb_alu_result(wb_alu_result),
        .wb_rd(wb_rd),
        //.wb_br_taken(wb_br_taken),
        //.wb_br_target(wb_br_target),
       // .wb_dram_rdata(wb_dram_rdata),
        .wb_res_from_dram(wb_res_from_dram),
        .wb_dram_waddr(wb_dram_waddr),
        .wb_dram_wdata(wb_dram_wdata),
        .wb_dram_we(wb_dram_we),
        .wb_pc(wb_pc),
        .wb_rdram_num(wb_rdram_num),
        .wb_rdram_need_signed_extend(wb_rdram_need_signed_extend),
        .wb_rdram_need_zero_extend(wb_rdram_need_zero_extend)
    );
    
    assign pc_br_taken=id_br_taken;
    assign pc_br_target=id_br_target;

    wire [4:0] rf_raddr1;
    wire [4:0] rf_raddr2;
    wire [31:0] rf_wdata;
    wire [31:0] rf_rdata1;
    wire [31:0] rf_rdata2;
    wire [31:0] mem_to_rf_data;
    assign mem_to_rf_data = wb_rdram_num==0 ?   mem_dram_rdata :
                            (wb_rdram_num==1&&wb_rdram_need_signed_extend) ?  {{16{mem_dram_rdata[15]}},mem_dram_rdata[15:0]}   :
                            (wb_rdram_num==1&&wb_rdram_need_zero_extend) ?  {{16{1'b0}},mem_dram_rdata[15:0]}   :
                            (wb_rdram_num==2&&wb_rdram_need_signed_extend) ?  {{24{mem_dram_rdata[7]}},mem_dram_rdata[7:0]}   :
                            (wb_rdram_num==2&&wb_rdram_need_zero_extend) ?  {{24{1'b0}},mem_dram_rdata[7:0]}   :32'b0;
    assign rf_raddr1 = id_rj;
    assign rf_raddr2 = id_src2_is_rd? id_rd: id_rk;
    assign rf_wdata = wb_res_from_dram? mem_to_rf_data: wb_alu_result;  
    
    
    
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
    


    assign exe_ready_go=1'b1;
    assign mem_ready_go=1'b1;
    //assign if_ready_go =1'b1;
    //assign id_ready_go =1'b1;
    //assign wb_ready_go=1'b1;
    assign if_ready_go = rst? 1'b1:(exe_ref_we&&exe_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe_rd))||(id_src2_from_ref&&(rf_raddr2==exe_rd))))? 1'b0 :
                        (mem_ref_we&&mem_rd!=0&&((id_src1_from_ref&&(rf_raddr1==mem_rd))||(id_src2_from_ref&&(rf_raddr2==mem_rd))))?  1'b0:
                        (wb_rf_we&&wb_rd!=0&&((id_src1_from_ref&&(rf_raddr1==wb_rd))||(id_src2_from_ref&&(rf_raddr2==wb_rd))))?  1'b0  :1'b1;
    assign id_ready_go = rst? 1'b1:(exe_ref_we&&exe_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe_rd))||(id_src2_from_ref&&(rf_raddr2==exe_rd))))? 1'b0 :
                        (mem_ref_we&&mem_rd!=0&&((id_src1_from_ref&&(rf_raddr1==mem_rd))||(id_src2_from_ref&&(rf_raddr2==mem_rd))))?  1'b0:
                        (wb_rf_we&&wb_rd!=0&&((id_src1_from_ref&&(rf_raddr1==wb_rd))||(id_src2_from_ref&&(rf_raddr2==wb_rd))))?  1'b0  :1'b1;
    assign wb_ready_go =rst? 1'b1:(exe_ref_we&&exe_rd!=0&&((id_src1_from_ref&&(rf_raddr1==exe_rd))||(id_src2_from_ref&&(rf_raddr2==exe_rd))))? 1'b0 :
                        (mem_ref_we&&mem_rd!=0&&((id_src1_from_ref&&(rf_raddr1==mem_rd))||(id_src2_from_ref&&(rf_raddr2==mem_rd))))?  1'b0:
                        (wb_rf_we&&wb_rd!=0&&((id_src1_from_ref&&(rf_raddr1==wb_rd))||(id_src2_from_ref&&(rf_raddr2==wb_rd))))?  1'b0  :1'b1;               
    
endmodule