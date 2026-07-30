// ============================================================
// Self-checking testbench for the RV32I Single-Cycle Core
// Loads a hand-assembled test program (program.hex) that
// exercises R-type ALU ops, I-type ALU ops, loads, stores
// (word and byte), a taken branch, a jump, LUI, and AUIPC —
// then runs the core for a fixed number of cycles and checks
// the architectural state (registers + data memory) against
// what the program should have produced.
//
// See program.hex / the README for the assembly listing this
// hex was hand-encoded from.
// ============================================================
`timescale 1ns/1ps

module tb_riscv_core;

    reg clk = 0;
    reg rst_n;

    integer errors = 0;
    integer tests  = 0;

    always #5 clk = ~clk;

    riscv_core #(
        .IMEM_INIT_FILE("program.hex"),
        .IMEM_WORDS(64),
        .DMEM_BYTES(256)
    ) dut (
        .clk(clk), .rst_n(rst_n)
    );

    task check_reg(input [4:0] idx, input [31:0] exp, input [127:0] name);
        begin
            tests = tests + 1;
            if (dut.u_regfile.regs[idx] === exp)
                $display("PASS [%0s] x%0d = 0x%08h", name, idx, dut.u_regfile.regs[idx]);
            else begin
                $display("FAIL [%0s] x%0d = 0x%08h, expected 0x%08h", name, idx, dut.u_regfile.regs[idx], exp);
                errors = errors + 1;
            end
        end
    endtask

    task check_mem_byte(input [31:0] addr, input [7:0] exp, input [127:0] name);
        begin
            tests = tests + 1;
            if (dut.u_dmem.mem[addr] === exp)
                $display("PASS [%0s] mem[%0d] = 0x%02h", name, addr, dut.u_dmem.mem[addr]);
            else begin
                $display("FAIL [%0s] mem[%0d] = 0x%02h, expected 0x%02h", name, addr, dut.u_dmem.mem[addr], exp);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        rst_n = 0;
        repeat (3) @(negedge clk);
        rst_n = 1;

        // 24 instructions, single-cycle (1 instruction/cycle) -> run well
        // past that so every instruction (including the branch/jump
        // skips) has definitely retired before we check state.
        repeat (30) @(negedge clk);

        $display("==================== Register checks ====================");
        check_reg(1,  32'd5,          "ADDI_x1");
        check_reg(2,  32'd10,         "ADDI_x2");
        check_reg(3,  32'd15,         "ADD_x3");
        check_reg(4,  32'd5,          "SUB_x4");
        check_reg(5,  32'd15,         "LW_x5");
        check_reg(6,  32'd0,          "BRANCH_SKIPPED_x6_untouched");
        check_reg(7,  32'd7,          "BRANCH_TARGET_x7");
        check_reg(8,  32'd40,         "JAL_link_x8");
        check_reg(9,  32'd0,          "JUMP_SKIPPED_x9_untouched");
        check_reg(10, 32'd11,         "JUMP_TARGET_x10");
        check_reg(11, 32'd1,          "SLT_x11");
        check_reg(12, 32'd0,          "SLTU_x12");
        check_reg(13, 32'd5,          "AND_x13");
        check_reg(14, 32'd15,         "OR_x14");
        check_reg(15, 32'd10,         "XOR_x15");
        check_reg(16, 32'd160,        "SLL_x16");
        check_reg(17, 32'd5,          "SRL_x17");
        check_reg(18, 32'h1234_5000,  "LUI_x18");
        check_reg(19, 32'h0000_1050,  "AUIPC_x19");
        check_reg(20, 32'd15,         "LBU_x20");

        $display("==================== Memory checks ====================");
        check_mem_byte(0, 8'h0F, "SW_mem0_lsb");
        check_mem_byte(1, 8'h00, "SW_mem1");
        check_mem_byte(4, 8'h0F, "SB_mem4");

        $display("--------------------------------------------------");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d / %0d TESTS FAILED", errors, tests);
        $finish;
    end

endmodule
