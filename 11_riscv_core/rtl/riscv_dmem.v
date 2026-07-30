// ============================================================
// Data Memory
// Byte-addressable RAM supporting the full RV32I load/store
// width variants (byte/half/word, signed and unsigned loads)
// selected by funct3, matching LB/LH/LW/LBU/LHU and SB/SH/SW.
// ============================================================
module riscv_dmem #(
    parameter DEPTH_BYTES = 256
)(
    input  wire        clk,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire         mem_write,
    input  wire         mem_read,
    input  wire [2:0]  funct3,     // load/store width + signedness selector
    output reg  [31:0] rdata
);

    reg [7:0] mem [0:DEPTH_BYTES-1];
    integer i;
    initial for (i = 0; i < DEPTH_BYTES; i = i + 1) mem[i] = 8'h00;

    localparam F3_BYTE  = 3'b000; // LB/SB
    localparam F3_HALF  = 3'b001; // LH/SH
    localparam F3_WORD  = 3'b010; // LW/SW
    localparam F3_BYTEU = 3'b100; // LBU
    localparam F3_HALFU = 3'b101; // LHU

    wire [31:0] a = addr;

    // ---------------- write ----------------
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                F3_BYTE: mem[a] <= wdata[7:0];
                F3_HALF: begin
                    mem[a]     <= wdata[7:0];
                    mem[a + 1] <= wdata[15:8];
                end
                F3_WORD: begin
                    mem[a]     <= wdata[7:0];
                    mem[a + 1] <= wdata[15:8];
                    mem[a + 2] <= wdata[23:16];
                    mem[a + 3] <= wdata[31:24];
                end
                default: ; // ignore malformed store width
            endcase
        end
    end

    // ---------------- read (combinational) ----------------
    always @(*) begin
        case (funct3)
            F3_BYTE:  rdata = {{24{mem[a][7]}}, mem[a]};
            F3_BYTEU: rdata = {24'b0, mem[a]};
            F3_HALF:  rdata = {{16{mem[a+1][7]}}, mem[a+1], mem[a]};
            F3_HALFU: rdata = {16'b0, mem[a+1], mem[a]};
            F3_WORD:  rdata = {mem[a+3], mem[a+2], mem[a+1], mem[a]};
            default:  rdata = 32'b0;
        endcase
        if (!mem_read) rdata = 32'b0;
    end

endmodule
