module Data_ram_state (
    input wire clk,
    input wire rst,
    input wire addr_ok,
    input wire data_ok,
    input wire req,
    output wire data_req_valid
);

    //machine state decode
    parameter            Can_Send_Request   = 1'd1 ;
    parameter            Cannot_Send_Request  = 1'd0 ;

    wire    Is_Address_Handshake_Succeeded;
    wire    Is_Data_Handshake_Succeeded;
    assign Is_Address_Handshake_Succeeded = addr_ok && req ;
    assign Is_Data_Handshake_Succeeded = data_ok ;

    //machine variable
    reg             st_next ;
    reg             st_cur ;

    // (1) 状态转移（时序逻辑）
    always @(posedge clk ) begin
        if (rst) begin
            st_cur <= Can_Send_Request;  // 复位后进入可发送请求状态
        end else begin
            st_cur <= st_next;
        end
    end

    //(2) state switch, using block assignment for combination-logic
    //all case items need to be displayed completely    
    always @(*) begin
        case(st_cur)
            Can_Send_Request:
                case (Is_Address_Handshake_Succeeded)
                    1'b0:     st_next = Can_Send_Request ;
                    1'b1:     st_next = Cannot_Send_Request ;
                    default:   st_next = Can_Send_Request ;
                endcase
            Cannot_Send_Request:
                case (Is_Data_Handshake_Succeeded)
                    1'b0:     st_next = Cannot_Send_Request ;
                    1'b1:     st_next = Can_Send_Request ;
                    default:   st_next = Cannot_Send_Request ;
                endcase
            default:    st_next = Can_Send_Request ;
        endcase
    end


    assign data_req_valid = st_cur;

endmodule