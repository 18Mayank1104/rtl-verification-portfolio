// ============================================================
// SPI self-checking testbench
// Connects spi_master to spi_slave and checks bidirectional
// byte transfer (master TX -> slave RX, slave TX -> master RX)
// ============================================================
`timescale 1ns/1ps

module tb_spi;

    reg clk = 0;
    reg rst_n;
    always #5 clk = ~clk; // 100 MHz

    reg  [7:0] m_tx_data, s_tx_data;
    wire [7:0] m_rx_data, s_rx_data;
    reg        m_start;
    wire       m_busy, m_done, s_rx_valid;

    wire sclk, mosi, miso, ss_n;

    integer errors = 0;
    integer tests  = 0;

    spi_master #(.CLK_DIV(4)) u_master (
        .clk(clk), .rst_n(rst_n),
        .start(m_start), .tx_data(m_tx_data),
        .rx_data(m_rx_data), .busy(m_busy), .done(m_done),
        .sclk(sclk), .mosi(mosi), .miso(miso), .ss_n(ss_n)
    );

    spi_slave u_slave (
        .clk(clk), .rst_n(rst_n),
        .tx_data(s_tx_data),
        .rx_data(s_rx_data), .rx_valid(s_rx_valid),
        .sclk(sclk), .mosi(mosi), .miso(miso), .ss_n(ss_n)
    );

    task do_transfer(input [7:0] master_byte, input [7:0] slave_byte);
        begin
            tests = tests + 1;
            m_tx_data = master_byte;
            s_tx_data = slave_byte;
            @(posedge clk);
            m_start = 1'b1;
            @(posedge clk);
            m_start = 1'b0;

            fork : wait_done
                begin
                    wait (m_done == 1'b1);
                    disable wait_done;
                end
                begin
                    #10000;
                    $display("FAIL [m=0x%0h s=0x%0h] TIMEOUT", master_byte, slave_byte);
                    errors = errors + 1;
                    disable wait_done;
                end
            join

            @(posedge clk);
            if (m_rx_data === slave_byte && s_rx_data === master_byte) begin
                $display("PASS master_sent=0x%0h slave_sent=0x%0h -> master_got=0x%0h slave_got=0x%0h",
                          master_byte, slave_byte, m_rx_data, s_rx_data);
            end else begin
                $display("FAIL master_sent=0x%0h slave_sent=0x%0h -> master_got=0x%0h(exp 0x%0h) slave_got=0x%0h(exp 0x%0h)",
                          master_byte, slave_byte, m_rx_data, slave_byte, s_rx_data, master_byte);
                errors = errors + 1;
            end
            repeat (4) @(posedge clk);
        end
    endtask

    initial begin
        rst_n = 0;
        m_start = 0;
        m_tx_data = 0;
        s_tx_data = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (5) @(posedge clk);

        do_transfer(8'hA5, 8'h5A);
        do_transfer(8'h00, 8'hFF);
        do_transfer(8'hFF, 8'h00);
        do_transfer(8'h3C, 8'hC3);
        do_transfer(8'h81, 8'h18);

        $display("--------------------------------------------------");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d / %0d TESTS FAILED", errors, tests);
        $finish;
    end

endmodule
