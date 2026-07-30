# Synchronous FIFO

A parameterized single-clock-domain FIFO using the standard extra-MSB
pointer trick to distinguish full from empty without a separate counter
comparison (though a `fifo_count` output is also provided for convenience).

## Design notes
- `wr_ptr` / `rd_ptr` are `ADDR_WIDTH+1` bits wide — one bit wider than
  needed to address the memory. The extra MSB tracks how many times each
  pointer has wrapped around the memory array.
- **empty**: `wr_ptr == rd_ptr` (both address and wrap bit match)
- **full**: same lower address bits, but differing wrap (MSB) bit —
  meaning the write pointer has lapped the read pointer exactly once
- Writes are dropped when `full`, reads are dropped when `empty`
  (no error flag; caller is expected to check `full`/`empty` before
  issuing a transaction, standard FIFO convention)

## Files
```
rtl/sync_fifo.v
tb/tb_sync_fifo.v   - self-checking testbench, reference-queue model
```

## Simulation (Icarus Verilog)
```bash
iverilog -o sim rtl/sync_fifo.v tb/tb_sync_fifo.v
vvp sim
```
24 tests covering: basic write/read ordering, full-flag assertion after
filling all 16 entries, empty-flag assertion after a full drain, and
overflow protection (write attempted while full is correctly dropped).
All 24 pass.
