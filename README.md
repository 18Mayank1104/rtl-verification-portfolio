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

More modules (AXI4-Lite Slave, RISC-V Register File) coming next as
this portfolio grows.

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
