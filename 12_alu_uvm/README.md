# ALU — UVM Verification Environment

A complete UVM testbench for the [8-bit ALU](../01_alu), following the
standard class hierarchy: transaction → sequence → driver/monitor →
scoreboard → agent → environment → test.

## ⚠️ Simulator requirement — please read
This environment uses the real Accellera UVM class library
(`uvm_pkg`), which requires a commercial-grade SystemVerilog simulator
— **Questa, VCS, or Xcelium**. It will **not** run on Icarus Verilog
(the free simulator used for every directed-testbench project earlier
in this portfolio) — Icarus's SystemVerilog class support isn't
complete enough for the real UVM library. This isn't a bug in this
code; it's a documented ecosystem limitation of open-source
simulators.

**To actually run and verify this testbench**, use
[EDA Playground](https://www.edaplayground.com/) (free):
1. Create a new playground, paste `tb_top.sv` content into the
   testbench pane (or upload all files and `` `include`` them as done
   here) and `rtl/alu.v` into the design pane.
2. Under **Tools & Simulators**, pick **Aldec Riviera-PRO** or
   **Cadence Xcelium** and check **UVM** (select a UVM version, e.g.
   1.2 or IEEE 1800.2).
3. Click **Run**. You'll get a real, timestamped simulation log
   showing every `uvm_info`/`uvm_error` and the final scoreboard
   summary.

## Architecture
```
alu_txn         - randomizable transaction (a, b, op_sel + captured outputs)
alu_sequences   - directed edge-case sequence + constrained-random sequence
alu_driver      - drives transactions onto the DUT's combinational inputs
alu_monitor     - passively samples inputs+outputs, publishes to analysis port
alu_scoreboard  - independent golden reference model, compares every transaction
alu_coverage    - functional coverage: all 8 ops, cross op×zero, op×carry
alu_agent       - bundles driver+monitor+sequencer
alu_env         - bundles agent+scoreboard+coverage
alu_test        - runs the directed sequence, then 200 random transactions
```

## Why an independent reference model matters
The scoreboard's `predict()` function reimplements ALU behavior from
the RV32I/ALU spec directly in the testbench — it does **not** call
into or copy the DUT's `alu.v` logic. If it did, a bug present in both
places (e.g. the same shift-width mistake copy-pasted into both) would
never be caught. An independent model is what makes the comparison a
real check rather than a tautology.

## Files
```
rtl/alu.v              - DUT (same design as project 01)
tb/alu_if.sv
tb/alu_txn.sv
tb/alu_sequences.sv
tb/alu_driver.sv
tb/alu_monitor.sv
tb/alu_scoreboard.sv
tb/alu_coverage.sv
tb/alu_env.sv           - agent, env, test
tb/tb_top.sv             - top-level module, DUT instantiation, run_test()
```

## Status
Code is written to the real UVM 1.2/IEEE 1800.2 methodology and
follows the standard patterns (config_db virtual interface handoff,
analysis port TLM connections, independent scoreboard model,
functional coverage with crosses). **Not yet simulator-verified in
this environment** due to the Icarus/UVM incompatibility above — this
is the one project in the portfolio without a pasted simulation log,
and it's called out here rather than a fabricated "all tests passed."
If you run it on EDA Playground, drop the resulting log/coverage
report in this folder as `sim_log.txt` for a fully verified entry.
