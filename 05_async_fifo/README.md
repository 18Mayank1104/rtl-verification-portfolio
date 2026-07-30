# Asynchronous FIFO (Dual Clock Domain)

A CDC-safe FIFO for crossing data between two independent, unrelated
clock domains — the classic Clifford Cummings design using Gray-coded
pointers and 2-flop synchronizers.

## Why Gray code?
A binary pointer can have multiple bits change simultaneously when it
increments (e.g. `0111 -> 1000`). If that multi-bit transition is sampled
mid-change by a synchronizer in another clock domain, the metastability
resolution can land on a completely wrong value, not just an off-by-one.
Gray code guarantees only **one bit** ever changes between consecutive
values, so even if a synchronizer catches the pointer mid-transition,
the worst case is being one cycle stale — never a garbage value.

## Design notes
- Each domain keeps its own **binary** pointer (for addressing memory)
  and a derived **Gray-coded** pointer (the only thing sent across the
  clock boundary).
- Each domain double-flops (`_sync0` / `_sync1`) the *other* domain's
  Gray pointer before using it — the standard 2-stage synchronizer to
  bring MTBF for metastability down to negligible levels.
- **empty** (read domain): read pointer (Gray) equals the synchronized
  write pointer (Gray) — read domain has caught up to what it has seen
  written so far.
- **full** (write domain): next write pointer (Gray) equals the
  synchronized read pointer (Gray) with the top two bits inverted —
  the standard Gray-code comparison that detects the write pointer
  having lapped the read pointer by exactly one full cycle.

## Files
```
rtl/async_fifo.v
tb/tb_async_fifo.v   - self-checking testbench, two independent clocks
```

## Simulation (Icarus Verilog)
```bash
iverilog -o sim rtl/async_fifo.v tb/tb_async_fifo.v
vvp sim
```
Testbench runs the write side at 100 MHz and the read side at ~58.8 MHz
(deliberately unrelated frequencies, not integer multiples of each
other) to genuinely exercise the CDC synchronizers rather than getting
lucky with aligned edges. 40 words pushed through and checked against
a reference queue for both correctness and order — all 40 pass.
