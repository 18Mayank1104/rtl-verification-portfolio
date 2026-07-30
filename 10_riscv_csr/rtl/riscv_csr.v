// ============================================================
// RISC-V CSR (Control and Status Register) Block
// Implements the Zicsr extension's read-modify-write semantics
// for a small set of standard machine-mode CSRs, enough to
// support a basic trap-handling RV32I core: mstatus, mie,
// mtvec, mepc, mcause, mtval, mip.
//
// The CSR instructions (CSRRW/CSRRS/CSRRC and their -I
// immediate variants) all share one shape at the hardware
// level: read the old value out (destined for rd), then write
// a new value computed from it and an operand (rs1 or a 5-bit
// zero-extended immediate) — decoded upstream into csr_wdata.
// This block only needs to know which of the three RMW
// operations to perform.
// ============================================================
module riscv_csr (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [11:0] csr_addr,
    input  wire [1:0]  csr_op,      // 00=none, 01=WRITE, 10=SET, 11=CLEAR
    input  wire [31:0] csr_wdata,   // rs1 (CSRRW/S/C) or zero-extended uimm5 (CSRRWI/SI/CI)
    output wire [31:0] csr_rdata,   // old value, combinational (destined for rd)
    output wire        csr_valid,   // 0 if csr_addr doesn't map to a known CSR

    // trap interface: hardware-driven updates on exception entry
    input  wire         trap_enter,
    input  wire [31:0]  trap_epc,     // PC to save into mepc
    input  wire [31:0]  trap_cause,   // cause code to save into mcause
    input  wire [31:0]  trap_val      // faulting value to save into mtval
);

    localparam ADDR_MSTATUS = 12'h300;
    localparam ADDR_MIE     = 12'h304;
    localparam ADDR_MTVEC   = 12'h305;
    localparam ADDR_MEPC    = 12'h341;
    localparam ADDR_MCAUSE  = 12'h342;
    localparam ADDR_MTVAL   = 12'h343;
    localparam ADDR_MIP     = 12'h344;

    reg [31:0] mstatus, mie, mtvec, mepc, mcause, mtval, mip;

    // ---------------- combinational read ----------------
    reg [31:0] rdata_r;
    reg        valid_r;
    always @(*) begin
        valid_r = 1'b1;
        case (csr_addr)
            ADDR_MSTATUS: rdata_r = mstatus;
            ADDR_MIE:     rdata_r = mie;
            ADDR_MTVEC:   rdata_r = mtvec;
            ADDR_MEPC:    rdata_r = mepc;
            ADDR_MCAUSE:  rdata_r = mcause;
            ADDR_MTVAL:   rdata_r = mtval;
            ADDR_MIP:     rdata_r = mip;
            default: begin
                rdata_r = 32'b0;
                valid_r = 1'b0;
            end
        endcase
    end
    assign csr_rdata = rdata_r;
    assign csr_valid = valid_r;

    // ---------------- RMW helper ----------------
    function [31:0] rmw(input [31:0] old_val, input [1:0] op, input [31:0] operand);
        case (op)
            2'b01:   rmw = operand;              // WRITE
            2'b10:   rmw = old_val | operand;    // SET
            2'b11:   rmw = old_val & ~operand;   // CLEAR
            default: rmw = old_val;              // no-op
        endcase
    endfunction

    wire do_write = (csr_op != 2'b00) && valid_r;

    // ---------------- register updates ----------------
    // Trap entry takes priority over a concurrent CSR instruction
    // writing the same trap CSRs (matches real hardware: the trap
    // itself is what causes the pipeline flush, so no CSR
    // instruction is actually retiring in the same cycle a trap
    // is taken).
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mstatus <= 32'b0;
            mie     <= 32'b0;
            mtvec   <= 32'b0;
            mepc    <= 32'b0;
            mcause  <= 32'b0;
            mtval   <= 32'b0;
            mip     <= 32'b0;
        end else if (trap_enter) begin
            mepc    <= trap_epc;
            mcause  <= trap_cause;
            mtval   <= trap_val;
            mstatus <= {mstatus[31:4], 1'b0, mstatus[2:0]}; // clear MIE (bit3) on trap entry, simplified
        end else if (do_write) begin
            case (csr_addr)
                ADDR_MSTATUS: mstatus <= rmw(mstatus, csr_op, csr_wdata);
                ADDR_MIE:     mie     <= rmw(mie,     csr_op, csr_wdata);
                ADDR_MTVEC:   mtvec   <= rmw(mtvec,   csr_op, csr_wdata);
                ADDR_MEPC:    mepc    <= rmw(mepc,    csr_op, csr_wdata);
                ADDR_MCAUSE:  mcause  <= rmw(mcause,  csr_op, csr_wdata);
                ADDR_MTVAL:   mtval   <= rmw(mtval,   csr_op, csr_wdata);
                ADDR_MIP:     mip     <= rmw(mip,     csr_op, csr_wdata);
                default: ; // unmapped address, no-op
            endcase
        end
    end

endmodule
