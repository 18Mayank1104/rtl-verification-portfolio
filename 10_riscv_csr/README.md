# RISC-V CSR (Control and Status Register) Block

Implements the Zicsr extension's read-modify-write semantics for a
small set of standard machine-mode CSRs — enough to support basic trap
handling in an RV32I core: `mstatus`, `mie`, `mtvec`, `mepc`, `mcause`,
`mtval`, `mip`.

## Design notes
- All six CSR instructions (`CSRRW`/`CSRRS`/`CSRRC` and their `-I`
  immediate variants) collapse to the same hardware shape: read the
  old value out (destined for `rd`), then write a new value computed
  from it and an operand. This block only takes a 2-bit `csr_op`
  (WRITE / SET / CLEAR) — the upstream decoder is responsible for
  picking `rs1` vs. a zero-extended 5-bit immediate as the operand,
  which is identical logic either way from the CSR block's point of
  view.
- **Trap entry** (`trap_enter`) is a separate hardware-driven path
  that captures `mepc`/`mcause`/`mtval` and clears the `MIE` bit in
  `mstatus`, and takes priority over a concurrent CSR instruction —
  matches real hardware, since a trap firing means the pipeline is
  being flushed, so no CSR instruction is actually retiring that same
  cycle.
- Unmapped CSR addresses read back `0` with `csr_valid=0`, and writes
  to them are silent no-ops (don't corrupt any real CSR).

## Files
```
rtl/riscv_csr.v
tb/tb_riscv_csr.v   - self-checking testbench, 9 test cases
```

## Simulation (Icarus Verilog)
```bash
iverilog -o sim rtl/riscv_csr.v tb/tb_riscv_csr.v
vvp sim
```
9 tests: WRITE/SET/CLEAR RMW operations, an unmapped-address read,
an unmapped-address write correctly being a no-op, hardware trap entry
capturing `mepc`/`mcause`/`mtval`, and the MIE-bit-clear-on-trap check.
All 9 pass.

## Debug note
The MIE-clear-on-trap line used a positional concatenation,
`{mstatus[31:8], 1'b0, mstatus[6:0]}`, intending to force bit 3 to
zero. But counting the concatenation positions: 24 bits
(`[31:8]`) + 1 bit + 7 bits (`[6:0]`) places that forced zero at
**bit 7**, not bit 3 — it silently clobbered a different, unrelated
status bit instead of the one intended. The testbench caught it
immediately (expected `0x80`, got `0x00`) because it checked the
*specific* bit pattern after the trap rather than just "some bits
changed." Fixed by re-deriving the split as `[31:4]` + 1 bit + `[2:0]`
so the forced zero lands exactly on bit 3. A reminder that positional
concatenation for single-bit clears is easy to get subtly wrong —
worth double-checking the bit-width arithmetic every time, or using
an explicit bit-clear (`mstatus & ~32'h8`) instead, which is harder to
miscount.

## Where this fits
Alongside the [Register File](../08_riscv_regfile) and
[Instruction Decoder](../09_riscv_decoder), this is the third
core building block for a working RV32I datapath — next step is
wiring all three together (plus the ALU) into a single-cycle or
5-stage core with basic trap/exception support.
