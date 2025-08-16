// RISC-V 32-bit I+M+F Instruction Decoder
// Decodes all supported RISC-V instructions and pseudo-instructions

import riscv_defines::*;

module instruction_decoder (
    input  logic        clk,
    input  logic        rst,
    input  logic        valid_in,
    input  logic [31:0] pc_in,
    input  logic [31:0] instruction_in,
    output decoded_inst_t decoded_inst
);

// Internal signals
logic [6:0]  opcode;
logic [4:0]  rd, rs1, rs2, rs3;
logic [2:0]  func3;
logic [6:0]  func7;
logic [4:0]  func5;
logic [1:0]  fmt;        // Format field for FP instructions
logic [2:0]  rm;         // Rounding mode for FP instructions

inst_format_e inst_format;
logic [31:0]  immediate;

// Extract instruction fields
assign opcode = instruction_in[6:0];
assign rd     = instruction_in[11:7];
assign func3  = instruction_in[14:12];
assign rs1    = instruction_in[19:15];
assign rs2    = instruction_in[24:20];
assign func7  = instruction_in[31:25];
assign rs3    = instruction_in[31:27];  // For R4-type FP instructions
assign func5  = instruction_in[31:27];  // For FP instructions
assign fmt    = instruction_in[26:25];  // Format field for FP
assign rm     = instruction_in[14:12];  // Rounding mode for FP

// Immediate generator instance
imm_gen imm_gen_inst (
    .instruction(instruction_in),
    .format(inst_format),
    .imm(immediate)
);

// Determine instruction format based on opcode
always_comb begin
    case (opcode)
        OP_LOAD, OP_LOAD_FP, OP_IMM, OP_JALR, OP_SYSTEM: begin
            inst_format = I_TYPE;
        end
        OP_STORE, OP_STORE_FP: begin
            inst_format = S_TYPE;
        end
        OP_BRANCH: begin
            inst_format = B_TYPE;
        end
        OP_LUI, OP_AUIPC: begin
            inst_format = U_TYPE;
        end
        OP_JAL: begin
            inst_format = J_TYPE;
        end
        OP_REG, OP_FP: begin
            inst_format = R_TYPE;
        end
        OP_FMADD, OP_FMSUB, OP_FNMSUB, OP_FNMADD: begin
            inst_format = R_TYPE;  // R4-type is treated as R-type with rs3
        end
        default: begin
            inst_format = UNKNOWN_TYPE;
        end
    endcase
end

