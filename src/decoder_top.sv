// Top-level RISC-V Instruction Decoder Module (Fixed for Icarus Verilog)
// Integrates all decoder components for out-of-order processor

import riscv_defines::*;

module decoder_top (
    input  logic        clk,
    input  logic        rst,
    
    // Input interface
    input  logic        inst_valid,
    input  logic [31:0] pc,
    input  logic [31:0] instruction,
    
    // Output interface
    output decoded_inst_t decoded_instruction,
    
    // Control signals for out-of-order execution (individual signals)
    output logic        integer_reg_read_en_0,    // Enable for integer read port 0
    output logic        integer_reg_read_en_1,    // Enable for integer read port 1
    output logic        integer_reg_read_en_2,    // Enable for integer read port 2
    output logic        float_reg_read_en_0,      // Enable for float read port 0
    output logic        float_reg_read_en_1,      // Enable for float read port 1
    output logic        float_reg_read_en_2,      // Enable for float read port 2
    output logic [4:0]  integer_reg_read_addr_0,  // Integer register read address 0
    output logic [4:0]  integer_reg_read_addr_1,  // Integer register read address 1
    output logic [4:0]  integer_reg_read_addr_2,  // Integer register read address 2
    output logic [4:0]  float_reg_read_addr_0,    // Float register read address 0
    output logic [4:0]  float_reg_read_addr_1,    // Float register read address 1
    output logic [4:0]  float_reg_read_addr_2,    // Float register read address 2
    output logic [4:0]  integer_reg_write_addr,   // Integer register write address
    output logic [4:0]  float_reg_write_addr,     // Float register write address
    output logic        integer_reg_write_en,     // Integer register write enable
    output logic        float_reg_write_en,       // Float register write enable
    
    // Execution unit dispatch signals
    output logic        dispatch_to_alu,
    output logic        dispatch_to_branch,
    output logic        dispatch_to_load_store,
    output logic        dispatch_to_fp_alu,
    output logic        dispatch_to_fp_mul,
    output logic        dispatch_to_fp_div,
    
    // Additional signals for OoO processor
    output logic        produces_result,          // Instruction produces a result
    output logic        uses_rs1,                 // Instruction uses rs1
    output logic        uses_rs2,                 // Instruction uses rs2
    output logic        uses_rs3                  // Instruction uses rs3 (FP only)
);

// Instantiate the main decoder
instruction_decoder main_decoder (
    .clk(clk),
    .rst(rst),
    .valid_in(inst_valid),
    .pc_in(pc),
    .instruction_in(instruction),
    .decoded_inst(decoded_instruction)
);

