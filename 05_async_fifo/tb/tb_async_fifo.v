// ============================================================
// Self-checking testbench for Asynchronous FIFO
// Write clock and read clock run at different, unrelated
// frequencies to genuinely exercise the CDC synchronizers.
// Checks data integrity and ordering via a reference queue.
// ============================================================
`timescale 1ns/1ps

module tb_async_fifo;

    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 16;
    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg wr_clk = 0;
    reg rd_clk = 0;
    reg wr_rst_n, rd_rst_n;

    reg                   wr_en;
    reg  [DATA_WIDTH-1:0] wr_data;
    wire                  full;

    reg                   rd_en;
    wire [DATA_WIDTH-1:0] rd_data;
    wire                  empty;

    integer errors = 0;
    integer tests  = 0;

    // write clock: 10ns period (100 MHz)
    always #5 wr_clk = ~wr_clk;
    // read clock: 17ns period (~58.8 MHz) - deliberately unrelated frequency
    always #8.5 rd_clk = ~rd_clk;

    async_fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (
        .wr_clk(wr_clk), .wr_rst_n(wr_rst_n), .wr_en(wr_en), .wr_data(wr_data), .full(full),
        .rd_clk(rd_clk), .rd_rst_n(rd_rst_n), .rd_en(rd_en), .rd_data(rd_data), .empty(empty)
    );

    // reference queue, shared between the two clock-domain processes
    reg [DATA_WIDTH-1:0] ref_queue [0:255];
    integer ref_tail = 0;
    integer ref_head = 0;
    integer write_count = 0;
    integer read_count  = 0;
    localparam integer TOTAL_WORDS = 40;

    // ---------------- writer process (wr_clk domain) ----------------
    initial begin
        wr_rst_n = 0; wr_en = 0; wr_data = 0;
        repeat (5) @(negedge wr_clk);
        wr_rst_n = 1;
        repeat (3) @(negedge wr_clk);

        while (write_count < TOTAL_WORDS) begin
            @(negedge wr_clk);
            if (!full) begin
                wr_en   = 1'b1;
                wr_data = write_count[7:0] ^ 8'hA5; // simple deterministic pattern
                ref_queue[ref_tail] = write_count[7:0] ^ 8'hA5;
                ref_tail = ref_tail + 1;
                write_count = write_count + 1;
            end else begin
                wr_en = 1'b0;
            end
            @(negedge wr_clk);
            wr_en = 1'b0;
        end
    end

    // ---------------- reader process (rd_clk domain) ----------------
    initial begin
        rd_rst_n = 0; rd_en = 0;
        repeat (5) @(negedge rd_clk);
        rd_rst_n = 1;
        repeat (3) @(negedge rd_clk);

        while (read_count < TOTAL_WORDS) begin
            @(negedge rd_clk);
            if (!empty) begin
                rd_en = 1'b1;
                @(negedge rd_clk);
                rd_en = 1'b0;
                tests = tests + 1;
                if (rd_data === ref_queue[ref_head]) begin
                    $display("PASS [word %0d] read data=0x%0h (expected 0x%0h)", read_count, rd_data, ref_queue[ref_head]);
                end else begin
                    $display("FAIL [word %0d] read data=0x%0h, expected 0x%0h", read_count, rd_data, ref_queue[ref_head]);
                    errors = errors + 1;
                end
                ref_head = ref_head + 1;
                read_count = read_count + 1;
            end else begin
                rd_en = 1'b0;
            end
        end

        $display("--------------------------------------------------");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED (async CDC data integrity verified across %0d words)", tests, TOTAL_WORDS);
        else
            $display("%0d / %0d TESTS FAILED", errors, tests);
        $finish;
    end

    // safety timeout
    initial begin
        #100000;
        $display("TIMEOUT: simulation did not complete in time");
        $finish;
    end

endmodule
