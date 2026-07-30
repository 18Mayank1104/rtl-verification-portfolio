# RISC-V RV32I Register File

The 32 x 32-bit general-purpose register file for an RV32I core, with
two combinational read ports and one synchronous write port — the
building block a 5-stage pipeline's Decode stage reads from and the
Writeback stage writes to.

## Design notes
- **x0 is hardwired to zero**, per the RV32I spec: reads always return
  0 regardless of what was ever written, and writes to x0 are silently
  dropped. x0 isn't even given a storage element in `regs[]` — the
  array is declared `[1:NUM_REGS-1]`, and the read/write ports
  explicitly special-case address 0.
- **Two read ports, one write port**: real pipelines need `rs1` and
  `rs2` (the two source operands) available combinationally in the
  same cycle Decode reads them.
- **Write-through (same-cycle) forwarding on the read ports**: if an
  instruction in Writeback is writing to the same register another
  instruction in Decode is reading this same cycle, the read port
  returns the new value being written, not the stale value about to be
  overwritten. Without this, a naive register file creates a spurious
  1-cycle read-after-write hazard even though real RV32I pipelines
  resolve this exact case for free at the register file (no forwarding
  network or stall needed for this specific case).

## Files
```
rtl/riscv_regfile.v
tb/tb_riscv_regfile.v   - self-checking testbench, 37 test cases
```

## Simulation (Icarus Verilog)
```bash
iverilog -o sim rtl/riscv_regfile.v tb/tb_riscv_regfile.v
vvp sim
```
37 tests: x0 hardwired-zero behavior (including that writes to x0 are
silently ignored), basic write/read-back, reading the same register on
both ports simultaneously, same-cycle write-through forwarding, and a
full sweep writing and reading back all 31 real registers (x1–x31)
with unique values to catch any address aliasing. All 37 pass.

## Where this fits
This register file is designed to plug directly into a Decode stage
(reads `rs1`/`rs2` from the instruction) and a Writeback stage (drives
`rd_addr`/`rd_data`/`reg_write`) — the next natural step from here is
the instruction decoder and, eventually, the full 5-stage RV32I core.
