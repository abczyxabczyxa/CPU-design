module If_to_id_need_cancel (
    input  wire        clk,               // 时钟信号
    input  wire        rst,               // 异步复位信号
    input  wire        wb_ex,             // 写回异常信号
    input  wire        inst_sram_req,     // 指令SRAM请求信号
    input  wire        inst_sram_addr_ok, // 指令SRAM地址接收OK
    input  wire        inst_sram_data_ok, // 指令SRAM数据接收OK
    input wire         if_ready_go,
    input wire         id_allow_in,
    input wire         id_br_taken,
    output wire [1:0]        id_need_cancel     // 需要取消ID阶段的信号.
);

    // 状态定义
    localparam STATE_NORMAL     = 2'b0;  // 正常状态         
    localparam STATE_NOT_NORMAL_one = 2'b1;  // 非正常状态,需要取消1次
    localparam STATE_NOT_NORMAL_two = 2'b10;
    // 状态寄存器声明
    reg [1:0]state_curr;  // 当前状态
    reg [1:0]state_next;   // 下一状态

    // (1) 状态寄存器时序逻辑
    always @(posedge clk) begin
        if (rst) begin
            state_curr <= STATE_NORMAL;  // 复位后进入正常状态
        end else begin
            state_curr <= state_next;   // 状态转移
        end
    end

    // (2) 下一状态组合逻辑
    always @(*) begin
        case(state_curr)
            STATE_NORMAL: begin
                if ((id_br_taken===1'b1) || ((inst_sram_data_ok== 1'b1 || (inst_sram_req==1'b1&&inst_sram_addr_ok==1'b0))&&wb_ex===1'b1) ) begin
                    state_next = STATE_NOT_NORMAL_one;
                end
                else if(wb_ex===1'b1&&(inst_sram_addr_ok==1'b1 || inst_sram_req==1'b0)&&(if_ready_go&&id_allow_in))
                begin
                    state_next = STATE_NOT_NORMAL_one;
                end
                else if(wb_ex===1'b1&&(inst_sram_addr_ok==1'b1 || inst_sram_req==1'b0))
                begin
                    state_next = STATE_NOT_NORMAL_two;
                end
                else
                begin
                    state_next = STATE_NORMAL;
                end
            end
            
            STATE_NOT_NORMAL_one: begin
                // 当数据OK时返回正常状态
                if (!(if_ready_go===1'b0)&& id_allow_in&&wb_ex!=1'b1) begin
                    state_next = STATE_NORMAL;
                end
                else if( ((inst_sram_data_ok== 1'b1 || (inst_sram_req==1'b1&&inst_sram_addr_ok==1'b0))&&wb_ex===1'b1))
                begin
                    state_next = STATE_NOT_NORMAL_one;
                end
                else if(wb_ex===1'b1&&(inst_sram_addr_ok==1'b1 || inst_sram_req==1'b0))
                begin
                    state_next = STATE_NOT_NORMAL_two;
                end
                else
                begin
                    state_next = STATE_NOT_NORMAL_one;
                end
            end
            STATE_NOT_NORMAL_two:begin
                if (!(if_ready_go===1'b0)&& id_allow_in) begin
                    state_next = STATE_NOT_NORMAL_one;
                end
                else if( ((inst_sram_data_ok== 1'b1 || (inst_sram_req==1'b1&&inst_sram_addr_ok==1'b0))&&wb_ex===1'b1))
                begin
                    state_next = STATE_NOT_NORMAL_one;
                end
                else if(wb_ex===1'b1&&(inst_sram_addr_ok==1'b1 || inst_sram_req==1'b0))
                begin
                    state_next = STATE_NOT_NORMAL_two;
                end
                else
                begin
                    state_next = STATE_NOT_NORMAL_two;
                end
            end
        endcase
    end

   
   assign id_need_cancel = state_curr;
endmodule