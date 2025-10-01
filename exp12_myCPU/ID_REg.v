module ID_Reg (
    input wire clk,
    input wire rst,
    input wire if_ready_go,
    input wire wb_is_ertn,
    input wire [31:0] if_pc,
    input wire [31:0] if_inst,
    input wire wb_ex,
    output reg [31:0] id_pc,
    output reg [31:0] id_inst
);
    always @(posedge clk) begin
    if (rst || wb_ex===1'b1||wb_is_ertn===1'b1) begin
        id_pc   <= 32'h1bfffffc;
        id_inst <= 32'h0;
    end
    else begin
        casez (if_ready_go)
            1'b1: begin
                id_pc   <= if_pc;
                id_inst <= if_inst;
            end
            1'b0: begin
                id_pc   <= id_pc;
                id_inst <= id_inst;
            end
            default: begin  // if_ready_go 为 x 或 z
                id_pc   <= if_pc;
                id_inst <= if_inst;
            end
        endcase
    end
end


endmodule