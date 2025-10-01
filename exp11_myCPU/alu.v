module ALU(
    input  wire [31:0] src1,
    input  wire [31:0] src2,
    input  wire [4:0]  alu_op,
    input  wire [31:0] exe_pc,
    input wire [31:0] alu_rf_src1,
    input wire [31:0] alu_rf_src2,
    output reg  [31:0] exe_alu_result,
    output reg         exe_br_taken,
    output reg  [31:0] exe_br_target
);

    wire [63:0] mul_signed_result;
    wire [63:0] mul_unsigned_result;
    assign mul_signed_result = $signed(src1) * $signed(src2);
    assign mul_unsigned_result = src1 * src2;

    always @(*) begin
        exe_alu_result = 32'b0;
        exe_br_taken = 1'b0;
        exe_br_target = exe_pc + 4;
        
        case (alu_op)
            5'd0: begin 
                exe_alu_result = src1 + src2;
            end
            
            5'd1: begin 
                exe_alu_result = src1 - src2;
            end
            
            5'd2: begin 
                if ($signed(src1) < $signed(src2))
                    exe_alu_result = 32'd1;
                else
                    exe_alu_result = 32'd0;
            end
            
            5'd3: begin 
                if (src1 < src2)
                    exe_alu_result = 32'd1;
                else
                    exe_alu_result = 32'd0;
            end
            
            5'd4: begin
                exe_alu_result = src1 & src2;
            end
            
            5'd5: begin 
                exe_alu_result = src1 | src2;
            end
            
            5'd6: begin 
                exe_alu_result = ~(src1 | src2);
            end
            
            5'd7: begin 
                exe_alu_result = src1 ^ src2;
            end
            
            5'd8: begin
                exe_alu_result = src1 << src2[4:0];
            end
            
            5'd9: begin
                exe_alu_result = src1 >> src2[4:0];
            end
            
            5'd10: begin 
                exe_alu_result = $signed(src1) >>> src2[4:0];
            end
            
            5'd11: begin  
                if (alu_rf_src1 == alu_rf_src2) begin
                    exe_br_taken = 1'b1;
                    exe_br_target = exe_pc + src2; 
                end
            end
            
            5'd12: begin 
                if (alu_rf_src1 != alu_rf_src2) begin
                    exe_br_taken = 1'b1;
                    exe_br_target = exe_pc + src2; 
                end
            end
            
            5'd13: begin
                exe_alu_result = exe_pc + 4;
                exe_br_taken = 1'b1;
                exe_br_target = exe_pc + src2; 
            end
            
            5'd14: begin 
                exe_alu_result = exe_pc + 4;
                exe_br_taken = 1'b1;
                exe_br_target = src1 + src2; 
            end
            
            5'd15: begin 
                exe_alu_result = {src2[19:0], 12'b0}; 
            end

             5'd16: begin 
                exe_alu_result = {src2[19:0], 12'b0} + exe_pc; 
            end
            
            5'd17: begin 
                exe_alu_result = mul_signed_result[31:0];
            end
            
            5'd18: begin 
                exe_alu_result = mul_signed_result[63:32];
            end
            
            5'd19: begin 
                exe_alu_result = mul_unsigned_result[63:32];
            end
            
            5'd20: begin 
                if (src2 != 0)
                    exe_alu_result = $signed(src1) / $signed(src2); 
                else
                    exe_alu_result = 32'hffffffff;
            end
            
            5'd21: begin 
                if (src2 != 0)
                    exe_alu_result = src1 / src2; 
                else
                    exe_alu_result = 32'hffffffff; 
            end
            
            5'd22: begin 
                if (src2 != 0)
                    exe_alu_result = $signed(src1) % $signed(src2); 
                else
                    exe_alu_result = src1; 
            end
            
            5'd23: begin 
                if (src2 != 0)
                    exe_alu_result = src1 % src2; 
                else
                    exe_alu_result = src1; 
            end
            
            default: begin
                exe_alu_result = 32'b0;
                exe_br_taken = 1'b0;
                exe_br_target = 32'b0;
            end
        endcase
    end
endmodule