# RTL Design Portfolio

A collection of industry-relevant RTL modules built and verified with
self-checking testbenches (simulated in Icarus Verilog). Each project
folder is self-contained with its own RTL, testbench, and README.

## Projects

| # | Project | Status |
|---|---------|--------|
| 01 | [8-bit ALU](./01_alu) | ✅ 11/11 tests passing |
| 02 | [UART Controller (TX/RX)](./02_uart) | ✅ 5/5 tests passing |
| 03 | [SPI Master/Slave](./03_spi) | ✅ 5/5 tests passing |
| 04 | [Synchronous FIFO](./04_sync_fifo) | ✅ 24/24 tests passing |
| 05 | [Asynchronous FIFO (dual clock, Gray-code CDC)](./05_async_fifo) | ✅ 40/40 tests passing |
| 06 | [APB Slave](./06_apb_slave) | ✅ 11/11 tests passing |
| 07 | [AXI4-Lite Slave](./07_axi4lite_slave) | ✅ 13/13 tests passing |
| 08 | [RISC-V RV32I Register File](./08_riscv_regfile) | ✅ 37/37 tests passing |
| 09 | [RISC-V RV32I Instruction Decoder](./09_riscv_decoder) | ✅ 14/14 tests passing |
| 10 | [RISC-V CSR Block](./10_riscv_csr) | ✅ 9/9 tests passing |
| 11 | [RV32I Single-Cycle Core](./11_riscv_core) | ✅ 23/23 tests passing |

Core RTL thread complete: register file → decoder → CSR block → full
single-cycle core running a hand-assembled test program. Next up:
UVM verification testbenches for a few of the earlier projects
(ALU, FIFO, APB).

## Tools
- Icarus Verilog (`iverilog`/`vvp`) for compilation and simulation
- GTKWave (optional) for waveform inspection

## Structure
```
<project>/
  rtl/    - synthesizable design files
  tb/     - self-checking testbench
  README.md - design notes, port list, and how to simulate
```

## Author
Mayank Chaudhary — B.Tech ECE, MANIT Bhopal
