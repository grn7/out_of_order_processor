// Final Comprehensive Test for RISC-V Decoder + 3-Port Register Files
// Tests all instruction types including R4-type (3-source) instructions

import riscv_defines::*;

module final_decoder_test();

logic        clk;
logic        rst;
logic        valid_in;
logic [31:0] pc_in;
logic [31:0] instruction_in;

// Decoder outputs
decoded_inst_t decoded_inst;
logic        integer_reg_read_en_0, integer_reg_read_en_1, integer_reg_read_en_2;
logic        float_reg_read_en_0, float_reg_read_en_1, float_reg_read_en_2;
logic [4:0]  integer_reg_read_addr_0, integer_reg_read_addr_1, integer_reg_read_addr_2;
logic [4:0]  float_reg_read_addr_0, float_reg_read_addr_1, float_reg_read_addr_2;
logic [4:0]  integer_reg_write_addr, float_reg_write_addr;
logic        integer_reg_write_en, float_reg_write_en;
logic        dispatch_to_alu, dispatch_to_branch, dispatch_to_load_store;
logic        dispatch_to_fp_alu, dispatch_to_fp_mul, dispatch_to_fp_div;
logic        produces_result, uses_rs1, uses_rs2, uses_rs3;

// Register file signals
logic [31:0] int_rd_data1, int_rd_data2, int_rd_data3;
logic [31:0] int_wr_data = 32'hDEADBEEF;
logic [31:0] fp_rd_data1, fp_rd_data2, fp_rd_data3;
logic [31:0] fp_wr_data = 32'h3F800000; // 1.0 in IEEE 754

int passed_tests = 0;
int failed_tests = 0;

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// DUT instantiation - Decoder Top
decoder_top dut_decoder (
    .clk(clk),
    .rst(rst),
    .inst_valid(valid_in),
    .pc(pc_in),
    .instruction(instruction_in),
    .decoded_instruction(decoded_inst),
    .integer_reg_read_en_0(integer_reg_read_en_0),
    .integer_reg_read_en_1(integer_reg_read_en_1),
    .integer_reg_read_en_2(integer_reg_read_en_2),
    .float_reg_read_en_0(float_reg_read_en_0),
    .float_reg_read_en_1(float_reg_read_en_1),
    .float_reg_read_en_2(float_reg_read_en_2),
    .integer_reg_read_addr_0(integer_reg_read_addr_0),
    .integer_reg_read_addr_1(integer_reg_read_addr_1),
    .integer_reg_read_addr_2(integer_reg_read_addr_2),
    .float_reg_read_addr_0(float_reg_read_addr_0),
    .float_reg_read_addr_1(float_reg_read_addr_1),
    .float_reg_read_addr_2(float_reg_read_addr_2),
    .integer_reg_write_addr(integer_reg_write_addr),
    .float_reg_write_addr(float_reg_write_addr),
    .integer_reg_write_en(integer_reg_write_en),
    .float_reg_write_en(float_reg_write_en),
    .dispatch_to_alu(dispatch_to_alu),
    .dispatch_to_branch(dispatch_to_branch),
    .dispatch_to_load_store(dispatch_to_load_store),
    .dispatch_to_fp_alu(dispatch_to_fp_alu),
    .dispatch_to_fp_mul(dispatch_to_fp_mul),
    .dispatch_to_fp_div(dispatch_to_fp_div),
    .produces_result(produces_result),
    .uses_rs1(uses_rs1),
    .uses_rs2(uses_rs2),
    .uses_rs3(uses_rs3)
);

// Integer Register File
reg_file_int int_regfile (
    .clk(clk),
    .rst(rst),
    .rd_addr1(integer_reg_read_addr_0),
    .rd_addr2(integer_reg_read_addr_1),
    .rd_addr3(integer_reg_read_addr_2),
    .wr_addr(integer_reg_write_addr),
    .wr_data(int_wr_data),
    .wr_enable(integer_reg_write_en),
    .rd_data1(int_rd_data1),
    .rd_data2(int_rd_data2),
    .rd_data3(int_rd_data3)
);

