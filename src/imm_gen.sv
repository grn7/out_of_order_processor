// Immediate Generator for RISC-V Instructions
// Extracts and sign-extends immediates based on instruction format

import riscv_defines::*;

module imm_gen (
    input  logic [31:0]     instruction,
    input  inst_format_e    format,
    output logic [31:0]     imm
);

always_comb begin
    case (format)
        I_TYPE: begin
            // I-type: imm[11:0] = inst[31:20]
            imm = {{20{instruction[31]}}, instruction[31:20]};
        end
        
        S_TYPE: begin
            // S-type: imm[11:0] = {inst[31:25], inst[11:7]}
            imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        end
        
        B_TYPE: begin
            // B-type: imm[12:1] = {inst[31], inst[7], inst[30:25], inst[11:8]}
            imm = {{19{instruction[31]}}, instruction[31], instruction[7], 
                   instruction[30:25], instruction[11:8], 1'b0};
        end
        
        U_TYPE: begin
            // U-type: imm[31:12] = inst[31:12], imm[11:0] = 0
            imm = {instruction[31:12], 12'b0};
        end
        
        J_TYPE: begin
            // J-type: imm[20:1] = {inst[31], inst[19:12], inst[20], inst[30:21]}
            imm = {{11{instruction[31]}}, instruction[31], instruction[19:12], 
                   instruction[20], instruction[30:21], 1'b0};
        end
        
        default: begin
            imm = 32'b0;
        end
    endcase
end

endmodule
