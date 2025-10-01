`define  CSR_CRMD  14'h0
`define  CSR_PRMD  14'd1
`define CSR_CRMD_PLV 1:0
`define CSR_CRMD_PIE 2
`define CSR_PRMD_PPLV 1:0
`define CSR_PRMD_PIE 2
`define CSR_ESTAT 14'd5
`define CSR_ESTAT_IS10 1:0
`define CSR_TICLR 14'h44
`define CSR_TICLR_CLR 0
`define CSR_ERA_PC 31:0
`define CSR_ERA 14'd6
`define CSR_EENTRY_VA 31:6
`define CSR_EENTRY 14'hc
`define CSR_SAVE0 14'h30
`define CSR_SAVE1 14'h31
`define CSR_SAVE2 14'h32
`define CSR_SAVE3 14'h33
`define CSR_SAVE_DATA 31:0
`define CSR_ECFG 14'h4
`define CSR_ECFG_LIE 12:0
`define CSR_BADV 14'h7
`define CSR_BADV_VADDR 31:0
`define ECODE_ADE 6'h8
`define ESUBCODE_ADEF 1'b0
`define CSR_TID 14'h40
`define CSR_TID_TID 31:0
`define CSR_TCFG_EN 0
`define CSR_TCFG_PERIOD 1
`define CSR_TCFG_INITV 30:2
`define CSR_TCFG 14'h41
`define ECODE_ALE 6'h9

//below are the csr related to tlb
`define CSR_TLBIDX 14'h10
`define CSR_TLBEHI 14'h11
`define CSR_TLBELO0 14'h12
`define CSR_TLBELO1 14'h13
`define CSR_ASID 14'h18
`define CSR_TLBRENTRY 14'h88
`define CSR_TLBIDX_INDEX 3:0
`define CSR_TLBIDX_PS 29:24
`define CSR_TLBIDX_NE 31
`define CSR_TLBEHI_VPPN 31:13
`define CSR_TLBELO0_V 0
`define CSR_TLBELO0_D 1
`define CSR_TLBELO0_PLV 3:2
`define CSR_TLBELO0_MAT 5:4
`define CSR_TLBELO0_G 6
`define CSR_TLBELO0_PPN 27:8
`define CSR_TLBELO1_V 0
`define CSR_TLBELO1_D 1
`define CSR_TLBELO1_PLV 3:2
`define CSR_TLBELO1_MAT 5:4
`define CSR_TLBELO1_G 6
`define CSR_TLBELO1_PPN 27:8
`define CSR_ASID_ASID 9:0
`define CSR_TLBRENTRY_PA 31:6



