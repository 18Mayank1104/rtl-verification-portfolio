# AXI4-Lite Slave

An AXI4-Lite slave wrapping a small word-addressable register file, with
independent handshakes on all five channels (AW, W, B, AR, R), `WSTRB`
byte-enable support on writes, and `SLVERR` for out-of-range addresses.

## Protocol recap
Unlike APB's single request/response pair, AXI4-Lite splits a
transaction into independent, decoupled channels, each with its own
`valid`/`ready` handshake — a transfer completes on whichever clock
edge both `valid` and `ready` are high, and either side can stall by
holding its signal low:
- **Write**: AW (address) and W (data) can arrive in any order or
  simultaneously; once both are accepted, B (response) is issued.
- **Read**: AR (address) is accepted, then R (data + response) is
  returned.

## Design notes
- `aw_en` gates AWREADY/WREADY so a new address isn't accepted until
  the previous write's B response has been accepted — prevents a second
  transaction from overwriting the latched address mid-transfer.
- `WSTRB` is honored per-byte on writes — only the byte lanes with
  their strobe bit set are updated, the rest of the register is
  untouched (standard AXI byte-enable behavior).
- Out-of-range addresses return `SLVERR` (`2'b10`) on both the write
  response and read response channels; out-of-range writes are dropped
  without touching any valid register.

## Files
```
rtl/axi4lite_slave.v
tb/tb_axi4lite_slave.v   - self-checking testbench with an AXI4-Lite master BFM
```

## Simulation (Icarus Verilog)
```bash
iverilog -o sim rtl/axi4lite_slave.v tb/tb_axi4lite_slave.v
vvp sim
```
13 tests: write+read-back of every register, a register overwrite, a
`WSTRB` partial-byte write, out-of-range write/read `SLVERR` checks,
and a check that an out-of-range write doesn't corrupt other
registers. All 13 pass.

## Testbench design note
AXI4-Lite's `valid`/`ready` handshake is level-sensitive (either side
can hold and stall), not edge-precise like APB. The master BFM here
polls each handshake with a `while (!ready) @(posedge aclk)` loop
rather than assuming a fixed number of cycles — this is the standard
robust pattern and avoids baking in timing assumptions that would
break if the slave's latency ever changed (e.g. if wait states were
added later).
