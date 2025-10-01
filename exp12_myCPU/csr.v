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
`define ESUBCODE_ADEF 1'b1
`define CSR_TID 14'h40
`define CSR_TID_TID 31:0
`define CSR_TCFG_EN 0
`define CSR_TCFG_PERIOD 1
`define CSR_TCFG_INITV 30:2
`define CSR_TCFG 14'h41

module CSR (
    input wire clk,
    input wire rst,
    input wire [13:0]csr_num,      //寄存器编�?,相当于地�?，手�?7.1节有规定
    input wire csr_we,             //写使�?
    input wire [31:0] csr_wmask,    //掩码，用于写操作
    input wire [31:0] csr_wvalue,  //写数�?

    output wire [31:0] csr_rvalue, //读数�?
    
    input wire wb_ex_ale,             //地址放存错误
    input wire [31:0] wb_ex_ale_addr,    //出错的访存地�?
    input wire [31:0] wb_pc,
    input wire [31:0] coreid_in,      //进入�?31位的计时器编�?

    input wire wb_ertn_flush,      //  来自写回级ertn指令有效,与写操作相关
    input wire wb_ex,              //  来自写回级的异常触发信号，与写操作相�?
    input wire [5:0]wb_ecode,      //�?7-7中异常的编码，与写操作相�?
    input wire [7:0]wb_esubcode,   //�?7-7中异常的编码，与写操作相�?
    input wire [7:0]hw_int_in,     //硬件输入，先不管
    input wire ipi_int_in,          //先不�?
    
    output reg[31:0] csr_era_pc,
    output reg[12:0] csr_ecfg_lie,
    output reg[12:0] csr_estat_is,
    output reg csr_crmd_ie,
    output reg [63:0]csr_timer_64,
    output reg [31:0]csr_tid_tid
);
    
    reg [1:0]csr_crmd_plv;
    reg [1:0]csr_prmd_pplv;
   
    reg csr_prmd_pie;
    wire csr_crmd_da;
    wire csr_crmd_pg;
    wire [1:0]csr_crmd_datf;
    wire [1:0]csr_crmd_datm;
   
    reg [5:0]csr_estat_ecode;
    reg [8:0]csr_estat_esubcode;
    reg [25:0]csr_eentry_va;
    reg [31:0]csr_save0_data;
    reg [31:0]csr_save1_data;
    reg [31:0]csr_save2_data;
    reg [31:0]csr_save3_data;
    
    reg [31:0]timer_cnt;
    reg csr_tcfg_en;
    reg csr_tcfg_periodic;
    reg [29:0]csr_tcfg_initval;
    wire [31:0]tcfg_next_value;
    wire [31:0]csr_tval;
    reg [31:0] csr_badv_vaddr;


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

    always @(posedge clk)
    begin
        if(csr_we && wb_ex_ale)
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
    

    assign csr_rvalue={32{csr_num==`CSR_CRMD}}  &  csr_crmd_rvalue
                    | {32{csr_num==`CSR_PRMD}}  &  csr_prmd_rvalue
                    | {32{csr_num==`CSR_ESTAT}} &  csr_estat_rvalue
                    | {32{csr_num==`CSR_ERA}}   &  csr_era_rvalue
                    | {32{csr_num==`CSR_EENTRY}}&  csr_eentry_rvalue
                    | {32{csr_num==`CSR_SAVE0}} &  csr_save0_rvalue
                    | {32{csr_num==`CSR_SAVE1}} &  csr_save1_rvalue
                    | {32{csr_num==`CSR_SAVE2}} &  csr_save2_rvalue
                    | {32{csr_num==`CSR_SAVE3}} &  csr_save3_rvalue
                    | {32{csr_num==`CSR_ECFG}}  &  csr_tcfg_rvalue
                    | {32{csr_num==`CSR_BADV}}  &  csr_badv_rvalue
                    | {32{csr_num==`CSR_TID}}   &  csr_tid_rvalue
                    | {32{csr_num==`CSR_TCFG}}  &  csr_tcfg_rvalue;
endmodule