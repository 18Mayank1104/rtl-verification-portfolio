// ============================================================
// RISC-V RV32I Register File
// 32 x 32-bit general purpose registers.
// - x0 is hardwired to zero (writes to x0 are always ignored,
//   reads from x0 always return zero), per the RV32I spec.
// - Two combinational read ports (rs1, rs2) — a real 5-stage
//   pipeline reads both source operands in the same cycle.
// - One synchronous write port (rd), gated by reg_write.
// - Write-before-read same-cycle forwarding: if rd == rs1/rs2
//   and a write is happening this cycle, the read port reflects
//   the NEW value immediately (standard register file behavior
//   used to avoid a spurious pipeline hazard/bubble).
// ============================================================
module riscv_regfile #(
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS   = 32
)(
    input  wire                       clk,
    input  wire                       rst_n,

    input  wire [4:0]                 rs1_addr,
    output wire [DATA_WIDTH-1:0]      rs1_data,

    input  wire [4:0]                 rs2_addr,
    output wire [DATA_WIDTH-1:0]      rs2_data,

    input  wire [4:0]                 rd_addr,
    input  wire [DATA_WIDTH-1:0]      rd_data,
    input  wire                       reg_write
);

    reg [DATA_WIDTH-1:0] regs [1:NUM_REGS-1]; // x0 is not a real storage element

    integer i;

    // ---------------- write port ----------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 1; i < NUM_REGS; i = i + 1)
                regs[i] <= {DATA_WIDTH{1'b0}};
        end else if (reg_write && rd_addr != 5'd0) begin
            regs[rd_addr] <= rd_data;
        end
    end

    // ---------------- read ports (combinational, with write-through) ----------------
    assign rs1_data = (rs1_addr == 5'd0) ? {DATA_WIDTH{1'b0}} :
                       (reg_write && rd_addr == rs1_addr) ? rd_data :
                       regs[rs1_addr];

    assign rs2_data = (rs2_addr == 5'd0) ? {DATA_WIDTH{1'b0}} :
                       (reg_write && rd_addr == rs2_addr) ? rd_data :
                       regs[rs2_addr];

endmodule
