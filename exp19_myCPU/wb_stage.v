module Wb_stage(
    input  wire        wb_is_syscall,  
    input  wire        wb_is_ertn,   
    input  wire        wb_ex_adef, 
    input  wire        wb_ex_ale,      
    input  wire        wb_ex_brk,    
    input  wire        wb_ex_ine,     
    input  wire        wb_has_int,    
    input wire       wb_need_cancel,
    input wire   [1:0] wb_inst_tlb_ex,
    input wire   [2:0] wb_data_tlb_ex,
    
    output reg  [5:0]  wb_ecode,     
    output reg  [7:0]  wb_esubcode,   
    output reg         wb_ex          
);

    localparam INT     = 6'h00;  
    localparam ADEF    = 6'h08;  
    localparam ALE     = 6'h09;  
    localparam SYS     = 6'h0B;  
    localparam BRK     = 6'h0C;  
    localparam INE     = 6'h0D;  
    localparam PIL     = 6'h01;
    localparam PIS     = 6'h02;
    localparam PIF     = 6'h03;
    localparam PME     = 6'h04;
    localparam PPI     = 6'h07;
    localparam TLBR    = 6'h3f;

    always @(*) begin
        wb_ex = wb_need_cancel==1'b0 &&(wb_has_int===1'b1 || wb_ex_adef===1'b1 || wb_ex_ale===1'b1 || wb_is_syscall===1'b1 || wb_ex_brk===1'b1 || wb_ex_ine===1'b1 || wb_is_ertn ===1'b1 || wb_data_tlb_ex != 3'b0 || wb_inst_tlb_ex != 2'b0);
        
        // （中断 > ADEF > ALE > 系统调用 > 断点 > 指令不存在）
        if ((wb_is_ertn===1'b0||wb_is_ertn===1'bx) && wb_has_int===1'b1)
            wb_ecode = INT;
        else if((wb_is_ertn===1'b0||wb_is_ertn===1'bx) && wb_data_tlb_ex == 3'h2 )
            wb_ecode = PIL;
        else if((wb_is_ertn===1'b0||wb_is_ertn===1'bx) && wb_data_tlb_ex == 3'h3 )
            wb_ecode = PIS;
        else if((wb_is_ertn===1'b0||wb_is_ertn===1'bx) && wb_inst_tlb_ex == 2'h2 )
            wb_ecode = PIF;
        else if((wb_is_ertn===1'b0||wb_is_ertn===1'bx) && wb_data_tlb_ex == 3'h5 )
            wb_ecode = PME;
        else if((wb_is_ertn===1'b0||wb_is_ertn===1'bx) && (wb_data_tlb_ex == 3'h4 ||wb_inst_tlb_ex == 2'h3) )
            wb_ecode = PPI;
        else if((wb_is_ertn===1'b0||wb_is_ertn===1'bx) && (wb_data_tlb_ex == 3'h1 ||wb_inst_tlb_ex == 2'h1) )
            wb_ecode = TLBR;
        else if ((wb_is_ertn===1'b0||wb_is_ertn===1'bx) && wb_ex_adef===1'b1)
            wb_ecode = ADEF;
        else if ((wb_is_ertn===1'b0||wb_is_ertn===1'bx) && wb_ex_ale===1'b1)
            wb_ecode = ALE;
        else if ((wb_is_ertn===1'b0||wb_is_ertn===1'bx) && wb_is_syscall===1'b1)
            wb_ecode = SYS;
        else if ((wb_is_ertn===1'b0||wb_is_ertn===1'bx) && wb_ex_brk===1'b1)
            wb_ecode = BRK;
        else if ((wb_is_ertn===1'b0||wb_is_ertn===1'bx) && wb_ex_ine===1'b1)
            wb_ecode = INE;
        else
            wb_ecode = 6'h00;
            
        wb_esubcode = 8'h00;
    end

endmodule