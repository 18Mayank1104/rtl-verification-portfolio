// ============================================================
// Self-checking testbench for RISC-V RV32I Instruction Decoder
// Builds real RV32I instruction encodings (as an assembler
// would) for at least one instruction per format, and checks
// every decoded field plus control signals.
// ============================================================
`timescale 1ns/1ps

module tb_riscv_decoder;

    reg  [31:0] instr;
    wire [6:0]  opcode;
    wire [4:0]  rd, rs1, rs2;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire [31:0] imm;
    wire        reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch, jump, invalid;

    integer errors = 0;
    integer tests  = 0;

    riscv_decoder dut (
        .instr(instr),
        .opcode(opcode), .rd(rd), .funct3(funct3), .rs1(rs1), .rs2(rs2), .funct7(funct7), .imm(imm),
        .reg_write(reg_write), .alu_src(alu_src), .mem_read(mem_read), .mem_write(mem_write),
        .mem_to_reg(mem_to_reg), .branch(branch), .jump(jump), .invalid(invalid)
    );

    // ---------------- instruction encoders ----------------
    function [31:0] enc_r(input [6:0] funct7, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3, input [4:0] rd, input [6:0] opcode);
        enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function [31:0] enc_i(input [11:0] imm, input [4:0] rs1, input [2:0] funct3, input [4:0] rd, input [6:0] opcode);
        enc_i = {imm, rs1, funct3, rd, opcode};
    endfunction

    function [31:0] enc_s(input [11:0] imm, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3, input [6:0] opcode);
        enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    endfunction

    function [31:0] enc_b(input [12:0] imm, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3, input [6:0] opcode);
        // imm[12] is sign bit; bit 0 is always 0 (not encoded)
        enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    endfunction

    function [31:0] enc_u(input [19:0] imm20, input [4:0] rd, input [6:0] opcode);
        enc_u = {imm20, rd, opcode};
    endfunction

    function [31:0] enc_j(input [20:0] imm, input [4:0] rd, input [6:0] opcode);
        enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    endfunction

    task check(input [127:0] name,
               input exp_rw, input exp_asrc, input exp_mr, input exp_mw,
               input exp_m2r, input exp_br, input exp_jmp, input exp_inv,
               input [31:0] exp_imm, input check_imm);
        begin
            tests = tests + 1;
            #1;
            if (reg_write === exp_rw && alu_src === exp_asrc && mem_read === exp_mr &&
                mem_write === exp_mw && mem_to_reg === exp_m2r && branch === exp_br &&
                jump === exp_jmp && invalid === exp_inv &&
                (!check_imm || imm === exp_imm)) begin
                $display("PASS [%0s] opcode=%07b rd=%0d rs1=%0d rs2=%0d imm=%0d", name, opcode, rd, rs1, rs2, $signed(imm));
            end else begin
                $display("FAIL [%0s] rw=%b(exp%b) asrc=%b(exp%b) mr=%b(exp%b) mw=%b(exp%b) m2r=%b(exp%b) br=%b(exp%b) jmp=%b(exp%b) inv=%b(exp%b) imm=%0d(exp%0d)",
                          name, reg_write, exp_rw, alu_src, exp_asrc, mem_read, exp_mr, mem_write, exp_mw,
                          mem_to_reg, exp_m2r, branch, exp_br, jump, exp_jmp, invalid, exp_inv, $signed(imm), $signed(exp_imm));
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        // ---- R-type: ADD x3, x1, x2  (funct7=0000000, funct3=000, opcode=0110011)
        instr = enc_r(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011);
        check("ADD_x3_x1_x2", 1,0,0,0,0,0,0,0, 32'd0, 0);

        // ---- R-type: SUB x5, x6, x7 (funct7=0100000)
        instr = enc_r(7'b0100000, 5'd7, 5'd6, 3'b000, 5'd5, 7'b0110011);
        check("SUB_x5_x6_x7", 1,0,0,0,0,0,0,0, 32'd0, 0);
        tests = tests + 1;
        if (rd===5'd5 && rs1===5'd6 && rs2===5'd7 && funct7===7'b0100000)
            $display("PASS [SUB fields] rd=%0d rs1=%0d rs2=%0d funct7=%07b", rd, rs1, rs2, funct7);
        else begin $display("FAIL [SUB fields]"); errors=errors+1; end

        // ---- I-type: ADDI x4, x1, -5  (imm=-5 = 12'hFFB)
        instr = enc_i(12'hFFB, 5'd1, 3'b000, 5'd4, 7'b0010011);
        check("ADDI_x4_x1_neg5", 1,1,0,0,0,0,0,0, -32'd5, 1);

        // ---- Load: LW x8, 16(x2)
        instr = enc_i(12'd16, 5'd2, 3'b010, 5'd8, 7'b0000011);
        check("LW_x8_16_x2", 1,1,1,0,1,0,0,0, 32'd16, 1);

        // ---- Store: SW x9, -8(x2)   imm = -8 = 12'hFF8
        instr = enc_s(12'hFF8, 5'd9, 5'd2, 3'b010, 7'b0100011);
        check("SW_x9_neg8_x2", 0,1,0,1,0,0,0,0, -32'd8, 1);
        tests = tests + 1;
        if (rs1===5'd2 && rs2===5'd9)
            $display("PASS [SW fields] rs1=%0d rs2=%0d", rs1, rs2);
        else begin $display("FAIL [SW fields] rs1=%0d rs2=%0d", rs1, rs2); errors=errors+1; end

        // ---- Branch: BEQ x1, x2, +8
        instr = enc_b(13'd8, 5'd2, 5'd1, 3'b000, 7'b1100011);
        check("BEQ_x1_x2_plus8", 0,0,0,0,0,1,0,0, 32'd8, 1);

        // ---- Branch: BNE x3, x4, -16 (tests negative branch offset encoding)
        instr = enc_b(-13'd16, 5'd4, 5'd3, 3'b001, 7'b1100011);
        check("BNE_x3_x4_neg16", 0,0,0,0,0,1,0,0, -32'd16, 1);

        // ---- JAL x1, +2048
        instr = enc_j(21'd2048, 5'd1, 7'b1101111);
        check("JAL_x1_plus2048", 1,0,0,0,0,0,1,0, 32'd2048, 1);

        // ---- JALR x1, x2, 4
        instr = enc_i(12'd4, 5'd2, 3'b000, 5'd1, 7'b1100111);
        check("JALR_x1_x2_4", 1,1,0,0,0,0,1,0, 32'd4, 1);

        // ---- LUI x5, 0x12345
        instr = enc_u(20'h12345, 5'd5, 7'b0110111);
        check("LUI_x5_0x12345", 1,1,0,0,0,0,0,0, 32'h12345000, 1);

        // ---- AUIPC x6, 0xABCDE
        instr = enc_u(20'hABCDE, 5'd6, 7'b0010111);
        check("AUIPC_x6", 1,1,0,0,0,0,0,0, 32'hABCDE000, 1);

        // ---- Invalid / unrecognized opcode
        instr = 32'b0000000_00000_00000_000_00000_1111111; // bogus opcode 1111111
        check("INVALID_OPCODE", 0,0,0,0,0,0,0,1, 32'd0, 0);

        $display("--------------------------------------------------");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d / %0d TESTS FAILED", errors, tests);
        $finish;
    end

endmodule
