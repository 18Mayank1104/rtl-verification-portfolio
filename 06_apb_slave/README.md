# APB Slave

An AMBA3 APB (Advanced Peripheral Bus) protocol slave wrapping a small
word-addressable register file, with `PSLVERR` support for out-of-range
addresses.

## Protocol recap
APB transfers happen in two phases:
- **SETUP**: master asserts `PSEL=1`, `PENABLE=0`, with address/data
  already valid — held for exactly one clock cycle.
- **ACCESS**: master asserts `PENABLE=1` (address/data unchanged) on the
  *next* clock edge. The slave samples/drives during this phase and must
  assert `PREADY` once the transfer can complete (immediately, for a
  zero-wait-state slave like this one).

## Design notes
- No internal state machine is needed: since `PADDR`/`PWDATA`/`PWRITE`
  are guaranteed stable across both SETUP and ACCESS by the protocol,
  `PREADY`, `PSLVERR`, and `PRDATA` are all pure combinational functions
  of `PSEL && PENABLE` (i.e. "are we in the ACCESS phase right now").
- Register writes are clocked, gated by `access && pwrite && addr_valid`.
- Out-of-range addresses (`word_addr >= NUM_REGS`) assert `PSLVERR` and
  return `0` on reads; writes to them are silently dropped (no memory
  corruption).

## Files
```
rtl/apb_slave.v
tb/tb_apb_slave.v   - self-checking testbench with an APB master BFM
```

## Simulation (Icarus Verilog)
```bash
iverilog -o sim rtl/apb_slave.v tb/tb_apb_slave.v
vvp sim
```
11 tests: write+read-back of every valid register, a register overwrite,
an out-of-range-address `PSLVERR` check, and a check that an out-of-range
write doesn't corrupt valid registers. All 11 pass.

## Debug note
The first version of this design used an explicit 2-state
IDLE/ACCESS FSM that transitioned to ACCESS (and asserted PREADY) on
the same clock edge the SETUP phase was first observed — one full
cycle *before* the master had actually raised PENABLE. This is a
subtle but real protocol violation: it worked by accident with sloppy
testbench timing, but a proper APB master BFM driving stimulus on the
correct clock edges caught it immediately as a mismatch (and, in an
earlier iteration, as an outright simulation hang caused by a
testbench/DUT race — both signals reacting to the same clock edge).
Switching to pure combinational logic keyed off `PSEL && PENABLE`
removed the extra state and the timing bug along with it.