// Generate register file interface signals
always_comb begin
    // Initialize all outputs
    integer_reg_read_en_0 = 1'b0;
    integer_reg_read_en_1 = 1'b0;
    integer_reg_read_en_2 = 1'b0;
    float_reg_read_en_0 = 1'b0;
    float_reg_read_en_1 = 1'b0;
    float_reg_read_en_2 = 1'b0;
    integer_reg_read_addr_0 = 5'b0;
    integer_reg_read_addr_1 = 5'b0;
    integer_reg_read_addr_2 = 5'b0;
    float_reg_read_addr_0 = 5'b0;
    float_reg_read_addr_1 = 5'b0;
    float_reg_read_addr_2 = 5'b0;
    integer_reg_write_addr = 5'b0;
    float_reg_write_addr = 5'b0;
    integer_reg_write_en = 1'b0;
    float_reg_write_en = 1'b0;
    
    // Default dispatch signals
    dispatch_to_alu = 1'b0;
    dispatch_to_branch = 1'b0;
    dispatch_to_load_store = 1'b0;
    dispatch_to_fp_alu = 1'b0;
    dispatch_to_fp_mul = 1'b0;
    dispatch_to_fp_div = 1'b0;
    
    // Default dependency signals
    produces_result = 1'b0;
    uses_rs1 = 1'b0;
    uses_rs2 = 1'b0;
    uses_rs3 = 1'b0;
    
    if (decoded_instruction.valid) begin
        // Set dependency tracking signals
        produces_result = decoded_instruction.rd_en;
        uses_rs1 = decoded_instruction.rs1_en;
        uses_rs2 = decoded_instruction.rs2_en;
        uses_rs3 = decoded_instruction.rs3_en;
        
        // Configure rs1 (source 1) - Port 0
        if (decoded_instruction.rs1_en) begin
            if (decoded_instruction.is_fp_rs1) begin
                float_reg_read_en_0 = 1'b1;
                float_reg_read_addr_0 = decoded_instruction.rs1_addr;
            end else begin
                integer_reg_read_en_0 = 1'b1;
                integer_reg_read_addr_0 = decoded_instruction.rs1_addr;
            end
        end
        
        // Configure rs2 (source 2) - Port 1
        if (decoded_instruction.rs2_en) begin
            if (decoded_instruction.is_fp_rs2) begin
                float_reg_read_en_1 = 1'b1;
                float_reg_read_addr_1 = decoded_instruction.rs2_addr;
            end else begin
                integer_reg_read_en_1 = 1'b1;
                integer_reg_read_addr_1 = decoded_instruction.rs2_addr;
            end
        end
        
        // Configure rs3 (source 3) - Port 2
        if (decoded_instruction.rs3_en) begin
            if (decoded_instruction.is_fp_rs3) begin
                float_reg_read_en_2 = 1'b1;
                float_reg_read_addr_2 = decoded_instruction.rs3_addr;
            end else begin
                integer_reg_read_en_2 = 1'b1;
                integer_reg_read_addr_2 = decoded_instruction.rs3_addr;
            end
        end
        
        // Configure destination register
        if (decoded_instruction.rd_en) begin
            if (decoded_instruction.is_fp_rd) begin
                float_reg_write_en = 1'b1;
                float_reg_write_addr = decoded_instruction.rd_addr;
            end else begin
                integer_reg_write_en = 1'b1;
                integer_reg_write_addr = decoded_instruction.rd_addr;
            end
        end
        
        // Set execution unit dispatch signals
        case (decoded_instruction.exec_unit)
            ALU_UNIT: begin
                dispatch_to_alu = 1'b1;
            end
            BRANCH_UNIT: begin
                dispatch_to_branch = 1'b1;
            end
            LOAD_UNIT, STORE_UNIT: begin
                dispatch_to_load_store = 1'b1;
            end
            FP_ALU_UNIT: begin
                dispatch_to_fp_alu = 1'b1;
            end
            FP_MUL_UNIT: begin
                dispatch_to_fp_mul = 1'b1;
            end
            FP_DIV_UNIT: begin
                dispatch_to_fp_div = 1'b1;
            end
            default: begin
                // Unknown unit - no dispatch
            end
        endcase
    end
end

// Utility functions for instruction analysis (can be used by other modules)
function automatic logic is_memory_instruction(decoded_inst_t inst);
    return inst.is_load || inst.is_store;
endfunction

function automatic logic is_control_flow_instruction(decoded_inst_t inst);
    return inst.is_branch || inst.is_jump;
endfunction

function automatic logic is_floating_point_instruction(decoded_inst_t inst);
    return (inst.exec_unit == FP_ALU_UNIT) || 
           (inst.exec_unit == FP_MUL_UNIT) || 
           (inst.exec_unit == FP_DIV_UNIT);
endfunction

function automatic logic has_immediate(decoded_inst_t inst);
    return (inst.format == I_TYPE) || 
           (inst.format == S_TYPE) || 
           (inst.format == B_TYPE) || 
           (inst.format == U_TYPE) || 
           (inst.format == J_TYPE);
endfunction

function automatic logic [1:0] get_num_source_regs(decoded_inst_t inst);
    logic [1:0] count = 0;
    if (inst.rs1_en) count = count + 1;
    if (inst.rs2_en) count = count + 1;
    if (inst.rs3_en) count = count + 1;
    return count;
endfunction

endmodule
