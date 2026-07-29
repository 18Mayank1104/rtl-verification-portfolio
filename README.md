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

More modules (Synchronous/Asynchronous FIFO, APB Slave, AXI4-Lite Slave,
RISC-V Register File) coming next as this portfolio grows.

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