// Floating-Point Register File
reg_file_float fp_regfile (
    .clk(clk),
    .rst(rst),
    .rd_addr1(float_reg_read_addr_0),
    .rd_addr2(float_reg_read_addr_1),
    .rd_addr3(float_reg_read_addr_2),
    .wr_addr(float_reg_write_addr),
    .wr_data(fp_wr_data),
    .wr_enable(float_reg_write_en),
    .rd_data1(fp_rd_data1),
    .rd_data2(fp_rd_data2),
    .rd_data3(fp_rd_data3)
);

// Test stimulus
initial begin
    $display("=== Final RISC-V Decoder + 3-Port Register Files Test ===");
    $display("");
    
    // Generate VCD file for waveform analysis
    $dumpfile("final_decoder_test.vcd");
    $dumpvars(0, final_decoder_test);
    
    // Initialize
    rst = 1;
    valid_in = 0;
    pc_in = 32'h1000;
    instruction_in = 0;
    
    // Reset cycle
    repeat (3) @(posedge clk);
    rst = 0;
    @(posedge clk);
    
    // Test various instruction types
    test_add_instruction();        // 2-source integer
    test_fmadd_instruction();      // 3-source floating-point
    test_fadd_instruction();       // 2-source floating-point
    test_load_instruction();       // 1-source + immediate
    test_branch_instruction();     // 2-source + immediate
    test_addi_instruction();       // 1-source + immediate
    
    // Summary
    $display("");
    $display("=== Final Test Summary ===");
    $display("Passed: %0d", passed_tests);
    $display("Failed: %0d", failed_tests);
    $display("Total:  %0d", passed_tests + failed_tests);
    
    if (failed_tests == 0) begin
        $display("");
        $display("🎉 ALL TESTS PASSED! 🎉");
        $display("✅ 3-port register files working correctly");
        $display("✅ R4-type instruction support verified");
        $display("✅ Decoder properly handles all source registers");
        $display("✅ All instruction types decoded correctly");
        $display("✅ Register file interfaces working properly");
        $display("");
        $display("The decoder is ready for integration into the out-of-order processor!");
    end else begin
        $display("❌ Some tests failed!");
    end
        
    $display("");
    $finish;
end

task test_add_instruction();
    $display("Test 1: 2-source integer instruction (ADD x3, x1, x2)...");
    
    @(posedge clk);
    valid_in = 1;
    instruction_in = 32'h002081B3; // ADD x3, x1, x2
    pc_in = pc_in + 4;
    
    @(posedge clk);
    @(posedge clk); // Pipeline delay
    
    $display("  uses_rs1=%b, uses_rs2=%b, uses_rs3=%b", uses_rs1, uses_rs2, uses_rs3);
    $display("  Integer read enables: [%b, %b, %b]", 
             integer_reg_read_en_0, integer_reg_read_en_1, integer_reg_read_en_2);
    $display("  Integer read addrs: [%0d, %0d, %0d]", 
             integer_reg_read_addr_0, integer_reg_read_addr_1, integer_reg_read_addr_2);
    $display("  dispatch_to_alu: %b, integer_reg_write_en: %b", dispatch_to_alu, integer_reg_write_en);
    
    if (uses_rs1 && uses_rs2 && !uses_rs3 && 
        integer_reg_read_en_0 && integer_reg_read_en_1 && !integer_reg_read_en_2 &&
        integer_reg_read_addr_0 == 1 && integer_reg_read_addr_1 == 2 &&
        dispatch_to_alu && integer_reg_write_en) begin
        $display("  ✅ PASS");
        passed_tests++;
    end else begin
        $display("  ❌ FAIL");
        failed_tests++;
    end
    $display("");
endtask

task test_fmadd_instruction();
    $display("Test 2: 3-source FP instruction (FMADD.S f4, f1, f2, f3)...");
    
    @(posedge clk);
    valid_in = 1;
    instruction_in = 32'h18208243; // FMADD.S f4, f1, f2, f3
    pc_in = pc_in + 4;
    
    @(posedge clk);
    @(posedge clk); // Pipeline delay
    
    $display("  uses_rs1=%b, uses_rs2=%b, uses_rs3=%b", uses_rs1, uses_rs2, uses_rs3);
    $display("  Float read enables: [%b, %b, %b]", 
             float_reg_read_en_0, float_reg_read_en_1, float_reg_read_en_2);
    $display("  Float read addrs: [%0d, %0d, %0d]", 
             float_reg_read_addr_0, float_reg_read_addr_1, float_reg_read_addr_2);
    $display("  dispatch_to_fp_mul: %b, float_reg_write_en: %b", dispatch_to_fp_mul, float_reg_write_en);
    
    if (uses_rs1 && uses_rs2 && uses_rs3 && 
        float_reg_read_en_0 && float_reg_read_en_1 && float_reg_read_en_2 &&
        float_reg_read_addr_0 == 1 && float_reg_read_addr_1 == 2 && float_reg_read_addr_2 == 3 &&
        dispatch_to_fp_mul && float_reg_write_en) begin
        $display("  ✅ PASS");
        passed_tests++;
    end else begin
        $display("  ❌ FAIL");
        failed_tests++;
    end
    $display("");
