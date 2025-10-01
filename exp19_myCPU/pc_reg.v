module PC_Reg(
    input wire clk,
    input wire rst,
    input wire wb_ready_go,
    input wire pc_br_taken,
    input wire if_allow_in,
    input wire [31:0] pc_br_target,
    input wire pre_if_ready_go,
    input wire pipline_is_not_stalled,
    input wire wb_ex,
    input wire [1:0] inst_tlb_ex,
    output reg [31:0] if_pc,
    output wire inst_en,
    output wire [31:0] inst_addr,
    output reg [1:0] if_inst_tlb_ex
);
    
    reg [31:0]nextpc;
    assign inst_en = rst? 1'b0 : 1'b1;

    reg [31:0]pc_target_memory;
    reg pc_br_taken_memory;
    always @(posedge clk)
    begin
        if(rst)
        begin
            pc_target_memory <= 32'b0;
            pc_br_taken_memory <= 1'b0;
        end
        else if (!(pre_if_ready_go===1'b0)&&if_allow_in&&wb_ex!=1'b1 && pc_br_taken_memory==1'b1)
        begin
            //if(pc_br_taken_memory===1'b1)
                pc_br_taken_memory <= 1'b0; 
        end
        else if(pc_br_taken&&pipline_is_not_stalled==1'b1)
        begin
            pc_target_memory <= pc_br_target;
            pc_br_taken_memory <= 1'b1;
        end
    end

    assign inst_addr = nextpc;
    
    always @(posedge clk) begin
    if (inst_en == 0) begin
        if_pc <= 32'h1bfffffc;
        nextpc <= if_pc+4;
        if_inst_tlb_ex <= 2'b0;
    end
    else begin
        casez (!(pre_if_ready_go===1'b0)&&if_allow_in)
            1'b1:
            begin 
            if(pc_br_taken_memory===1'b1)
            begin
            if_pc <= nextpc;   //         ¸   
            nextpc <=  pc_target_memory ;
            if_inst_tlb_ex <= inst_tlb_ex ;
            //pc_br_taken_memory <= 1'b0; 
            end
            else
            begin
            if_pc <= nextpc;   //         ¸   
            nextpc <= nextpc+4;
            if_inst_tlb_ex <= inst_tlb_ex;
            end
            end
            1'b0:
            begin 
            if_pc <= if_pc;    //       ʱ    
            nextpc <= nextpc;
            if_inst_tlb_ex <= if_inst_tlb_ex;
            end
            default:
            begin 
            if(pc_br_taken_memory===1'b1)
            begin
            if_pc <= nextpc;   //         ¸   
            nextpc <=  pc_target_memory ;
            if_inst_tlb_ex <= inst_tlb_ex;
            //pc_br_taken_memory <= 1'b0; 
            end
            else
            begin
            if_pc <= nextpc;   //         ¸   
            nextpc <= nextpc+4;
            if_inst_tlb_ex <= inst_tlb_ex;
            end
            end
        endcase
    end
end
endmodule