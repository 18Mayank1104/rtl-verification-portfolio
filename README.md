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
| 12 | [ALU — UVM Verification](./12_alu_uvm) | ⚠️ Needs Questa/VCS/Xcelium — see README |
| 13 | [Synchronous FIFO — UVM Verification](./13_fifo_uvm) | ⚠️ Needs Questa/VCS/Xcelium — see README |
| 14 | [APB Slave — UVM Verification](./14_apb_uvm) | ⚠️ Needs Questa/VCS/Xcelium — see README |

Core RTL thread complete: register file → decoder → CSR block → full
single-cycle core running a hand-assembled test program.

Projects 12-14 are real UVM 1.2/IEEE 1800.2 testbenches (transaction,
sequence, driver, monitor, independent-reference-model scoreboard,
functional coverage, agent/env/test) for the ALU, FIFO, and APB
projects above. **Icarus Verilog cannot run the real UVM class
library** (confirmed by directly testing the Accellera UVM source
against it — a documented open-source-simulator limitation, not a bug
in this code), so unlike every other project here, these aren't
simulator-verified in this repo. Each one's README has exact steps to
run and verify them for free on
[EDA Playground](https://www.edaplayground.com/) (Questa/Xcelium).

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
