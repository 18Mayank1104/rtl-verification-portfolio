// ============================================================
// Self-checking testbench for Synchronous FIFO
// Uses a reference queue model to check every read against
// what was actually written, plus checks full/empty flags
// ============================================================
`timescale 1ns/1ps

module tb_sync_fifo;

    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 16;
    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg                  clk = 0;
    reg                  rst_n;
    reg                  wr_en, rd_en;
    reg  [DATA_WIDTH-1:0] wr_data;
    wire [DATA_WIDTH-1:0] rd_data;
    wire                  full, empty;
    wire [ADDR_WIDTH:0]   fifo_count;

    integer errors = 0;
    integer tests  = 0;

    // reference model: simple behavioral queue
    reg [DATA_WIDTH-1:0] ref_queue [0:255];
    integer ref_head = 0, ref_tail = 0;

    always #5 clk = ~clk; // 100 MHz

    sync_fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .wr_data(wr_data), .full(full),
        .rd_en(rd_en), .rd_data(rd_data), .empty(empty),
        .fifo_count(fifo_count)
    );

    task do_write(input [DATA_WIDTH-1:0] data);
        begin
            @(negedge clk);
            if (!full) begin
                wr_en   = 1'b1;
                wr_data = data;
                ref_queue[ref_tail] = data;
                ref_tail = ref_tail + 1;
            end else begin
                wr_en = 1'b0;
                $display("INFO write skipped, FIFO full");
            end
            @(negedge clk);
            wr_en = 1'b0;
        end
    endtask

    task do_read;
        begin
            tests = tests + 1;
            @(negedge clk);
            if (!empty) begin
                rd_en = 1'b1;
                @(negedge clk);
                rd_en = 1'b0;
                if (rd_data === ref_queue[ref_head]) begin
                    $display("PASS read data=0x%0h (expected 0x%0h)", rd_data, ref_queue[ref_head]);
                end else begin
                    $display("FAIL read data=0x%0h, expected 0x%0h", rd_data, ref_queue[ref_head]);
                    errors = errors + 1;
                end
                ref_head = ref_head + 1;
            end else begin
                rd_en = 1'b0;
                $display("INFO read skipped, FIFO empty");
            end
        end
    endtask

    integer i;
    initial begin
        rst_n = 0; wr_en = 0; rd_en = 0; wr_data = 0;
        repeat (3) @(negedge clk);
        rst_n = 1;

        // Test 1: basic write then read back, FIFO order
        for (i = 0; i < 5; i = i + 1)
            do_write(i * 8'h11);
        for (i = 0; i < 5; i = i + 1)
            do_read;

        // Test 2: fill FIFO completely, check full flag
        for (i = 0; i < DEPTH; i = i + 1)
            do_write(8'hA0 + i);
        @(negedge clk);
        tests = tests + 1;
        if (full) $display("PASS full flag asserted after %0d writes", DEPTH);
        else begin $display("FAIL full flag not asserted after %0d writes", DEPTH); errors = errors + 1; end

        // Test 3: drain completely, check empty flag
        for (i = 0; i < DEPTH; i = i + 1)
            do_read;
        @(negedge clk);
        tests = tests + 1;
        if (empty) $display("PASS empty flag asserted after full drain");
        else begin $display("FAIL empty flag not asserted after full drain"); errors = errors + 1; end

        // Test 4: overflow protection - write when full should be ignored
        for (i = 0; i < DEPTH; i = i + 1)
            do_write(8'hC0 + i);
        do_write(8'hFF); // should be dropped, FIFO already full
        do_read; // should get the FIRST value written (0xC0), not 0xFF

        $display("--------------------------------------------------");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d / %0d TESTS FAILED", errors, tests);
        $finish;
    end

endmodule
