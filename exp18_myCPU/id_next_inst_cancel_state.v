module id_next_inst_cancel (
    input clk,
    input rst,
    input if_ready_go,
    input id_allow_in,
    input id_br_taken,
    input pre_if_ready_go,
    input if_allow_in,
    output id_next_inst_cancel
);

    parameter            need_cancel   = 1'd1 ;
    parameter            not_need_cancel  = 1'd0 ;

    reg st_cur;
    reg st_next;

    always @(posedge clk)
    begin
        if(rst)
        begin
            st_cur <= not_need_cancel;
        end 
        else 
        begin
            st_cur <= st_next;
        end
    end

    always @(*)
    begin
        case (st_cur)
            not_need_cancel:
            begin
                if(id_br_taken===1'b1 && !(pre_if_ready_go===1'b0)&& if_allow_in)
                begin
                    st_next = need_cancel;
                end
                else
                begin
                    st_next =not_need_cancel;
                end
            end 
            need_cancel:
            begin
                if(id_allow_in && !(if_ready_go===1'b0))
                begin
                    st_next =not_need_cancel;
                end
                else
                begin
                    st_next = need_cancel;
                end
            end
        endcase
    end
    assign id_next_inst_cancel = st_cur;
endmodule