module CSR (
    input wire clk,
    input wire rst,
    input wire [13:0]csr_num,      //寄存器编�??,相当于地�??，手�??7.1节有规定
    input wire csr_we,             //写使�??
    input wire [31:0] csr_wmask,    //掩码，用于写操作
    input wire [31:0] csr_wvalue,  //写数�??

    output wire [31:0] csr_rvalue, //读数�??
    
    input wire wb_ex_ale,             //地址放存错误
    input wire [31:0] wb_ex_ale_addr,    //出错的访存地�??
    input wire [31:0] wb_pc,
    input wire [31:0] coreid_in,      //进入�??31位的计时器编�??

    input wire wb_ertn_flush,      //  来自写回级ertn指令有效,与写操作相关
    input wire wb_ex,              //  来自写回级的异常触发信号，与写操作相�??
    input wire [5:0]wb_ecode,      //�??7-7中异常的编码，与写操作相�??
    input wire [7:0]wb_esubcode,   //�??7-7中异常的编码，与写操作相�??
    input wire [7:0]hw_int_in,     //硬件输入，先不管
    input wire ipi_int_in,          //先不�??
    
    output reg[31:0] csr_era_pc,
    output reg[12:0] csr_ecfg_lie,
    output reg[12:0] csr_estat_is,
    output reg csr_crmd_ie,
    output reg [63:0]csr_timer_64,
    output reg [31:0]csr_tid_tid,
    output reg [5:0]csr_estat_ecode,
    output reg csr_tlbidx_ne,
    output reg [5:0]csr_tlbidx_ps,
    output reg csr_tlbelo0_d,
    output reg csr_tlbelo0_g,
    output reg csr_tlbelo0_v,
    output reg [1:0]csr_tlbelo0_mat,
    output reg [19:0] csr_tlbelo0_ppn,
    output reg [1:0] csr_tlbelo0_plv,
    output reg csr_tlbelo1_d,
    output reg csr_tlbelo1_g,
    output reg csr_tlbelo1_v,
    output reg [1:0] csr_tlbelo1_mat,
    output reg [19:0] csr_tlbelo1_ppn,
    output reg [1:0] csr_tlbelo1_plv,


    input wire [3:0]csr_tlbidx_index_wvalue,
    input wire csr_tlbidx_index_we,
    output reg [3:0] csr_tlbidx_index,
    input wire csr_tlbidx_ne_we,
    input wire csr_tlbidx_ne_wvalue,
    input wire csr_tlbidx_ps_we,
    input wire [5:0] csr_tlbidx_ps_wvalue,

    input wire csr_tlbehi_we,
    input wire [18:0] csr_tlbehi_wvalue,

    input wire csr_tlbelo0_v_we,
    input wire csr_tlbelo0_v_wvalue,
    input wire csr_tlbelo0_d_we,
    input wire csr_tlbelo0_d_wvalue,
    input wire csr_tlbelo0_plv_we,
    input wire [1:0]csr_tlbelo0_plv_wvalue,
    input wire csr_tlbelo0_mat_we,
    input wire [1:0]csr_tlbelo0_mat_wvalue,
    input wire csr_tlbelo0_g_we,
    input wire csr_tlbelo0_g_wvalue,
    input wire csr_tlbelo0_ppn_we,
    input wire [19:0]csr_tlbelo0_ppn_wvalue,
    input wire csr_tlbelo1_v_we,
    input wire csr_tlbelo1_v_wvalue,
    input wire csr_tlbelo1_d_we,
    input wire csr_tlbelo1_d_wvalue,
    input wire csr_tlbelo1_plv_we,
    input wire [1:0]csr_tlbelo1_plv_wvalue,
    input wire csr_tlbelo1_mat_we,
    input wire [1:0]csr_tlbelo1_mat_wvalue,
    input wire csr_tlbelo1_g_we,
    input wire csr_tlbelo1_g_wvalue,
    input wire csr_tlbelo1_ppn_we,
    input wire [19:0]csr_tlbelo1_ppn_wvalue,
    input wire csr_asid_asid_we,
    input wire [9:0] csr_asid_asid_wvalue,
    input wire csr_tlbrentry_we,
    input wire [25:0] csr_tlbrentry_wvalue,


    output reg [9:0]csr_asid_asid,
    output reg [18:0] csr_tlbehi
    
);
    
    reg [1:0]csr_crmd_plv;
    reg [1:0]csr_prmd_pplv;
   
    reg csr_prmd_pie;
    wire csr_crmd_da;
    wire csr_crmd_pg;
    wire [1:0]csr_crmd_datf;
    wire [1:0]csr_crmd_datm;
   
    
    reg [8:0]csr_estat_esubcode;
    reg [25:0]csr_eentry_va;
    reg [31:0]csr_save0_data;
    reg [31:0]csr_save1_data;
    reg [31:0]csr_save2_data;
    reg [31:0]csr_save3_data;
    
    reg [31:0]timer_cnt;
    reg csr_tcfg_en;
    reg csr_tcfg_periodic;
    reg [28:0]csr_tcfg_initval;
    wire [31:0]tcfg_next_value;
    wire [31:0]csr_tval;
    reg [31:0] csr_badv_vaddr;

    reg [25:0] csr_tlbrentry;

    
    


    assign csr_crmd_da=1'b1;
    assign csr_crmd_pg=1'b0;
    assign csr_crmd_datf=2'b00;
    assign csr_crmd_datm=2'b00;

    always @(posedge clk)
    begin
        if(rst)
        begin
            csr_crmd_plv<=2'b0;
        end
        else if(wb_ex)
        begin
            csr_crmd_plv<=2'b0;
        end
        else if(wb_ertn_flush)
        begin
            csr_crmd_plv<=csr_prmd_pplv;
        end
        else if(csr_we && csr_num == `CSR_CRMD)
        begin
            csr_crmd_plv<= csr_wmask[`CSR_CRMD_PLV] &csr_wvalue[`CSR_CRMD_PLV] | ~csr_wmask[`CSR_CRMD_PLV] &csr_crmd_plv;
        end
    end


    always @(posedge clk)
    begin
        if(rst)
        begin
            csr_crmd_ie<=1'b0;
        end
        else if(wb_ex)
        begin
            csr_crmd_ie<=1'b0;
        end
        else if(wb_ertn_flush)
        begin
            csr_crmd_ie<=csr_prmd_pie;
        end
        else if(csr_we && csr_num==`CSR_CRMD)
        begin
            csr_crmd_ie<=csr_wmask[`CSR_CRMD_PIE]&csr_wvalue[`CSR_CRMD_PIE] | ~csr_wmask[`CSR_CRMD_PIE]&csr_crmd_ie;
        end
    end

    always @(posedge clk)
    begin
        if(wb_ex)
        begin
            csr_prmd_pplv<=csr_crmd_plv;
            csr_prmd_pie<=csr_crmd_ie;
        end
        else if(csr_we && csr_num==`CSR_PRMD)
        begin
            csr_prmd_pplv <= csr_wmask[`CSR_PRMD_PPLV]&csr_wvalue[`CSR_PRMD_PPLV] | ~csr_wmask[`CSR_PRMD_PPLV]&csr_prmd_pplv;
            csr_prmd_pie  <= csr_wmask[`CSR_PRMD_PIE]&csr_wvalue[`CSR_PRMD_PIE]  | ~csr_wvalue[`CSR_PRMD_PIE]&csr_prmd_pie;
        end
    end

    always @(posedge clk)
    begin
        if(rst)
        begin
            csr_estat_is[1:0] <=2'b0;
        end
        else if(csr_we && csr_num==`CSR_ESTAT)
        csr_estat_is[1:0]<=csr_wmask[`CSR_ESTAT_IS10]&csr_wvalue[`CSR_ESTAT_IS10] | ~csr_wmask[`CSR_ESTAT_IS10]&csr_estat_is[1:0];

        csr_estat_is[10]<=1'b0;
        csr_estat_is[9:2]<=hw_int_in[7:0];

        if(timer_cnt[31:0]==32'b0)
        begin
            csr_estat_is[11]<=1'b1;
        end
        else if(csr_we && csr_num==`CSR_TICLR && csr_wmask[`CSR_TICLR_CLR] && csr_wvalue[`CSR_TICLR_CLR])
        begin
            csr_estat_is[11] <=1'b0;
        end

        csr_estat_is[12]<=ipi_int_in;
    end


    always @(posedge clk)
    begin
        if(wb_ex)
        begin
        csr_estat_ecode<=wb_ecode;
        csr_estat_esubcode<=wb_esubcode;
        end
    end



    always @(posedge clk)
    begin
        if(wb_ex)
        begin
            csr_era_pc<=wb_pc;
        end
        else if(csr_we &&csr_num==`CSR_ERA)
        begin
            csr_era_pc<=csr_wmask[`CSR_ERA_PC]&csr_wvalue[`CSR_ERA_PC] | ~csr_wmask[`CSR_ERA_PC]&csr_era_pc;
        end
    end


    always @(posedge clk)
    begin
        if(csr_we &&csr_num==`CSR_EENTRY)
        csr_eentry_va <= csr_wmask[`CSR_EENTRY_VA]&csr_wvalue[`CSR_EENTRY_VA] | ~csr_wmask[`CSR_EENTRY_VA]&csr_eentry_va;
    end

    always @(posedge clk)
    begin
        if(csr_we &&csr_num==`CSR_SAVE0)
        csr_save0_data<=csr_wmask[`CSR_SAVE_DATA]&csr_wvalue[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA]&csr_save0_data;
        if(csr_we &&csr_num==`CSR_SAVE1)
        csr_save1_data<=csr_wmask[`CSR_SAVE_DATA]&csr_wvalue[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA]&csr_save1_data;
        if(csr_we &&csr_num==`CSR_SAVE0)
        csr_save2_data<=csr_wmask[`CSR_SAVE_DATA]&csr_wvalue[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA]&csr_save2_data;
        if(csr_we &&csr_num==`CSR_SAVE0)
        csr_save3_data<=csr_wmask[`CSR_SAVE_DATA]&csr_wvalue[`CSR_SAVE_DATA] | ~csr_wmask[`CSR_SAVE_DATA]&csr_save3_data;
    end



    always @(posedge clk)
    begin
        if(rst)
        csr_ecfg_lie<=13'b0;
        else if(csr_we &&csr_num==`CSR_ECFG)
        begin
            csr_ecfg_lie<=csr_wmask[`CSR_ECFG_LIE] &13'h1bff &csr_wvalue[`CSR_ECFG_LIE] |~csr_wmask[`CSR_ECFG_LIE] & 13'h1bff &csr_ecfg_lie;
        end
    end

    wire wb_ex_addr_err;
    assign wb_ex_addr_err =  wb_ecode==`ECODE_ADE  ||  wb_ecode==`ECODE_ALE;
    always @(posedge clk)
    begin
        if(wb_ex && wb_ex_addr_err)
        csr_badv_vaddr <= (wb_ecode==`ECODE_ADE && wb_esubcode ==`ESUBCODE_ADEF) ? wb_pc : wb_ex_ale_addr; 
    end

    always @(posedge clk)
    begin
        if(rst)
        csr_tid_tid <=coreid_in;
        else if(csr_we &&csr_num==`CSR_TID)
        csr_tid_tid <=csr_wmask[`CSR_TID_TID] & csr_wvalue[`CSR_TID_TID] |~csr_wmask[`CSR_TID_TID] &csr_tid_tid;
    end

    always @(posedge clk)
    begin
        if(rst)
        csr_tcfg_en<=1'b0;
        else if(csr_we &&csr_num==`CSR_TCFG)
        csr_tcfg_en <=csr_wmask[`CSR_TCFG_EN] & csr_wvalue[`CSR_TCFG_EN] | ~csr_wmask[`CSR_TCFG_EN] &csr_tcfg_en;

        if(csr_we &&csr_num==`CSR_TCFG)
        begin
            csr_tcfg_periodic <=csr_wmask[`CSR_TCFG_PERIOD] & csr_wvalue[`CSR_TCFG_PERIOD] | ~csr_wmask[`CSR_TCFG_PERIOD] &csr_tcfg_periodic;
            csr_tcfg_initval <=csr_wmask[`CSR_TCFG_INITV] & csr_wvalue[`CSR_TCFG_INITV] | ~csr_wmask[`CSR_TCFG_INITV] &csr_tcfg_initval;
        end
    end
 

    assign tcfg_next_value =csr_wmask[31:0]&csr_wvalue[31:0] |~csr_wmask[31:0]&{csr_tcfg_initval,csr_tcfg_periodic,csr_tcfg_en};

    always @(posedge clk)
    begin
        if(rst)
        timer_cnt<=32'hffffffff;
        else if(csr_we &&csr_num==`CSR_TCFG &&tcfg_next_value[`CSR_TCFG_EN])
        timer_cnt<={tcfg_next_value[`CSR_TCFG_INITV],2'b00};
        else if(csr_tcfg_en && csr_tcfg_periodic!=32'hffffffff)
        begin
            if(timer_cnt[31:0]==32'b0 &&csr_tcfg_periodic)
            timer_cnt<={csr_tcfg_initval,2'b0};
            else 
            timer_cnt<=timer_cnt-1'b1;
        end
    end

   
// waiting for revise
    always @(posedge clk)
    begin
        if(rst)
        begin
            csr_tlbidx_ne <= 1'b0;
        end
        else if(csr_we && csr_num == `CSR_TLBIDX)
        begin
            csr_tlbidx_ne <=csr_wmask[`CSR_TLBIDX_NE] & csr_wvalue[`CSR_TLBIDX_NE] | ~csr_wmask[`CSR_TLBIDX_NE] &csr_tlbidx_ne;
        end
        else if(csr_tlbidx_ne_we)
        begin
            csr_tlbidx_ne <= csr_tlbidx_ne_wvalue;
        end
    end

      always @(posedge clk) 
    begin
        if (rst) 
        begin
            csr_tlbidx_index <= 4'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBIDX)
        begin
            csr_tlbidx_index <=csr_wmask[`CSR_TLBIDX_INDEX] & csr_wvalue[`CSR_TLBIDX_INDEX] | ~csr_wmask[`CSR_TLBIDX_INDEX] &csr_tlbidx_index;
        end
        else if (csr_tlbidx_index_we) 
        begin
                csr_tlbidx_index <= csr_tlbidx_index_wvalue; 
        end        
    end


    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbidx_ps <= 6'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBIDX)
        begin
            csr_tlbidx_ps <=csr_wmask[`CSR_TLBIDX_PS] & csr_wvalue[`CSR_TLBIDX_PS] | ~csr_wmask[`CSR_TLBIDX_PS] &csr_tlbidx_ps;
        end
        else if (csr_tlbidx_ps_we) 
        begin
                csr_tlbidx_ps <= csr_tlbidx_ps_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbehi <= 19'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBEHI)
        begin
            csr_tlbehi <=csr_wmask[`CSR_TLBEHI_VPPN] & csr_wvalue[`CSR_TLBEHI_VPPN] | ~csr_wmask[`CSR_TLBEHI_VPPN] &csr_tlbehi;
        end
        else if (csr_tlbehi_we) 
        begin
            csr_tlbehi <= csr_tlbehi_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbelo0_v <= 1'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBELO0)
        begin
            csr_tlbelo0_v <=csr_wmask[`CSR_TLBELO0_V] & csr_wvalue[`CSR_TLBELO0_V] | ~csr_wmask[`CSR_TLBELO0_V] &csr_tlbelo0_v;
        end
        else if (csr_tlbelo0_v_we) 
        begin
                csr_tlbelo0_v <= csr_tlbelo0_v_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbelo0_d <= 1'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBELO0)
        begin
            csr_tlbelo0_d <=csr_wmask[`CSR_TLBELO0_D] & csr_wvalue[`CSR_TLBELO0_D] | ~csr_wmask[`CSR_TLBELO0_D] &csr_tlbelo0_d;
        end
        else if (csr_tlbelo0_d_we) 
        begin
                csr_tlbelo0_d <= csr_tlbelo0_d_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbelo0_plv <= 2'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBELO0)
        begin
            csr_tlbelo0_plv <=csr_wmask[`CSR_TLBELO0_PLV] & csr_wvalue[`CSR_TLBELO0_PLV] | ~csr_wmask[`CSR_TLBELO0_PLV] &csr_tlbelo0_plv;
        end
        else if (csr_tlbelo0_plv_we) 
        begin
                csr_tlbelo0_plv <= csr_tlbelo0_plv_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbelo0_mat <= 2'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBELO0)
        begin
            csr_tlbelo0_mat <=csr_wmask[`CSR_TLBELO0_MAT] & csr_wvalue[`CSR_TLBELO0_MAT] | ~csr_wmask[`CSR_TLBELO0_MAT] &csr_tlbelo0_mat;
        end
        else if (csr_tlbelo0_mat_we) 
        begin
                csr_tlbelo0_mat <= csr_tlbelo0_mat_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbelo0_g <= 1'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBELO0)
        begin
            csr_tlbelo0_g <=csr_wmask[`CSR_TLBELO0_G] & csr_wvalue[`CSR_TLBELO0_G] | ~csr_wmask[`CSR_TLBELO0_G] &csr_tlbelo0_g;
        end
        else if (csr_tlbelo0_g_we) 
        begin
                csr_tlbelo0_g <= csr_tlbelo0_g_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbelo0_ppn <= 20'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBELO0)
        begin
            csr_tlbelo0_ppn <=csr_wmask[`CSR_TLBELO0_PPN] & csr_wvalue[`CSR_TLBELO0_PPN] | ~csr_wmask[`CSR_TLBELO0_PPN] &csr_tlbelo0_ppn;
        end
        else if (csr_tlbelo0_ppn_we) 
        begin
                csr_tlbelo0_ppn <= csr_tlbelo0_ppn_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbelo1_v <= 1'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBELO1)
        begin
            csr_tlbelo1_v <=csr_wmask[`CSR_TLBELO1_V] & csr_wvalue[`CSR_TLBELO1_V] | ~csr_wmask[`CSR_TLBELO1_V] &csr_tlbelo1_v;
        end
        else if (csr_tlbelo1_v_we) 
        begin
                csr_tlbelo1_v <= csr_tlbelo1_v_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbelo1_d <= 1'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBELO1)
        begin
            csr_tlbelo1_d <=csr_wmask[`CSR_TLBELO1_D] & csr_wvalue[`CSR_TLBELO1_D] | ~csr_wmask[`CSR_TLBELO1_D] &csr_tlbelo1_d;
        end
        else if (csr_tlbelo1_d_we) 
        begin
                csr_tlbelo1_d <= csr_tlbelo1_d_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbelo1_plv <= 2'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBELO1)
        begin
            csr_tlbelo1_plv <=csr_wmask[`CSR_TLBELO1_PLV] & csr_wvalue[`CSR_TLBELO1_PLV] | ~csr_wmask[`CSR_TLBELO1_PLV] &csr_tlbelo1_plv;
        end
        else if (csr_tlbelo1_plv_we) 
        begin
                csr_tlbelo1_plv <= csr_tlbelo1_plv_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbelo1_mat <= 2'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBELO1)
        begin
            csr_tlbelo1_mat <=csr_wmask[`CSR_TLBELO1_MAT] & csr_wvalue[`CSR_TLBELO1_MAT] | ~csr_wmask[`CSR_TLBELO1_MAT] &csr_tlbelo1_mat;
        end
        else if (csr_tlbelo1_mat_we) 
        begin
                csr_tlbelo1_mat <= csr_tlbelo1_mat_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbelo1_g <= 1'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBELO1)
        begin
            csr_tlbelo1_g <=csr_wmask[`CSR_TLBELO1_G] & csr_wvalue[`CSR_TLBELO1_G] | ~csr_wmask[`CSR_TLBELO1_G] &csr_tlbelo1_g;
        end
        else if (csr_tlbelo1_g_we) 
        begin
                csr_tlbelo1_g <= csr_tlbelo1_g_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbelo1_ppn <= 20'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBELO1)
        begin
            csr_tlbelo1_ppn <=csr_wmask[`CSR_TLBELO1_PPN] & csr_wvalue[`CSR_TLBELO1_PPN] | ~csr_wmask[`CSR_TLBELO1_PPN] &csr_tlbelo1_ppn;
        end
        else if (csr_tlbelo1_ppn_we) 
        begin
                csr_tlbelo1_ppn <= csr_tlbelo1_ppn_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_asid_asid <= 10'b0;
        end 
        else if(csr_we && csr_num == `CSR_ASID)
        begin
            csr_asid_asid <=csr_wmask[`CSR_ASID_ASID] & csr_wvalue[`CSR_ASID_ASID] | ~csr_wmask[`CSR_ASID_ASID] &csr_asid_asid;
        end
        else if (csr_asid_asid_we) 
        begin
                csr_asid_asid <= csr_asid_asid_wvalue; 
        end        
    end

    always @(posedge clk)
    begin
        if (rst) 
        begin
            csr_tlbrentry <= 26'b0;
        end 
        else if(csr_we && csr_num == `CSR_TLBRENTRY)
        begin
            csr_tlbrentry <=csr_wmask[`CSR_TLBRENTRY_PA] & csr_wvalue[`CSR_TLBRENTRY_PA] | ~csr_wmask[`CSR_TLBRENTRY_PA] &csr_tlbrentry;
        end
        else if (csr_tlbrentry_we) 
        begin
                csr_tlbrentry <= csr_tlbrentry_wvalue; 
        end        
    end

// waiting for revise





    always @(posedge clk) begin
    if (rst)
        csr_timer_64 <= 64'd0;
    else
        csr_timer_64 <= csr_timer_64 + 64'd1;
    end

    
    assign csr_tval=timer_cnt-1'b1;
    assign csr_ticlr_clr =1'b0;



    wire [31:0] csr_crmd_rvalue ={23'b0,csr_crmd_datm,csr_crmd_datf,csr_crmd_pg,csr_crmd_da,csr_crmd_ie,csr_crmd_plv};
    wire [31:0] csr_prmd_rvalue ={29'b0,csr_prmd_pie,csr_prmd_pplv};
    wire [31:0] csr_estat_rvalue={1'b0,csr_estat_esubcode,csr_estat_ecode,3'b0,csr_estat_is};
    wire [31:0] csr_era_rvalue=csr_era_pc;
    wire [31:0] csr_eentry_rvalue={csr_eentry_va,6'b0};
    wire [31:0] csr_save0_rvalue=csr_save0_data;
    wire [31:0] csr_save1_rvalue=csr_save1_data;
    wire [31:0] csr_save2_rvalue=csr_save2_data;
    wire [31:0] csr_save3_rvalue=csr_save3_data;
    wire [31:0] csr_ecfg_rvalue ={19'b0,csr_ecfg_lie};
    wire [31:0] csr_badv_rvalue ={csr_badv_vaddr};
    wire [31:0] csr_tid_rvalue =csr_tid_tid;
    wire [31:0] csr_tcfg_rvalue ={1'b0,csr_tcfg_initval,csr_tcfg_periodic,csr_tcfg_en};
    wire [31:0] csr_asid_rvalue ={8'b0,8'b1010,6'b0,csr_asid_asid};
    wire [31:0] csr_tlbidx_rvalue ={csr_tlbidx_ne,1'b0,csr_tlbidx_ps,8'b0,12'b0,csr_tlbidx_index};
    wire [31:0] csr_tlbehi_rvalue ={csr_tlbehi,13'b0};
    wire [31:0] csr_tlbelo0_rvalue ={4'b0,csr_tlbelo0_ppn,1'b0,csr_tlbelo0_g,csr_tlbelo0_mat,csr_tlbelo0_plv,csr_tlbelo0_d,csr_tlbelo0_v};
    wire [31:0] csr_tlbelo1_rvalue ={4'b0,csr_tlbelo1_ppn,1'b0,csr_tlbelo1_g,csr_tlbelo1_mat,csr_tlbelo1_plv,csr_tlbelo1_d,csr_tlbelo1_v};
    wire [31:0] csr_tlbrentry_rvalue ={csr_tlbrentry,6'b0};

    assign csr_rvalue={32{csr_num==`CSR_CRMD}}  &  csr_crmd_rvalue
                    | {32{csr_num==`CSR_PRMD}}  &  csr_prmd_rvalue
                    | {32{csr_num==`CSR_ESTAT}} &  csr_estat_rvalue
                    | {32{csr_num==`CSR_ERA}}   &  csr_era_rvalue
                    | {32{csr_num==`CSR_EENTRY}}&  csr_eentry_rvalue
                    | {32{csr_num==`CSR_SAVE0}} &  csr_save0_rvalue
                    | {32{csr_num==`CSR_SAVE1}} &  csr_save1_rvalue
                    | {32{csr_num==`CSR_SAVE2}} &  csr_save2_rvalue
                    | {32{csr_num==`CSR_SAVE3}} &  csr_save3_rvalue
                    | {32{csr_num==`CSR_ECFG}}  &  csr_ecfg_rvalue
                    | {32{csr_num==`CSR_BADV}}  &  csr_badv_rvalue
                    | {32{csr_num==`CSR_TID}}   &  csr_tid_rvalue
                    | {32{csr_num==`CSR_TCFG}}  &  csr_tcfg_rvalue
                    | {32{csr_num==`CSR_ASID}}  &  csr_asid_rvalue
                    | {32{csr_num==`CSR_TLBIDX}}  &  csr_tlbidx_rvalue
                    | {32{csr_num==`CSR_TLBEHI}}  &  csr_tlbehi_rvalue
                    | {32{csr_num==`CSR_TLBELO0}}  &  csr_tlbelo0_rvalue
                    | {32{csr_num==`CSR_TLBELO1}}  &  csr_tlbelo1_rvalue
                    | {32{csr_num==`CSR_TLBRENTRY}}  &  csr_tlbrentry_rvalue;

endmodule