// ============================================================
// RISC-V RV32I Instruction Decoder
// Decodes a 32-bit RV32I instruction word into its constituent
// fields (opcode, rd, funct3, rs1, rs2, funct7), a correctly
// sign-extended immediate per instruction format (I/S/B/U/J),
// and the standard Decode-stage control signals a 5-stage
// pipeline datapath needs.
// ============================================================
module riscv_decoder (
    input  wire [31:0] instr,

    // raw fields
    output wire [6:0]  opcode,
    output wire [4:0]  rd,
    output wire [2:0]  funct3,
    output wire [4:0]  rs1,
    output wire [4:0]  rs2,
    output wire [6:0]  funct7,
    output reg  [31:0] imm,

    // control signals
    output reg         reg_write,   // write result into rd
    output reg         alu_src,     // 0 = ALU operand B is rs2, 1 = immediate
    output reg         mem_read,    // load from data memory
    output reg         mem_write,   // store to data memory
    output reg         mem_to_reg,  // writeback comes from memory, not ALU
    output reg         branch,      // conditional branch instruction
    output reg         jump,        // unconditional jump (JAL/JALR)
    output reg         invalid      // unrecognized opcode
);

    // ---------------- RV32I opcode map ----------------
    localparam OP_RTYPE  = 7'b0110011; // ADD/SUB/AND/OR/XOR/SLT/SLL/SRL/SRA
    localparam OP_ITYPE  = 7'b0010011; // ADDI/SLTI/ANDI/ORI/XORI/SLLI/SRLI/SRAI
    localparam OP_LOAD   = 7'b0000011; // LB/LH/LW/LBU/LHU
    localparam OP_STORE  = 7'b0100011; // SB/SH/SW
    localparam OP_BRANCH = 7'b1100011; // BEQ/BNE/BLT/BGE/BLTU/BGEU
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    // ---------------- immediate generation ----------------
    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    wire [31:0] imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    wire [31:0] imm_u = {instr[31:12], 12'b0};
    wire [31:0] imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

    always @(*) begin
        case (opcode)
            OP_ITYPE, OP_LOAD, OP_JALR: imm = imm_i;
            OP_STORE:                  imm = imm_s;
            OP_BRANCH:                 imm = imm_b;
            OP_LUI, OP_AUIPC:          imm = imm_u;
            OP_JAL:                    imm = imm_j;
            default:                   imm = 32'b0;
        endcase
    end

    // ---------------- control signals ----------------
    always @(*) begin
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        invalid    = 1'b0;

        case (opcode)
            OP_RTYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
            end
            OP_ITYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
            end
            OP_LOAD: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
            end
            OP_STORE: begin
                alu_src   = 1'b1;
                mem_write = 1'b1;
            end
            OP_BRANCH: begin
                branch  = 1'b1;
                alu_src = 1'b0;
            end
            OP_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
            end
            OP_JALR: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                jump      = 1'b1;
            end
            OP_LUI: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
            end
            OP_AUIPC: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
            end
            default: begin
                invalid = 1'b1;
            end
        endcase
    end

endmodule
