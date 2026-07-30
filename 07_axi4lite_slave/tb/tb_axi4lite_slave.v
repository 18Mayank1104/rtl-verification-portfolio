// ============================================================
// Self-checking testbench for AXI4-Lite Slave
// Drives independent AW/W/B and AR/R channel handshakes via a
// small master BFM, using level-sensitive polling loops for
// each handshake (robust to exact cycle timing, since AXI
// valid/ready is a level-sensitive protocol, not edge-precise
// like APB's single request/response pair).
// ============================================================
`timescale 1ns/1ps

module tb_axi4lite_slave;

    localparam ADDR_WIDTH = 8;
    localparam DATA_WIDTH = 32;
    localparam NUM_REGS   = 8;

    reg  aclk = 0;
    reg  aresetn;

    reg  [ADDR_WIDTH-1:0]     awaddr;
    reg                       awvalid;
    wire                      awready;

    reg  [DATA_WIDTH-1:0]     wdata;
    reg  [(DATA_WIDTH/8)-1:0] wstrb;
    reg                       wvalid;
    wire                      wready;

    wire [1:0]                bresp;
    wire                      bvalid;
    reg                       bready;

    reg  [ADDR_WIDTH-1:0]     araddr;
    reg                       arvalid;
    wire                      arready;

    wire [DATA_WIDTH-1:0]     rdata;
    wire [1:0]                rresp;
    wire                      rvalid;
    reg                       rready;

    integer errors = 0;
    integer tests  = 0;

    always #5 aclk = ~aclk; // 100 MHz

    axi4lite_slave #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .NUM_REGS(NUM_REGS)) dut (
        .aclk(aclk), .aresetn(aresetn),
        .s_axi_awaddr(awaddr), .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wvalid(wvalid), .s_axi_wready(wready),
        .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
        .s_axi_araddr(araddr), .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rdata(rdata), .s_axi_rresp(rresp), .s_axi_rvalid(rvalid), .s_axi_rready(rready)
    );

    // ---------------- AXI4-Lite master BFM ----------------
    task axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data, output [1:0] resp);
        begin
            @(negedge aclk);
            awaddr  = addr;
            awvalid = 1'b1;
            wdata   = data;
            wstrb   = 4'hF;
            wvalid  = 1'b1;
            bready  = 1'b1;

            // wait for AW+W handshake to complete
            @(posedge aclk);
            while (!(awready && wready)) @(posedge aclk);
            @(negedge aclk);
            awvalid = 1'b0;
            wvalid  = 1'b0;

            // wait for B (response) handshake
            @(posedge aclk);
            while (!bvalid) @(posedge aclk);
            resp = bresp;
            @(negedge aclk);
            bready = 1'b0;
        end
    endtask

    task axi_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data, output [1:0] resp);
        begin
            @(negedge aclk);
            araddr  = addr;
            arvalid = 1'b1;
            rready  = 1'b1;

            @(posedge aclk);
            while (!arready) @(posedge aclk);
            @(negedge aclk);
            arvalid = 1'b0;

            @(posedge aclk);
            while (!rvalid) @(posedge aclk);
            data = rdata;
            resp = rresp;
            @(negedge aclk);
            rready = 1'b0;
        end
    endtask

    reg [DATA_WIDTH-1:0] rd_val;
    reg [1:0]             resp_val;
    integer i;

    initial begin
        aresetn = 0; awaddr=0; awvalid=0; wdata=0; wstrb=0; wvalid=0; bready=0;
        araddr=0; arvalid=0; rready=0;
        repeat (3) @(negedge aclk);
        aresetn = 1;
        repeat (2) @(negedge aclk);

        // Test 1: write then read back every valid register
        for (i = 0; i < NUM_REGS; i = i + 1) begin
            axi_write(i * 4, 32'hBEEF_0000 + i, resp_val);
        end
        for (i = 0; i < NUM_REGS; i = i + 1) begin
            tests = tests + 1;
            axi_read(i * 4, rd_val, resp_val);
            if (rd_val === (32'hBEEF_0000 + i) && resp_val === 2'b00)
                $display("PASS reg[%0d] read back 0x%08h", i, rd_val);
            else begin
                $display("FAIL reg[%0d] read 0x%08h resp=%0b, expected 0x%08h OKAY", i, rd_val, resp_val, 32'hBEEF_0000 + i);
                errors = errors + 1;
            end
        end

        // Test 2: overwrite and confirm new value sticks
        tests = tests + 1;
        axi_write(3 * 4, 32'h1234_5678, resp_val);
        axi_read(3 * 4, rd_val, resp_val);
        if (rd_val === 32'h1234_5678)
            $display("PASS reg[3] overwrite -> 0x%08h", rd_val);
        else begin
            $display("FAIL reg[3] overwrite -> 0x%08h, expected 0x12345678", rd_val);
            errors = errors + 1;
        end

        // Test 3: partial write using WSTRB (only lower byte)
        tests = tests + 1;
        @(negedge aclk);
        awaddr = 5 * 4; awvalid = 1; wdata = 32'hFFFF_FF00; wstrb = 4'b0001; wvalid = 1; bready = 1;
        @(posedge aclk);
        while (!(awready && wready)) @(posedge aclk);
        @(negedge aclk);
        awvalid = 0; wvalid = 0;
        @(posedge aclk);
        while (!bvalid) @(posedge aclk);
        @(negedge aclk);
        bready = 0;
        axi_read(5 * 4, rd_val, resp_val);
        // reg[5] was 0xBEEF0005 from Test 1; WSTRB=0001 with wdata=0xFFFFFF00
        // should only replace byte 0 (0x05 -> 0x00), leaving upper bytes untouched
        if (rd_val === 32'hBEEF_0000)
            $display("PASS reg[5] WSTRB partial write -> 0x%08h", rd_val);
        else begin
            $display("FAIL reg[5] WSTRB partial write -> 0x%08h, expected 0xBEEF0000", rd_val);
            errors = errors + 1;
        end

        // Test 4: out-of-range write should get SLVERR
        tests = tests + 1;
        axi_write(NUM_REGS * 4, 32'hDEAD_DEAD, resp_val);
        if (resp_val === 2'b10)
            $display("PASS out-of-range write correctly returned SLVERR");
        else begin
            $display("FAIL out-of-range write resp=%0b, expected SLVERR(10)", resp_val);
            errors = errors + 1;
        end

        // Test 5: out-of-range read should get SLVERR and rdata=0
        tests = tests + 1;
        axi_read(NUM_REGS * 4, rd_val, resp_val);
        if (resp_val === 2'b10 && rd_val === {DATA_WIDTH{1'b0}})
            $display("PASS out-of-range read correctly returned SLVERR, rdata=0");
        else begin
            $display("FAIL out-of-range read resp=%0b rdata=0x%08h, expected SLVERR/0", resp_val, rd_val);
            errors = errors + 1;
        end

        // Test 6: out-of-range write did not corrupt reg[0]
        tests = tests + 1;
        axi_read(0, rd_val, resp_val);
        if (rd_val === 32'hBEEF_0000)
            $display("PASS out-of-range write did not corrupt reg[0]");
        else begin
            $display("FAIL reg[0] corrupted: 0x%08h", rd_val);
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
        #20000;
        $display("TIMEOUT: simulation did not complete in time");
        $finish;
    end

endmodule
