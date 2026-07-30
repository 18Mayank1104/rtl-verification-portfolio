// ============================================================
// APB UVM Top
// ============================================================
`include "uvm_macros.svh"

import uvm_pkg::*;

`include "apb_if.sv"
`include "apb_txn.sv"
`include "apb_sequences.sv"
`include "apb_driver.sv"
`include "apb_monitor.sv"
`include "apb_scoreboard.sv"
`include "apb_coverage.sv"
`include "apb_env.sv"

module tb_top;

    logic pclk = 0;
    always #5 pclk = ~pclk;

    apb_if #(.ADDR_WIDTH(8), .DATA_WIDTH(32)) vif(pclk);

    apb_slave #(.ADDR_WIDTH(8), .DATA_WIDTH(32), .NUM_REGS(8)) dut (
        .pclk(pclk), .presetn(vif.presetn),
        .paddr(vif.paddr), .psel(vif.psel), .penable(vif.penable), .pwrite(vif.pwrite),
        .pwdata(vif.pwdata), .prdata(vif.prdata), .pready(vif.pready), .pslverr(vif.pslverr)
    );

    initial begin
        vif.presetn = 0;
        repeat (3) @(negedge pclk);
        vif.presetn = 1;
    end

    initial begin
        uvm_config_db#(virtual apb_if)::set(null, "*", "vif", vif);
        run_test("apb_test");
    end

endmodule
