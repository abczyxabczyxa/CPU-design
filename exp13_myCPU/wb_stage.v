module Wb_stage(
    input  wire        wb_is_syscall,  
    input  wire        wb_is_ertn,   
    input  wire        wb_ex_adef, 
    input  wire        wb_ex_ale,      
    input  wire        wb_ex_brk,    
    input  wire        wb_ex_ine,     
    input  wire        wb_has_int,    
    
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

    always @(*) begin
        wb_ex = (wb_is_ertn===1'b0||wb_is_ertn===1'bx) && (wb_has_int===1'b1 || wb_ex_adef===1'b1 || wb_ex_ale===1'b1 || 
                                wb_is_syscall===1'b1 || wb_ex_brk===1'b1 || wb_ex_ine===1'b1);
        
        // （中断 > ADEF > ALE > 系统调用 > 断点 > 指令不存在）
        if ((wb_is_ertn===1'b0||wb_is_ertn===1'bx) && wb_has_int===1'b1)
            wb_ecode = INT;
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