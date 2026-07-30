# APB Slave — UVM Verification Environment

A complete UVM testbench for the [APB Slave](../06_apb_slave), driving
proper 2-phase (SETUP/ACCESS) APB transfers and checking both data
correctness and `PSLVERR` behavior against an independent register
model.

## ⚠️ Simulator requirement
Same note as the [ALU](../12_alu_uvm/README.md) and
[FIFO](../13_fifo_uvm/README.md) UVM environments: needs a real
UVM-capable simulator via [EDA Playground](https://www.edaplayground.com/),
since Icarus Verilog can't run the Accellera UVM library.

## Architecture
```
apb_txn        - one APB transfer: addr, write/read, wdata (+ captured rdata/slverr)
                 address constrained 90% toward the valid range, 10% out-of-range,
                 so PSLVERR gets exercised by random stimulus too
apb_sequences  - directed (write+read-back every register, overwrite, both
                 out-of-range cases) + constrained-random
apb_driver     - drives a real 2-phase SETUP/ACCESS transfer, negedge-timed
apb_monitor    - detects transfer completion at PSEL&&PENABLE&&PREADY,
                 independent of the driver's own timing
apb_scoreboard - independent associative-array register model, checks
                 every write's SLVERR behavior and every read's data+SLVERR
apb_coverage   - cross of write/read × in-range/out-of-range address
apb_agent      - driver+monitor+sequencer
apb_env        - agent+scoreboard+coverage
apb_test       - directed sequence, then 150 random transactions
```

## Design decisions worth calling out
- **The driver drives all stimulus on the negative clock edge**, the
  same convention adopted after the timing race found in project 06's
  original directed testbench (see that project's README for the
  full story: an FSM-based APB slave design that asserted `PREADY` a
  full cycle before `PENABLE` was actually valid, caught by
  protocol-correct testbench timing). This UVM driver reuses that
  lesson directly.
- **The monitor detects transfer completion independently of the
  driver's timing** — it watches for `PSEL && PENABLE && PREADY` on
  the bus itself, rather than assuming anything about when the driver
  considers a transfer "done." This means the monitor would work
  correctly even against a different master with different timing,
  which is the actual point of separating monitor from driver in UVM.
- **The scoreboard's register model is a `bit [31:0] ref_regs[bit[7:0]]`
  associative array**, entirely independent of the DUT's own
  `regs[0:NUM_REGS-1]` array — checking against a copy of the DUT's
  own storage would just be checking the DUT against itself.

## Files
```
rtl/apb_slave.v         - DUT (same design as project 06)
tb/apb_if.sv
tb/apb_txn.sv
tb/apb_sequences.sv
tb/apb_driver.sv
tb/apb_monitor.sv
tb/apb_scoreboard.sv
tb/apb_coverage.sv
tb/apb_env.sv             - agent, env, test
tb/tb_top.sv                - top-level module, clock, DUT instantiation
```

## Status
Written to real UVM 1.2/IEEE 1800.2 methodology. Not yet
simulator-verified in this environment for the same reason as the
other UVM projects in this portfolio — see the ALU UVM README's
status section for the full explanation. Run on EDA Playground to get
a real pass log.
