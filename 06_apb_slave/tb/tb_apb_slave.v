// ============================================================
// Self-checking testbench for APB Slave
// Drives proper APB SETUP/ACCESS phase transactions via a
// small master BFM (bus functional model) task, checks
// write-then-read-back data integrity and the PSLVERR path
// for out-of-range addresses.
//
// Stimulus is driven on the negative clock edge (standard
// testbench convention) so it settles well before the DUT's
// posedge-triggered logic samples it — avoiding a race where
// both the testbench and the DUT react to the same edge.
// ============================================================
`timescale 1ns/1ps

module tb_apb_slave;

    localparam ADDR_WIDTH = 8;
    localparam DATA_WIDTH = 32;
    localparam NUM_REGS   = 8;

    reg                     pclk = 0;
    reg                     presetn;
    reg  [ADDR_WIDTH-1:0]   paddr;
    reg                     psel, penable, pwrite;
    reg  [DATA_WIDTH-1:0]   pwdata;
    wire [DATA_WIDTH-1:0]   prdata;
    wire                    pready, pslverr;

    integer errors = 0;
    integer tests  = 0;

    always #5 pclk = ~pclk; // 100 MHz

    apb_slave #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .NUM_REGS(NUM_REGS)) dut (
        .pclk(pclk), .presetn(presetn),
        .paddr(paddr), .psel(psel), .penable(penable), .pwrite(pwrite),
        .pwdata(pwdata), .prdata(prdata), .pready(pready), .pslverr(pslverr)
    );

    // ---------------- APB master BFM ----------------
    task apb_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            @(negedge pclk);
            paddr   = addr;
            pwdata  = data;
            pwrite  = 1'b1;
            psel    = 1'b1;
            penable = 1'b0;           // SETUP phase
            @(negedge pclk);
            penable = 1'b1;           // ACCESS phase
            @(negedge pclk);          // pready/pslverr settled from the posedge in between
            while (!pready) @(negedge pclk);
            psel    = 1'b0;
            penable = 1'b0;
        end
    endtask

    task apb_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data, output err);
        begin
            @(negedge pclk);
            paddr   = addr;
            pwrite  = 1'b0;
            psel    = 1'b1;
            penable = 1'b0;
            @(negedge pclk);
            penable = 1'b1;
            @(negedge pclk);
            while (!pready) @(negedge pclk);
            data = prdata;
            err  = pslverr;
            psel    = 1'b0;
            penable = 1'b0;
        end
    endtask

    reg [DATA_WIDTH-1:0] rdata;
    reg                  rerr;
    integer i;

    initial begin
        presetn = 0; psel = 0; penable = 0; pwrite = 0; paddr = 0; pwdata = 0;
        repeat (3) @(negedge pclk);
        presetn = 1;
        repeat (2) @(negedge pclk);

        // Test 1: write then read back every valid register
        for (i = 0; i < NUM_REGS; i = i + 1) begin
            apb_write(i * 4, 32'hCAFE_0000 + i);
        end
        for (i = 0; i < NUM_REGS; i = i + 1) begin
            tests = tests + 1;
            apb_read(i * 4, rdata, rerr);
            if (rdata === (32'hCAFE_0000 + i) && rerr === 1'b0)
                $display("PASS reg[%0d] read back 0x%08h", i, rdata);
            else begin
                $display("FAIL reg[%0d] read 0x%08h err=%0b, expected 0x%08h err=0", i, rdata, rerr, 32'hCAFE_0000 + i);
                errors = errors + 1;
            end
        end

        // Test 2: overwrite a register and confirm new value sticks
        tests = tests + 1;
        apb_write(4 * 4, 32'hDEAD_BEEF);
        apb_read(4 * 4, rdata, rerr);
        if (rdata === 32'hDEAD_BEEF)
            $display("PASS reg[4] overwrite -> 0x%08h", rdata);
        else begin
            $display("FAIL reg[4] overwrite -> 0x%08h, expected 0xDEADBEEF", rdata);
            errors = errors + 1;
        end

        // Test 3: out-of-range address should assert PSLVERR
        tests = tests + 1;
        apb_read(NUM_REGS * 4, rdata, rerr); // one past the last valid register
        if (rerr === 1'b1)
            $display("PASS out-of-range address correctly asserted PSLVERR");
        else begin
            $display("FAIL out-of-range address did not assert PSLVERR (got %0b)", rerr);
            errors = errors + 1;
        end

        // Test 4: out-of-range write should not corrupt memory (no crash / no valid reg touched)
        tests = tests + 1;
        apb_write(NUM_REGS * 4, 32'hBAD0_BAD0);
        apb_read(0, rdata, rerr); // reg 0 should be untouched by the bad write
        if (rdata === 32'hCAFE_0000)
            $display("PASS out-of-range write did not corrupt reg[0]");
        else begin
            $display("FAIL reg[0] corrupted after out-of-range write: 0x%08h", rdata);
            errors = errors + 1;
        end

        $display("--------------------------------------------------");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d / %0d TESTS FAILED", errors, tests);
        $finish;
    end

    // safety timeout
    initial begin
        #10000;
        $display("TIMEOUT: simulation did not complete in time");
        $finish;
    end

endmodule