// Main decoder logic
always_ff @(posedge clk) begin
    if (rst) begin
        decoded_inst <= '0;
    end else begin
        // Default values
        decoded_inst.valid <= valid_in;
        decoded_inst.pc <= pc_in;
        decoded_inst.instruction <= instruction_in;
        decoded_inst.format <= inst_format;
        decoded_inst.opcode <= opcode_e'(opcode);
        decoded_inst.func3 <= func3;
        decoded_inst.func7 <= func7;
        decoded_inst.imm <= immediate;
        
        // Default register addresses
        decoded_inst.rs1_addr <= rs1;
        decoded_inst.rs2_addr <= rs2;
        decoded_inst.rs3_addr <= rs3;
        decoded_inst.rd_addr <= rd;
        
        // Default control signals
        decoded_inst.rs1_en <= 1'b0;
        decoded_inst.rs2_en <= 1'b0;
        decoded_inst.rs3_en <= 1'b0;
        decoded_inst.rd_en <= 1'b0;
        decoded_inst.is_fp_rs1 <= 1'b0;
        decoded_inst.is_fp_rs2 <= 1'b0;
        decoded_inst.is_fp_rs3 <= 1'b0;
        decoded_inst.is_fp_rd <= 1'b0;
        
        // Default operation signals
        decoded_inst.is_load <= 1'b0;
        decoded_inst.is_store <= 1'b0;
        decoded_inst.is_branch <= 1'b0;
        decoded_inst.is_jump <= 1'b0;
        
        decoded_inst.exec_unit <= UNKNOWN_UNIT;
        decoded_inst.alu_op <= ALU_ADD;
        decoded_inst.fp_alu_op <= FP_ADD;
        decoded_inst.branch_op <= BRANCH_EQ;
        
        if (valid_in) begin
            case (opcode)
                OP_IMM: begin
                    // I-type immediate operations (addi, slli, etc.)
                    decoded_inst.exec_unit <= ALU_UNIT;
                    decoded_inst.rs1_en <= 1'b1;
                    decoded_inst.rd_en <= 1'b1;
                    
                    case (func3)
                        FUNC3_ADDI: begin
                            decoded_inst.alu_op <= ALU_ADD;
                            // Handle mv pseudo-instruction (addi rd, rs, 0)
                            if (immediate == 32'b0) begin
                                decoded_inst.alu_op <= ALU_COPY_A;
                            end
                        end
                        FUNC3_SLTI:  decoded_inst.alu_op <= ALU_SLT;
                        FUNC3_SLTIU: decoded_inst.alu_op <= ALU_SLTU;
                        FUNC3_XORI:  decoded_inst.alu_op <= ALU_XOR;
                        FUNC3_ORI:   decoded_inst.alu_op <= ALU_OR;
                        FUNC3_ANDI:  decoded_inst.alu_op <= ALU_AND;
                        FUNC3_SLLI:  decoded_inst.alu_op <= ALU_SLL;
                        FUNC3_SRLI_SRAI: begin
                            if (func7[5]) 
                                decoded_inst.alu_op <= ALU_SRA;
                            else 
                                decoded_inst.alu_op <= ALU_SRL;
                        end
                        default: decoded_inst.alu_op <= ALU_ADD;
                    endcase
                end
                
                OP_REG: begin
                    // R-type register operations
                    decoded_inst.exec_unit <= ALU_UNIT;
                    decoded_inst.rs1_en <= 1'b1;
                    decoded_inst.rs2_en <= 1'b1;
                    decoded_inst.rd_en <= 1'b1;
                    
                    case (func3)
                        FUNC3_ADD_SUB: begin
                            if (func7 == FUNC7_MUL) begin
                                decoded_inst.alu_op <= ALU_MUL;
                            end else if (func7[5]) begin
                                decoded_inst.alu_op <= ALU_SUB;
                            end else begin
                                decoded_inst.alu_op <= ALU_ADD;
                            end
                        end
                        FUNC3_SLL:    decoded_inst.alu_op <= ALU_SLL;
                        FUNC3_SLT:    decoded_inst.alu_op <= ALU_SLT;
                        FUNC3_SLTU:   decoded_inst.alu_op <= ALU_SLTU;
                        FUNC3_XOR:    decoded_inst.alu_op <= ALU_XOR;
                        FUNC3_SRL_SRA: begin
                            if (func7[5]) 
                                decoded_inst.alu_op <= ALU_SRA;
                            else 
                                decoded_inst.alu_op <= ALU_SRL;
                        end
                        FUNC3_OR:     decoded_inst.alu_op <= ALU_OR;
                        FUNC3_AND:    decoded_inst.alu_op <= ALU_AND;
                        3'b100: begin  // DIV operations
                            if (func7 == FUNC7_DIV) begin
                                decoded_inst.alu_op <= ALU_DIV;
                            end
                        end
                        default: decoded_inst.alu_op <= ALU_ADD;
                    endcase
                end
                
                OP_LOAD: begin
                    // Load instructions (lw)
                    decoded_inst.exec_unit <= LOAD_UNIT;
                    decoded_inst.rs1_en <= 1'b1;
                    decoded_inst.rd_en <= 1'b1;
                    decoded_inst.is_load <= 1'b1;
                end
                
                OP_LOAD_FP: begin
                    // Floating-point load instructions (flw)
                    decoded_inst.exec_unit <= LOAD_UNIT;
                    decoded_inst.rs1_en <= 1'b1;
                    decoded_inst.rd_en <= 1'b1;
                    decoded_inst.is_fp_rd <= 1'b1;
                    decoded_inst.is_load <= 1'b1;
                end
                
                OP_STORE: begin
                    // Store instructions (sw)
                    decoded_inst.exec_unit <= STORE_UNIT;
                    decoded_inst.rs1_en <= 1'b1;
                    decoded_inst.rs2_en <= 1'b1;
                    decoded_inst.is_store <= 1'b1;
                end
                
                OP_STORE_FP: begin
                    // Floating-point store instructions (fsw)
                    decoded_inst.exec_unit <= STORE_UNIT;
                    decoded_inst.rs1_en <= 1'b1;
                    decoded_inst.rs2_en <= 1'b1;
                    decoded_inst.is_fp_rs2 <= 1'b1;
                    decoded_inst.is_store <= 1'b1;
                end
                
                OP_BRANCH: begin
                    // Branch instructions
                    decoded_inst.exec_unit <= BRANCH_UNIT;
                    decoded_inst.rs1_en <= 1'b1;
                    decoded_inst.rs2_en <= 1'b1;
                    decoded_inst.is_branch <= 1'b1;
                    
                    case (func3)
                        FUNC3_BEQ:  decoded_inst.branch_op <= BRANCH_EQ;
                        FUNC3_BNE:  decoded_inst.branch_op <= BRANCH_NE;
                        FUNC3_BLT:  decoded_inst.branch_op <= BRANCH_LT;
                        FUNC3_BGE:  decoded_inst.branch_op <= BRANCH_GE;
                        FUNC3_BLTU: decoded_inst.branch_op <= BRANCH_LTU;
                        FUNC3_BGEU: decoded_inst.branch_op <= BRANCH_GEU;
                        default: decoded_inst.branch_op <= BRANCH_EQ;
                    endcase
                end
                
                OP_JAL: begin
                    // Jump and link (j pseudo-instruction uses x0 as rd)
                    decoded_inst.exec_unit <= BRANCH_UNIT;
                    decoded_inst.rd_en <= (rd != 5'b0);
                    decoded_inst.is_jump <= 1'b1;
                end
                
                OP_JALR: begin
                    // Jump and link register (ret pseudo-instruction)
                    decoded_inst.exec_unit <= BRANCH_UNIT;
                    decoded_inst.rs1_en <= 1'b1;
                    decoded_inst.rd_en <= (rd != 5'b0);
                    decoded_inst.is_jump <= 1'b1;
                end
                
                OP_LUI: begin
                    // Load upper immediate (li pseudo-instruction uses lui)
                    decoded_inst.exec_unit <= ALU_UNIT;
                    decoded_inst.rd_en <= 1'b1;
                    decoded_inst.alu_op <= ALU_COPY_B;  // Copy immediate to rd
                end
                
                OP_AUIPC: begin
                    // Add upper immediate to PC (for la pseudo-instruction)
                    decoded_inst.exec_unit <= ALU_UNIT;
                    decoded_inst.rd_en <= 1'b1;
                    decoded_inst.alu_op <= ALU_ADD;  // PC + immediate
                end
                
                OP_FP: begin
                    // Floating-point operations
                    decoded_inst.rs1_en <= 1'b1;
                    decoded_inst.rs2_en <= 1'b1;
                    decoded_inst.rd_en <= 1'b1;
                    decoded_inst.is_fp_rs1 <= 1'b1;
                    decoded_inst.is_fp_rs2 <= 1'b1;
                    decoded_inst.is_fp_rd <= 1'b1;
                    
                    case (func5)
                        FUNC5_FADD: begin
                            decoded_inst.exec_unit <= FP_ALU_UNIT;
                            decoded_inst.fp_alu_op <= FP_ADD;
                        end
                        FUNC5_FSUB: begin
                            decoded_inst.exec_unit <= FP_ALU_UNIT;
                            decoded_inst.fp_alu_op <= FP_SUB;
                        end
                        FUNC5_FMUL: begin
                            decoded_inst.exec_unit <= FP_MUL_UNIT;
                            decoded_inst.fp_alu_op <= FP_MUL;
                        end
                        FUNC5_FDIV: begin
                            decoded_inst.exec_unit <= FP_DIV_UNIT;
                            decoded_inst.fp_alu_op <= FP_DIV;
                        end
                        FUNC5_FSQRT: begin
                            decoded_inst.exec_unit <= FP_DIV_UNIT;
                            decoded_inst.fp_alu_op <= FP_SQRT;
                            decoded_inst.rs2_en <= 1'b0;  // Single operand
                        end
                        FUNC5_FSGNJ: begin
                            decoded_inst.exec_unit <= FP_ALU_UNIT;
                            case (func3)
                                3'b000: decoded_inst.fp_alu_op <= FP_SGNJ;   // fmv.s pseudo
                                3'b001: decoded_inst.fp_alu_op <= FP_SGNJN;
                                3'b010: decoded_inst.fp_alu_op <= FP_SGNJX;
                                default: decoded_inst.fp_alu_op <= FP_SGNJ;
                            endcase
                        end
                        FUNC5_FMIN_FMAX: begin
                            decoded_inst.exec_unit <= FP_ALU_UNIT;
                            if (func3[0])
                                decoded_inst.fp_alu_op <= FP_MAX;
                            else
                                decoded_inst.fp_alu_op <= FP_MIN;
                        end
                        FUNC5_FCMP: begin
                            decoded_inst.exec_unit <= FP_ALU_UNIT;
                            decoded_inst.is_fp_rd <= 1'b0;  // Result goes to integer register
                            case (func3)
                                3'b010: decoded_inst.fp_alu_op <= FP_EQ;
                                3'b001: decoded_inst.fp_alu_op <= FP_LT;
                                3'b000: decoded_inst.fp_alu_op <= FP_LE;
                                default: decoded_inst.fp_alu_op <= FP_EQ;
                            endcase
                        end
                        FUNC5_FMV_W_X: begin
                            decoded_inst.exec_unit <= FP_ALU_UNIT;
                            decoded_inst.fp_alu_op <= FP_MV_W_X;
                            decoded_inst.is_fp_rs1 <= 1'b0;  // rs1 is integer register
                            decoded_inst.rs2_en <= 1'b0;     // Single operand
                        end
                        FUNC5_FMV_X_W: begin
                            decoded_inst.exec_unit <= FP_ALU_UNIT;
                            decoded_inst.fp_alu_op <= FP_MV_X_W;
                            decoded_inst.is_fp_rd <= 1'b0;   // rd is integer register
                            decoded_inst.rs2_en <= 1'b0;     // Single operand
                        end
                        FUNC5_FCVT_W: begin
                            decoded_inst.exec_unit <= FP_ALU_UNIT;
                            decoded_inst.fp_alu_op <= FP_CVT_W_S;
                            decoded_inst.is_fp_rd <= 1'b0;   // rd is integer register
                            decoded_inst.rs2_en <= 1'b0;     // Single operand
                        end
                        FUNC5_FCVT_S: begin
                            decoded_inst.exec_unit <= FP_ALU_UNIT;
                            decoded_inst.fp_alu_op <= FP_CVT_S_W;
                            decoded_inst.is_fp_rs1 <= 1'b0;  // rs1 is integer register
                            decoded_inst.rs2_en <= 1'b0;     // Single operand
                        end
                        default: begin
                            decoded_inst.exec_unit <= FP_ALU_UNIT;
                            decoded_inst.fp_alu_op <= FP_ADD;
                        end
                    endcase
                end
                
                OP_FMADD: begin
                    // Fused multiply-add operations
                    decoded_inst.exec_unit <= FP_MUL_UNIT;
                    decoded_inst.rs1_en <= 1'b1;
                    decoded_inst.rs2_en <= 1'b1;
                    decoded_inst.rs3_en <= 1'b1;
                    decoded_inst.rd_en <= 1'b1;
                    decoded_inst.is_fp_rs1 <= 1'b1;
                    decoded_inst.is_fp_rs2 <= 1'b1;
                    decoded_inst.is_fp_rs3 <= 1'b1;
                    decoded_inst.is_fp_rd <= 1'b1;
                    decoded_inst.fp_alu_op <= FP_MADD;
                end
                
                OP_FMSUB: begin
                    decoded_inst.exec_unit <= FP_MUL_UNIT;
                    decoded_inst.rs1_en <= 1'b1;
                    decoded_inst.rs2_en <= 1'b1;
                    decoded_inst.rs3_en <= 1'b1;
                    decoded_inst.rd_en <= 1'b1;
                    decoded_inst.is_fp_rs1 <= 1'b1;
                    decoded_inst.is_fp_rs2 <= 1'b1;
                    decoded_inst.is_fp_rs3 <= 1'b1;
                    decoded_inst.is_fp_rd <= 1'b1;
                    decoded_inst.fp_alu_op <= FP_MSUB;
                end
                
                OP_FNMSUB: begin
                    decoded_inst.exec_unit <= FP_MUL_UNIT;
                    decoded_inst.rs1_en <= 1'b1;
                    decoded_inst.rs2_en <= 1'b1;
                    decoded_inst.rs3_en <= 1'b1;
                    decoded_inst.rd_en <= 1'b1;
                    decoded_inst.is_fp_rs1 <= 1'b1;
                    decoded_inst.is_fp_rs2 <= 1'b1;
                    decoded_inst.is_fp_rs3 <= 1'b1;
                    decoded_inst.is_fp_rd <= 1'b1;
                    decoded_inst.fp_alu_op <= FP_NMSUB;
                end
                
                OP_FNMADD: begin
                    decoded_inst.exec_unit <= FP_MUL_UNIT;
                    decoded_inst.rs1_en <= 1'b1;
                    decoded_inst.rs2_en <= 1'b1;
                    decoded_inst.rs3_en <= 1'b1;
                    decoded_inst.rd_en <= 1'b1;
                    decoded_inst.is_fp_rs1 <= 1'b1;
                    decoded_inst.is_fp_rs2 <= 1'b1;
                    decoded_inst.is_fp_rs3 <= 1'b1;
                    decoded_inst.is_fp_rd <= 1'b1;
                    decoded_inst.fp_alu_op <= FP_NMADD;
                end
                
                default: begin
                    // Invalid instruction
                    decoded_inst.valid <= 1'b0;
                end
            endcase
        end else begin
            decoded_inst.valid <= 1'b0;
        end
    end
end

endmodule
