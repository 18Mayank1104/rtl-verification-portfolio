// ============================================================
// Instruction Memory
// Simple word-addressable ROM, loaded from a hex file at
// simulation start via $readmemh (mirrors how a real flow
// loads a compiled program image into instruction memory).
// ============================================================
module riscv_imem #(
    parameter DEPTH_WORDS = 64,
    parameter MEM_INIT_FILE = ""
)(
    input  wire [31:0] addr,   // byte address; only [31:2] used (word-aligned)
    output wire [31:0] instr
);

    reg [31:0] mem [0:DEPTH_WORDS-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH_WORDS; i = i + 1)
            mem[i] = 32'h0000_0013; // NOP (ADDI x0, x0, 0)
        if (MEM_INIT_FILE != "")
            $readmemh(MEM_INIT_FILE, mem);
    end

    assign instr = mem[addr[31:2]];

endmodule
