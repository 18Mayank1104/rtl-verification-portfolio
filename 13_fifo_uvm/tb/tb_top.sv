// ============================================================
// FIFO UVM Top
// ============================================================
`include "uvm_macros.svh"

import uvm_pkg::*;

`include "fifo_if.sv"
`include "fifo_txn.sv"
`include "fifo_sequences.sv"
`include "fifo_driver.sv"
`include "fifo_monitor.sv"
`include "fifo_scoreboard.sv"
`include "fifo_coverage.sv"
`include "fifo_env.sv"

module tb_top;

    logic clk = 0;
    always #5 clk = ~clk;

    fifo_if #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) vif(clk);

    sync_fifo #(.DATA_WIDTH(8), .DEPTH(16)) dut (
        .clk(clk),
        .rst_n(vif.rst_n),
        .wr_en(vif.wr_en), .wr_data(vif.wr_data), .full(vif.full),
        .rd_en(vif.rd_en), .rd_data(vif.rd_data), .empty(vif.empty),
        .fifo_count(vif.fifo_count)
    );

    initial begin
        vif.rst_n = 0;
        repeat (3) @(negedge clk);
        vif.rst_n = 1;
    end

    initial begin
        uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", vif);
        run_test("fifo_test");
    end

endmodule
