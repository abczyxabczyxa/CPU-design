module If_to_id_need_cancel (
    input  wire        clk,               // 时钟信号
    input  wire        rst,               // 异步复位信号
    input  wire        wb_ex,             // 写回异常信号
    input  wire        inst_sram_req,     // 指令SRAM请求信号
    input  wire        inst_sram_addr_ok, // 指令SRAM地址接收OK
    input  wire        inst_sram_data_ok, // 指令SRAM数据接收OK
    input wire         if_ready_go,
    input wire         id_allow_in,
    output wire         id_need_cancel     // 需要取消ID阶段的信号.
);

    // 状态定义(使用localparam优于parameter)
    localparam STATE_NORMAL     = 1'b0;  // 正常状态         
    localparam STATE_NOT_NORMAL = 1'b1;  // 非正常状态

    // 状态寄存器声明
    reg state_curr;  // 当前状态
    reg state_next;   // 下一状态

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
                
                if (((wb_ex && inst_sram_req && inst_sram_addr_ok) ||(wb_ex && inst_sram_req==1'b0 && inst_sram_data_ok==1'b0)) && !(if_ready_go===1'b1 && id_allow_in)) begin
                    state_next = STATE_NOT_NORMAL;
                end
                else
                begin
                    state_next = STATE_NORMAL;
                end
            end
            
            STATE_NOT_NORMAL: begin
                // 当数据OK时返回正常状态
                if (!(if_ready_go===1'b0)&& id_allow_in) begin
                    state_next = STATE_NORMAL;
                end
                else
                begin
                    state_next = STATE_NOT_NORMAL;
                end
            end
        endcase
    end

   
   assign id_need_cancel = state_curr;
endmodule