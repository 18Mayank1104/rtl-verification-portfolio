// ============================================================
// ALU UVM Top
// Instantiates the DUT and interface, hooks the virtual
// interface into the config_db, and kicks off UVM.
// ============================================================
`include "uvm_macros.svh"

import uvm_pkg::*;

`include "alu_if.sv"
`include "alu_txn.sv"
`include "alu_sequences.sv"
`include "alu_driver.sv"
`include "alu_monitor.sv"
`include "alu_scoreboard.sv"
`include "alu_coverage.sv"
`include "alu_env.sv"

module tb_top;

    alu_if #(.WIDTH(8)) vif();

    alu #(.WIDTH(8)) dut (
        .a(vif.a),
        .b(vif.b),
        .op_sel(vif.op_sel),
        .result(vif.result),
        .zero(vif.zero),
        .carry(vif.carry),
        .overflow(vif.overflow)
    );

    initial begin
        uvm_config_db#(virtual alu_if)::set(null, "*", "vif", vif);
        run_test("alu_test");
    end

endmodule
