// ============================================================
// UART self-checking loopback testbench
// TX output is looped back into RX; verifies byte integrity
// ============================================================
`timescale 1ns/1ps

module tb_uart;

    localparam CLK_FREQ  = 50_000_000;
    localparam BAUD_RATE = 115_200;
    localparam CLK_PERIOD = 20; // 50 MHz

    reg clk = 0;
    reg rst_n;
    wire tick_16x;

    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx_line, tx_busy;

    wire [7:0] rx_data;
    wire       rx_valid, rx_error;

    integer errors = 0;
    integer tests  = 0;

    always #(CLK_PERIOD/2) clk = ~clk;

    baud_gen #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_baud (
        .clk(clk), .rst_n(rst_n), .tick_16x(tick_16x)
    );

    uart_tx u_tx (
        .clk(clk), .rst_n(rst_n), .tick_16x(tick_16x),
        .tx_start(tx_start), .tx_data(tx_data),
        .tx(tx_line), .tx_busy(tx_busy)
    );

    uart_rx u_rx (
        .clk(clk), .rst_n(rst_n), .tick_16x(tick_16x),
        .rx(tx_line), // loopback
        .rx_data(rx_data), .rx_valid(rx_valid), .rx_error(rx_error)
    );

    task send_and_check(input [7:0] byte_val);
        begin
            tests = tests + 1;
            @(posedge clk);
            tx_data  = byte_val;
            tx_start = 1'b1;
            @(posedge clk);
            tx_start = 1'b0;

            // wait for rx_valid, with timeout
            fork : wait_block
                begin
                    wait (rx_valid == 1'b1);
                    disable wait_block;
                end
                begin
                    #200000; // timeout
                    $display("FAIL [byte=%0h] TIMEOUT waiting for rx_valid", byte_val);
                    errors = errors + 1;
                    disable wait_block;
                end
            join

            if (rx_valid) begin
                if (rx_data === byte_val && rx_error === 1'b0)
                    $display("PASS [byte=0x%0h] received correctly", byte_val);
                else begin
                    $display("FAIL [byte=0x%0h] got rx_data=0x%0h rx_error=%0b", byte_val, rx_data, rx_error);
                    errors = errors + 1;
                end
            end
            @(posedge clk);
            wait (tx_busy == 1'b0);
        end
    endtask

    initial begin
        rst_n = 0;
        tx_start = 0;
        tx_data = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (5) @(posedge clk);

        send_and_check(8'h55); // 01010101 pattern
        send_and_check(8'hA5);
        send_and_check(8'h00);
        send_and_check(8'hFF);
        send_and_check(8'h3C);

        $display("--------------------------------------------------");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d / %0d TESTS FAILED", errors, tests);
        $finish;
    end

endmodule
