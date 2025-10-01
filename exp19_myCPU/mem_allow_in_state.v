module mem_allow_in_state (
    input wire clk,
    input wire rst,
    input wire exe_ready_go,
    input wire mem_ready_go,
    input wire wb_allow_in,
    output wire mem_allow_in
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
                if(exe_ready_go===1'b0 || ( !(exe_ready_go===1'b0)&& !(mem_ready_go===1'b0) &&wb_allow_in==1'b1))
                begin
                    st_next  = allow_in;
                end
                else
                begin
                    st_next  = not_allow_in;
                end
            not_allow_in:
                if( !(mem_ready_go===1'b0)&&wb_allow_in==1'b1)
                begin
                    st_next = allow_in;
                end
                else
                begin
                    st_next =not_allow_in;
                end
        endcase
    end

    assign mem_allow_in = st_cur;
endmodule