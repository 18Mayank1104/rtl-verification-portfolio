# Synchronous FIFO — UVM Verification Environment

A complete UVM testbench for the [Synchronous FIFO](../04_sync_fifo),
with a fill sequence (writes past depth to check the full-flag
holdoff), a drain sequence, and a mixed random sequence including
simultaneous read+write cycles.

## ⚠️ Simulator requirement
Same note as the [ALU UVM environment](../12_alu_uvm/README.md):
requires a real UVM-capable simulator (Questa/VCS/Xcelium via
[EDA Playground](https://www.edaplayground.com/)), since Icarus
Verilog can't run the Accellera UVM library. See that README for
exact setup steps — same process here, just point the design pane at
`rtl/sync_fifo.v` and the testbench pane at `tb/tb_top.sv` (plus the
`` `include``d files).

## Architecture
```
fifo_txn        - per-cycle stimulus: wr_en, rd_en, wr_data (+ captured outputs)
fifo_sequences  - fill (writes past depth), drain, and mixed-random sequences
fifo_driver     - drives on negedge, gates wr_en/rd_en against full/empty
fifo_monitor    - samples at posedge, publishes ground truth to analysis port
fifo_scoreboard - independent reference QUEUE model (SystemVerilog $ queue,
                  not a re-instantiated FIFO), checks every read's data AND
                  the full/empty flags every single cycle
fifo_coverage   - full/empty boundary crosses + simultaneous-read-write bin
fifo_agent      - driver+monitor+sequencer
fifo_env        - agent+scoreboard+coverage
fifo_test       - fill -> drain -> 300 mixed-random transactions
```

## Design decisions worth calling out
- **The driver gates wr_en/rd_en against full/empty before driving
  them**, mirroring how a real upstream/downstream block would behave
  in integration. This keeps the scoreboard's reference queue exact —
  it only needs to track transactions the DUT actually accepted, not
  reason about what happens if you push into a full FIFO (which this
  DUT defines as simply being dropped, per its own README).
- **Simultaneous read+write ordering**: the scoreboard applies the
  write to the reference queue *before* popping for the read in the
  same cycle, matching a same-cycle read returning the old front of
  the queue while a new value is pushed to the back — the same
  semantics as the DUT's own pointer-based implementation.
- **Full/empty flags are checked every single monitored cycle**, not
  just after fill/drain — this is what actually catches an
  off-by-one in the pointer-wrap logic, which the original directed
  testbench in project 04 only checked at two specific moments (full
  after exactly `DEPTH` writes, empty after a full drain).

## Files
```
rtl/sync_fifo.v          - DUT (same design as project 04)
tb/fifo_if.sv
tb/fifo_txn.sv
tb/fifo_sequences.sv
tb/fifo_driver.sv
tb/fifo_monitor.sv
tb/fifo_scoreboard.sv
tb/fifo_coverage.sv
tb/fifo_env.sv            - agent, env, test
tb/tb_top.sv               - top-level module, clock, DUT instantiation
```

## Status
Written to real UVM 1.2/IEEE 1800.2 methodology. Not yet
simulator-verified in this environment for the same reason as the ALU
UVM project — see that README's status section. Run on EDA Playground
to get a real pass log.
