# SPI Master/Slave

A full-duplex, 8-bit SPI Master and Slave pair implementing Mode 0
(CPOL=0, CPHA=0): data is sampled on the rising edge of SCLK and
shifted out on the falling edge.

## Architecture
- **spi_master.v** — generates SCLK from the system clock via a
  configurable divider (`CLK_DIV`), drives `SS_N` low for the duration
  of the transfer, and shifts `tx_data` out MSB-first on MOSI while
  simultaneously capturing MISO into `rx_data`.
- **spi_slave.v** — fully clock-synchronous design that double-flop
  synchronizes SCLK/SS_N (treated as async inputs from the master),
  edge-detects SCLK internally, samples MOSI on the rising edge and
  drives MISO on the falling edge, and pre-loads the next TX byte
  when SS_N deasserts.

## Files
```
rtl/spi_master.v
rtl/spi_slave.v
tb/tb_spi.v       - self-checking master<->slave loopback testbench
```

## Simulation (Icarus Verilog)
```bash
iverilog -o sim rtl/spi_master.v rtl/spi_slave.v tb/tb_spi.v
vvp sim
```
Verifies simultaneous bidirectional transfer (master and slave each
send/receive a different byte in the same transaction) across 5 test
vectors — all pass, confirming both the master-to-slave and
slave-to-master paths independently.

## Debug note
An early version double-counted the final received bit on the master
side (`rx_data <= {shift_in[6:0], miso}` instead of `rx_data <= shift_in`),
since by the last falling edge all 8 bits were already captured in
`shift_in` on the preceding rising edges. Caught via simulation
mismatch on the loopback testbench — worth knowing this class of
off-by-one is common in shift-register-based serial protocols.

## Possible extensions
- CPOL/CPHA parameterization for all 4 SPI modes
- Multi-slave support with a slave-select decoder
- FIFO-buffered continuous transfers
