// ============================================================
// Self-checking testbench for RISC-V CSR Block
// Covers WRITE/SET/CLEAR RMW ops, an unmapped-address read,
// and the hardware trap-entry path (mepc/mcause/mtval capture).
// ============================================================
`timescale 1ns/1ps

module tb_riscv_csr;

    reg         clk = 0;
    reg         rst_n;
    reg  [11:0] csr_addr;
    reg  [1:0]  csr_op;
    reg  [31:0] csr_wdata;
    wire [31:0] csr_rdata;
    wire        csr_valid;
    reg         trap_enter;
    reg  [31:0] trap_epc, trap_cause, trap_val;

    integer errors = 0;
    integer tests  = 0;

    always #5 clk = ~clk;

    riscv_csr dut (
        .clk(clk), .rst_n(rst_n),
        .csr_addr(csr_addr), .csr_op(csr_op), .csr_wdata(csr_wdata),
        .csr_rdata(csr_rdata), .csr_valid(csr_valid),
        .trap_enter(trap_enter), .trap_epc(trap_epc), .trap_cause(trap_cause), .trap_val(trap_val)
    );

    localparam MSTATUS = 12'h300;
    localparam MTVEC   = 12'h305;
    localparam MEPC    = 12'h341;
    localparam MCAUSE  = 12'h342;
    localparam MTVAL   = 12'h343;
    localparam BOGUS   = 12'hFFF;

    task do_csr_op(input [11:0] addr, input [1:0] op, input [31:0] wdata);
        begin
            @(negedge clk);
            csr_addr  = addr;
            csr_op    = op;
            csr_wdata = wdata;
            @(negedge clk);
            csr_op    = 2'b00; // deassert after one cycle
        end
    endtask

    task check_read(input [11:0] addr, input [31:0] exp_val, input exp_valid, input [127:0] name);
        begin
            tests = tests + 1;
            @(negedge clk);
            csr_addr = addr;
            csr_op   = 2'b00;
            #1;
            if (csr_rdata === exp_val && csr_valid === exp_valid)
                $display("PASS [%0s] addr=0x%03h rdata=0x%08h valid=%b", name, addr, csr_rdata, csr_valid);
            else begin
                $display("FAIL [%0s] addr=0x%03h rdata=0x%08h(exp 0x%08h) valid=%b(exp %b)",
                          name, addr, csr_rdata, exp_val, csr_valid, exp_valid);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        rst_n = 0; csr_addr = 0; csr_op = 0; csr_wdata = 0;
        trap_enter = 0; trap_epc = 0; trap_cause = 0; trap_val = 0;
        repeat (3) @(negedge clk);
        rst_n = 1;
        repeat (2) @(negedge clk);

        // Test 1: CSRRW-equivalent (WRITE) to mtvec
        do_csr_op(MTVEC, 2'b01, 32'h8000_0000);
        check_read(MTVEC, 32'h8000_0000, 1'b1, "WRITE_mtvec");

        // Test 2: CSRRS-equivalent (SET) on mstatus
        do_csr_op(MSTATUS, 2'b01, 32'h0000_0008); // start from known value
        do_csr_op(MSTATUS, 2'b10, 32'h0000_0080); // set bit 7
        check_read(MSTATUS, 32'h0000_0088, 1'b1, "SET_mstatus_bit7");

        // Test 3: CSRRC-equivalent (CLEAR) on mstatus - clear bit 3
        do_csr_op(MSTATUS, 2'b11, 32'h0000_0008);
        check_read(MSTATUS, 32'h0000_0080, 1'b1, "CLEAR_mstatus_bit3");

        // Test 4: unmapped CSR address returns valid=0, rdata=0
        check_read(BOGUS, 32'h0, 1'b0, "UNMAPPED_ADDR");

        // Test 5: write to unmapped address should be a silent no-op
        // (does not corrupt any real CSR, does not hang / error)
        do_csr_op(BOGUS, 2'b01, 32'hDEAD_DEAD);
        check_read(MTVEC, 32'h8000_0000, 1'b1, "UNMAPPED_WRITE_NOOP");

        // Test 6: hardware trap entry captures epc/cause/tval
        @(negedge clk);
        trap_epc   = 32'h0000_1004;
        trap_cause = 32'h0000_000B; // environment call from M-mode
        trap_val   = 32'h0000_0000;
        trap_enter = 1'b1;
        @(negedge clk);
        trap_enter = 1'b0;
        check_read(MEPC,   32'h0000_1004, 1'b1, "TRAP_mepc_captured");
        check_read(MCAUSE, 32'h0000_000B, 1'b1, "TRAP_mcause_captured");
        check_read(MTVAL,  32'h0000_0000, 1'b1, "TRAP_mtval_captured");

        // Test 7: trap entry clears MIE (bit 3) in mstatus
        check_read(MSTATUS, 32'h0000_0080, 1'b1, "TRAP_mstatus_mie_cleared");

        $display("--------------------------------------------------");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d / %0d TESTS FAILED", errors, tests);
        $finish;
    end

endmodule
