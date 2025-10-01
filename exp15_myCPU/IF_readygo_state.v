module IF_readygo_state (
    input wire clk,
    input wire rst,
    input wire id_allow_in,
    input wire if_ready_go,
    output wire IF_ready_go
);
    parameter readygo = 1'b1;
    parameter notreadygo = 1'b0;

    reg st_cur;
    reg st_next;

    always @(posedge clk)
    begin
        if(rst)
        begin
            st_cur <= notreadygo;
        end
        else
        begin
            st_cur <= st_next;
        end
    end

    always @(*)
    begin
        case (st_cur)
            readygo:
            begin
                if(id_allow_in)
                begin
                    st_next = notreadygo;
                end
                else 
                begin
                    st_next = readygo;
                end
            end 
            notreadygo:
                if(if_ready_go===1'b1 && id_allow_in==1'b0)
                begin
                    st_next = readygo;
                end
                else
                begin
                    st_next <= notreadygo;
                end
        endcase
    end

    assign IF_ready_go = st_cur;
endmodule