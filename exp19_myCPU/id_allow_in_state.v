module id_allow_in_state (
    input wire clk,
    input wire rst,
    input wire if_ready_go,
    input wire id_ready_go,
    input wire exe_allow_in,
    output wire id_allow_in
);
    parameter            allow_in   = 1'd1 ;
    parameter            not_allow_in  = 1'd0 ;

    reg st_cur;
    reg st_next;

    always @(posedge clk)
    begin
        if(rst)
        begin
            st_cur <= allow_in;
        end
        else
        begin
            st_cur <= st_next;
        end
    end

    always @(*)
    begin
        case(st_cur)
            allow_in :
                if(if_ready_go===1'b0 || (!(if_ready_go===1'b0)&& !(id_ready_go===1'b0) &&exe_allow_in==1'b1))
                begin
                    st_next  = allow_in;
                end
                else
                begin
                    st_next  = not_allow_in;
                end
            not_allow_in:
                if( !(id_ready_go===1'b0)&&exe_allow_in==1'b1)
                begin
                    st_next = allow_in;
                end
        endcase
    end

    assign id_allow_in = st_cur;
endmodule