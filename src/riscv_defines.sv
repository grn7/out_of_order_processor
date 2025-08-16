// RISC-V 32-bit I+M+F ISA Definitions Package
// Defines all instruction formats, opcodes, and field definitions

package riscv_defines;

    // Instruction formats
    typedef enum logic [2:0] {
        R_TYPE = 3'b000,
        I_TYPE = 3'b001,
        S_TYPE = 3'b010,
        B_TYPE = 3'b011,
        U_TYPE = 3'b100,
        J_TYPE = 3'b101,
        UNKNOWN_TYPE = 3'b111
    } inst_format_e;

    // Primary opcodes (bits [6:0])
    typedef enum logic [6:0] {
        OP_LOAD     = 7'b0000011,  // I-type: lw, lb, lh, lbu, lhu
        OP_LOAD_FP  = 7'b0000111,  // I-type: flw
        OP_IMM      = 7'b0010011,  // I-type: addi, slti, sltiu, xori, ori, andi, slli, srli, srai
        OP_AUIPC    = 7'b0010111,  // U-type: auipc
        OP_STORE    = 7'b0100011,  // S-type: sw, sb, sh
        OP_STORE_FP = 7'b0100111,  // S-type: fsw
        OP_REG      = 7'b0110011,  // R-type: add, sub, sll, slt, sltu, xor, srl, sra, or, and, mul, div
        OP_LUI      = 7'b0110111,  // U-type: lui
        OP_BRANCH   = 7'b1100011,  // B-type: beq, bne, blt, bge, bltu, bgeu
        OP_JALR     = 7'b1100111,  // I-type: jalr
        OP_JAL      = 7'b1101111,  // J-type: jal
        OP_SYSTEM   = 7'b1110011,  // I-type: ecall, ebreak, csrr*
        OP_FMADD    = 7'b1000011,  // R4-type: fmadd.s
        OP_FMSUB    = 7'b1000111,  // R4-type: fmsub.s
        OP_FNMSUB   = 7'b1001011,  // R4-type: fnmsub.s
        OP_FNMADD   = 7'b1001111,  // R4-type: fnmadd.s
        OP_FP       = 7'b1010011   // R-type: fadd.s, fsub.s, fmul.s, fdiv.s, fsqrt.s, fmv.w.x, etc.
    } opcode_e;

    // Function3 codes for different instruction types
    localparam FUNC3_ADDI   = 3'b000;
    localparam FUNC3_SLTI   = 3'b010;
    localparam FUNC3_SLTIU  = 3'b011;
    localparam FUNC3_XORI   = 3'b100;
    localparam FUNC3_ORI    = 3'b110;
    localparam FUNC3_ANDI   = 3'b111;
    localparam FUNC3_SLLI   = 3'b001;
    localparam FUNC3_SRLI_SRAI = 3'b101;
    localparam FUNC3_ADD_SUB = 3'b000;
    localparam FUNC3_SLL    = 3'b001;
    localparam FUNC3_SLT    = 3'b010;
    localparam FUNC3_SLTU   = 3'b011;
    localparam FUNC3_XOR    = 3'b100;
    localparam FUNC3_SRL_SRA = 3'b101;
    localparam FUNC3_OR     = 3'b110;
    localparam FUNC3_AND    = 3'b111;
    localparam FUNC3_LW     = 3'b010;
    localparam FUNC3_SW     = 3'b010;
    localparam FUNC3_BEQ    = 3'b000;
    localparam FUNC3_BNE    = 3'b001;
    localparam FUNC3_BLT    = 3'b100;
    localparam FUNC3_BGE    = 3'b101;
    localparam FUNC3_BLTU   = 3'b110;
    localparam FUNC3_BGEU   = 3'b111;
    localparam FUNC3_JALR   = 3'b000;

    // Function7 codes for R-type instructions
    localparam FUNC7_ADD    = 7'b0000000;
    localparam FUNC7_SUB    = 7'b0100000;
    localparam FUNC7_SLL    = 7'b0000000;
    localparam FUNC7_SLT    = 7'b0000000;
    localparam FUNC7_SLTU   = 7'b0000000;
    localparam FUNC7_XOR    = 7'b0000000;
    localparam FUNC7_SRL    = 7'b0000000;
    localparam FUNC7_SRA    = 7'b0100000;
    localparam FUNC7_OR     = 7'b0000000;
    localparam FUNC7_AND    = 7'b0000000;
    localparam FUNC7_MUL    = 7'b0000001;  // M extension
    localparam FUNC7_DIV    = 7'b0000001;   // M extension

    // Floating-point function codes
    typedef enum logic [4:0] {
        FUNC5_FADD   = 5'b00000,
        FUNC5_FSUB   = 5'b00001,
        FUNC5_FMUL   = 5'b00010,
        FUNC5_FDIV   = 5'b00011,
        FUNC5_FSQRT  = 5'b01011,
        FUNC5_FSGNJ  = 5'b00100,
        FUNC5_FMIN_FMAX = 5'b00101,
        FUNC5_FCVT_W = 5'b11000,
        FUNC5_FMV_X_W = 5'b11100,
        FUNC5_FCMP   = 5'b10100,
        FUNC5_FCVT_S = 5'b11010,
        FUNC5_FMV_W_X = 5'b11110
    } func5_fp_e;

    // Instruction execution units
    typedef enum logic [2:0] {
        ALU_UNIT   = 3'b000,
        BRANCH_UNIT = 3'b001,
        LOAD_UNIT  = 3'b010,
        STORE_UNIT = 3'b011,
        FP_ALU_UNIT = 3'b100,
        FP_MUL_UNIT = 3'b101,
        FP_DIV_UNIT = 3'b110,
        UNKNOWN_UNIT = 3'b111
    } exec_unit_e;

    // ALU operation types
    typedef enum logic [4:0] {
        ALU_ADD  = 5'b00000,
        ALU_SUB  = 5'b00001,
        ALU_AND  = 5'b00010,
        ALU_OR   = 5'b00011,
        ALU_XOR  = 5'b00100,
        ALU_SLT  = 5'b00101,
        ALU_SLTU = 5'b00110,
        ALU_SLL  = 5'b00111,
        ALU_SRL  = 5'b01000,
        ALU_SRA  = 5'b01001,
        ALU_MUL  = 5'b01010,
        ALU_DIV  = 5'b01011,
        ALU_COPY_A = 5'b01100,  // For mv pseudo-instruction
        ALU_COPY_B = 5'b01101   // For li pseudo-instruction
    } alu_op_e;

    // Floating-point ALU operations
    typedef enum logic [4:0] {
        FP_ADD    = 5'b00000,
        FP_SUB    = 5'b00001,
        FP_MUL    = 5'b00010,
        FP_DIV    = 5'b00011,
        FP_SQRT   = 5'b00100,
        FP_SGNJ   = 5'b00101,
        FP_SGNJN  = 5'b00110,
        FP_SGNJX  = 5'b00111,
        FP_MIN    = 5'b01000,
        FP_MAX    = 5'b01001,
        FP_EQ     = 5'b01010,
        FP_LT     = 5'b01011,
        FP_LE     = 5'b01100,
        FP_CVT_W_S = 5'b01101,
        FP_CVT_S_W = 5'b01110,
        FP_MV_X_W = 5'b01111,
        FP_MV_W_X = 5'b10000,
        FP_MADD   = 5'b10001,
        FP_MSUB   = 5'b10010,
        FP_NMSUB  = 5'b10011,
        FP_NMADD  = 5'b10100
    } fp_alu_op_e;

    // Branch operation types
    typedef enum logic [2:0] {
        BRANCH_EQ  = 3'b000,
        BRANCH_NE  = 3'b001,
        BRANCH_LT  = 3'b100,
        BRANCH_GE  = 3'b101,
        BRANCH_LTU = 3'b110,
        BRANCH_GEU = 3'b111
    } branch_op_e;

    // Decoded instruction structure
    typedef struct packed {
        logic               valid;
        logic [31:0]        pc;
        logic [31:0]        instruction;
        inst_format_e       format;
        opcode_e            opcode;
        exec_unit_e         exec_unit;
        
        // Register addresses
        logic [4:0]         rs1_addr;
        logic [4:0]         rs2_addr;
        logic [4:0]         rs3_addr;    // For R4-type FP instructions
        logic [4:0]         rd_addr;
        
        // Control signals
        logic               rs1_en;      // rs1 read enable
        logic               rs2_en;      // rs2 read enable
        logic               rs3_en;      // rs3 read enable (FP)
        logic               rd_en;       // rd write enable
        logic               is_fp_rs1;   // rs1 is floating-point register
        logic               is_fp_rs2;   // rs2 is floating-point register
        logic               is_fp_rs3;   // rs3 is floating-point register
        logic               is_fp_rd;    // rd is floating-point register
        
        // Immediates
        logic [31:0]        imm;
        
        // Operation type
        alu_op_e            alu_op;
        fp_alu_op_e         fp_alu_op;
        branch_op_e         branch_op;
        
        // Memory operation signals
        logic               is_load;
        logic               is_store;
        logic               is_branch;
        logic               is_jump;
        
        // Function codes
        logic [2:0]         func3;
        logic [6:0]         func7;
        
    } decoded_inst_t;

endpackage
