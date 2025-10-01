module ID_Reg (
    input wire clk,
    input wire rst,
    input wire if_ready_go,
    input wire id_inst_cancel,
    input wire exe_addr_shake_ok,
    input wire exe_data_ram_req,
    input wire exe_data_ram_addr_ok,
    input wire wb_is_ertn,
    input wire [31:0] if_pc,
    input wire [31:0] if_inst,
    input wire wb_ex,
    input wire pipline_is_not_stalled,
    input wire [1:0]id_need_cancel,
    input wire id_allow_in,
    input wire exe_allow_in,
    output reg [31:0] id_pc,
    output reg [31:0] id_inst,
    output reg ID_need_cancel
);
    
    wire [31:0]if_to_id_inst;
    reg [31:0] if_to_id_inst_memory;
    reg if_to_id_memory;

    always @(posedge clk)
    begin
        if(rst)
        begin
            if_to_id_inst_memory <= 32'b0;
            if_to_id_memory <= 1'b0;
        end
        else if((!(if_ready_go===1'b0)&&id_allow_in)||wb_ex===1'b1)
        begin
            if_to_id_memory <= 1'b0 ;
        end
        else if(!(if_ready_go===1'b0) && id_allow_in==1'b0 && if_to_id_memory==1'b0)
        begin
            if_to_id_inst_memory <= if_to_id_inst;
            if_to_id_memory <= 1'b1;
        end
    end

    assign if_to_id_inst = (id_need_cancel!=2'b0) ? 32'h02800000 : if_inst; 
    always @(posedge clk) begin
    if (rst || wb_ex===1'b1||wb_is_ertn===1'b1) begin
        id_pc   <= 32'h1bfffffc;
        id_inst <= 32'h0;
        ID_need_cancel <= 1'b0;
    end
    else begin
        casez (!(if_ready_go===1'b0)&&id_allow_in)
            1'b1: begin
                id_pc   <= if_pc;
                id_inst <= id_inst_cancel? 32'h02800000:
                           if_to_id_memory ? if_to_id_inst_memory : if_to_id_inst;
                //if_to_id_memory <= 1'b0;
                ID_need_cancel <= id_need_cancel!=2'b0;
            end
            1'b0: begin
                if(exe_addr_shake_ok===1'b0)
                begin
                    id_pc <= id_pc;
                    id_inst <= id_inst;
                    ID_need_cancel <= ID_need_cancel;
                end
                else if(exe_allow_in==1'b0)
                begin
                    id_pc <= id_pc;
                    id_inst <= id_inst;
                    ID_need_cancel <= ID_need_cancel;
                end
                else if(exe_data_ram_req && exe_data_ram_addr_ok)
                begin
                    id_pc <= id_pc;
                    id_inst <= id_inst;
                    ID_need_cancel <= ID_need_cancel;
                end
                else if(pipline_is_not_stalled===1'b1)
                begin
                    id_pc <= 32'b0;
                    id_inst <=32'h02800000;
                    ID_need_cancel <= 1'b0;
                end
                else
                begin
                    id_pc   <= id_pc;
                    id_inst <= id_inst;
                    ID_need_cancel <= ID_need_cancel;
                end
            end
            default: begin  // if_ready_go Ϊ x    z
                id_pc   <= if_pc;
                id_inst <= id_inst_cancel? 32'h02800000:
                           if_to_id_memory ? if_to_id_inst_memory : if_to_id_inst;
                //if_to_id_memory <= 1'b0;
                ID_need_cancel <= id_need_cancel!=2'b0;
            end
        endcase
    end
end


endmodule