# UART Controller (TX + RX)

An 8N1 UART transmitter and receiver pair with a shared 16x-oversampling
baud rate generator, verified via loopback (TX output tied to RX input).

## Architecture
- **baud_gen.v** — generates a `tick_16x` pulse at 16x the configured baud
  rate, derived from `CLK_FREQ` and `BAUD_RATE` parameters.
- **uart_tx.v** — 4-state FSM (IDLE → START → DATA → STOP) that shifts out
  8 data bits LSB-first, framed by a start bit (0) and stop bit (1).
- **uart_rx.v** — synchronizes the incoming line with a 2-flop synchronizer,
  detects the start bit, and samples each bit at its temporal midpoint
  using the 16x tick for reliable recovery. Flags framing errors if the
  stop bit isn't seen as 1.

## Files
```
rtl/baud_gen.v
rtl/uart_tx.v
rtl/uart_rx.v
tb/tb_uart.v      - self-checking loopback testbench
```

## Simulation (Icarus Verilog)
```bash
iverilog -o sim rtl/baud_gen.v rtl/uart_tx.v rtl/uart_rx.v tb/tb_uart.v
vvp sim
```
Default config: 50 MHz clock, 115200 baud. Sends 5 test bytes
(0x55, 0xA5, 0x00, 0xFF, 0x3C) through TX and checks the byte
recovered by RX for correctness — all 5 pass.

## Possible extensions
- Parameterizable data/parity/stop-bit configuration (8E1, 8O2, etc.)
- FIFO-buffered TX/RX for back-to-back byte streaming
- APB/AXI-Lite register wrapper for SoC integration
