// ============================================================
// RV32I Single-Cycle Core
// Wires together the instruction memory, decoder, register
// file, ALU, and data memory into a working single-cycle
// datapath covering the RV32I base integer instruction set:
// R-type, I-type ALU ops, loads, stores, branches, JAL, JALR,
// LUI, and AUIPC.
//
// Single-cycle by design (not pipelined) — this is the
// integration/proof-of-correctness step; a 5-stage pipelined
// version with hazard handling is a natural, larger follow-on
// project built on top of these same verified sub-blocks.
// ============================================================
module riscv_core #(
    parameter IMEM_INIT_FILE = "",
    parameter IMEM_WORDS     = 64,
    parameter DMEM_BYTES     = 256
)(
    input  wire clk,
    input  wire rst_n
);

    // ---------------- Program Counter ----------------
    reg  [31:0] pc;
    wire [31:0] pc_plus4 = pc + 32'd4;
    wire [31:0] pc_next;

    // ---------------- Instruction fetch ----------------
    wire [31:0] instr;
    riscv_imem #(.DEPTH_WORDS(IMEM_WORDS), .MEM_INIT_FILE(IMEM_INIT_FILE)) u_imem (
        .addr(pc), .instr(instr)
    );

    // ---------------- Decode ----------------
    wire [6:0] opcode;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [31:0] imm;
    wire reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch, jump, invalid;

    riscv_decoder u_decoder (
        .instr(instr),
        .opcode(opcode), .rd(rd), .funct3(funct3), .rs1(rs1), .rs2(rs2), .funct7(funct7), .imm(imm),
        .reg_write(reg_write), .alu_src(alu_src), .mem_read(mem_read), .mem_write(mem_write),
        .mem_to_reg(mem_to_reg), .branch(branch), .jump(jump), .invalid(invalid)
    );

    // ---------------- Register file ----------------
    wire [31:0] rs1_data, rs2_data;
    reg  [31:0] rd_data;

    riscv_regfile u_regfile (
        .clk(clk), .rst_n(rst_n),
        .rs1_addr(rs1), .rs1_data(rs1_data),
        .rs2_addr(rs2), .rs2_data(rs2_data),
        .rd_addr(rd), .rd_data(rd_data), .reg_write(reg_write)
    );

    // ---------------- ALU control ----------------
    localparam OP_RTYPE  = 7'b0110011;
    localparam OP_ITYPE  = 7'b0010011;
    localparam OP_BRANCH = 7'b1100011;

    reg [3:0] alu_op;
    always @(*) begin
        case (opcode)
            OP_RTYPE: begin
                case (funct3)
                    3'b000: alu_op = funct7[5] ? 4'b0001 /*SUB*/ : 4'b0000 /*ADD*/;
                    3'b001: alu_op = 4'b0101; // SLL
                    3'b010: alu_op = 4'b1000; // SLT
                    3'b011: alu_op = 4'b1001; // SLTU
                    3'b100: alu_op = 4'b0100; // XOR
                    3'b101: alu_op = funct7[5] ? 4'b0111 /*SRA*/ : 4'b0110 /*SRL*/;
                    3'b110: alu_op = 4'b0011; // OR
                    3'b111: alu_op = 4'b0010; // AND
                    default: alu_op = 4'b0000;
                endcase
            end
            OP_ITYPE: begin
                case (funct3)
                    3'b000: alu_op = 4'b0000; // ADDI
                    3'b001: alu_op = 4'b0101; // SLLI
                    3'b010: alu_op = 4'b1000; // SLTI
                    3'b011: alu_op = 4'b1001; // SLTIU
                    3'b100: alu_op = 4'b0100; // XORI
                    3'b101: alu_op = funct7[5] ? 4'b0111 /*SRAI*/ : 4'b0110 /*SRLI*/;
                    3'b110: alu_op = 4'b0011; // ORI
                    3'b111: alu_op = 4'b0010; // ANDI
                    default: alu_op = 4'b0000;
                endcase
            end
            default: alu_op = 4'b0000; // ADD: covers loads, stores, JALR, AUIPC address calc
        endcase
    end

    wire [31:0] alu_b = alu_src ? imm : rs2_data;
    wire [31:0] alu_result;
    wire        alu_zero;

    riscv_alu u_alu (
        .a(rs1_data), .b(alu_b), .alu_op(alu_op),
        .result(alu_result), .zero(alu_zero)
    );

    // ---------------- Branch decision ----------------
    reg branch_taken;
    always @(*) begin
        case (funct3)
            3'b000: branch_taken = branch && (rs1_data == rs2_data);                         // BEQ
            3'b001: branch_taken = branch && (rs1_data != rs2_data);                         // BNE
            3'b100: branch_taken = branch && ($signed(rs1_data) < $signed(rs2_data));        // BLT
            3'b101: branch_taken = branch && ($signed(rs1_data) >= $signed(rs2_data));       // BGE
            3'b110: branch_taken = branch && (rs1_data < rs2_data);                          // BLTU
            3'b111: branch_taken = branch && (rs1_data >= rs2_data);                         // BGEU
            default: branch_taken = 1'b0;
        endcase
    end

    // ---------------- Next PC ----------------
    localparam OP_JALR = 7'b1100111;
    wire [31:0] jalr_target = (rs1_data + imm) & 32'hFFFF_FFFE;

    assign pc_next = (opcode == OP_JALR) ? jalr_target :
                      (jump || branch_taken)            ? (pc + imm) :
                                                            pc_plus4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) pc <= 32'b0;
        else        pc <= pc_next;
    end

    // ---------------- Data memory ----------------
    wire [31:0] dmem_rdata;
    riscv_dmem #(.DEPTH_BYTES(DMEM_BYTES)) u_dmem (
        .clk(clk), .addr(alu_result), .wdata(rs2_data),
        .mem_write(mem_write), .mem_read(mem_read), .funct3(funct3),
        .rdata(dmem_rdata)
    );

    // ---------------- Writeback mux ----------------
    localparam OP_LUI   = 7'b0110111;
    localparam OP_AUIPC = 7'b0010111;

    always @(*) begin
        if (mem_to_reg)            rd_data = dmem_rdata;
        else if (jump)             rd_data = pc_plus4;          // JAL/JALR link address
        else if (opcode == OP_LUI) rd_data = imm;
        else if (opcode == OP_AUIPC) rd_data = pc + imm;
        else                       rd_data = alu_result;
    end

endmodule