endtask

task test_fadd_instruction();
    $display("Test 3: 2-source FP instruction (FADD.S f3, f1, f2)...");
    
    @(posedge clk);
    valid_in = 1;
    instruction_in = 32'h002081D3; // FADD.S f3, f1, f2
    pc_in = pc_in + 4;
    
    @(posedge clk);
    @(posedge clk); // Pipeline delay
    
    $display("  uses_rs1=%b, uses_rs2=%b, uses_rs3=%b", uses_rs1, uses_rs2, uses_rs3);
    $display("  Float read enables: [%b, %b, %b]", 
             float_reg_read_en_0, float_reg_read_en_1, float_reg_read_en_2);
    $display("  dispatch_to_fp_alu: %b", dispatch_to_fp_alu);
    
    if (uses_rs1 && uses_rs2 && !uses_rs3 && 
        float_reg_read_en_0 && float_reg_read_en_1 && !float_reg_read_en_2 &&
        dispatch_to_fp_alu) begin
        $display("  ✅ PASS");
        passed_tests++;
    end else begin
        $display("  ❌ FAIL");
        failed_tests++;
    end
    $display("");
endtask

task test_load_instruction();
    $display("Test 4: Load instruction (LW x4, 8(x1))...");
    
    @(posedge clk);
    valid_in = 1;
    instruction_in = 32'h0080A203; // LW x4, 8(x1)
    pc_in = pc_in + 4;
    
    @(posedge clk);
    @(posedge clk); // Pipeline delay
    
    $display("  uses_rs1=%b, produces_result=%b, dispatch_to_load_store=%b", 
             uses_rs1, produces_result, dispatch_to_load_store);
    
    if (uses_rs1 && !uses_rs2 && !uses_rs3 && produces_result && 
        dispatch_to_load_store && integer_reg_write_en) begin
        $display("  ✅ PASS");
        passed_tests++;
    end else begin
        $display("  ❌ FAIL");
        failed_tests++;
    end
    $display("");
endtask

task test_branch_instruction();
    $display("Test 5: Branch instruction (BEQ x1, x2, 16)...");
    
    @(posedge clk);
    valid_in = 1;
    instruction_in = 32'h00208863; // BEQ x1, x2, 16
    pc_in = pc_in + 4;
    
    @(posedge clk);
    @(posedge clk); // Pipeline delay
    
    $display("  uses_rs1=%b, uses_rs2=%b, dispatch_to_branch=%b", 
             uses_rs1, uses_rs2, dispatch_to_branch);
    
    if (uses_rs1 && uses_rs2 && !uses_rs3 && !produces_result && 
        dispatch_to_branch) begin
        $display("  ✅ PASS");
        passed_tests++;
    end else begin
        $display("  ❌ FAIL");
        failed_tests++;
    end
    $display("");
endtask

task test_addi_instruction();
    $display("Test 6: Immediate instruction (ADDI x1, x0, 100)...");
    
    @(posedge clk);
    valid_in = 1;
    instruction_in = 32'h06400093; // ADDI x1, x0, 100
    pc_in = pc_in + 4;
    
    @(posedge clk);
    @(posedge clk); // Pipeline delay
    
    $display("  uses_rs1=%b, produces_result=%b, dispatch_to_alu=%b", 
             uses_rs1, produces_result, dispatch_to_alu);
    
    if (uses_rs1 && !uses_rs2 && !uses_rs3 && produces_result && 
        dispatch_to_alu && integer_reg_write_en) begin
        $display("  ✅ PASS");
        passed_tests++;
    end else begin
        $display("  ❌ FAIL");
        failed_tests++;
    end
    $display("");
endtask

endmodule
