# RV32I Single-Cycle Core

Wires the [Register File](../08_riscv_regfile), [Instruction Decoder](../09_riscv_decoder),
and a purpose-built ALU together with instruction/data memories into a
working single-cycle datapath that executes real RV32I programs.

**Single-cycle by design** (not pipelined) — this is the
integration/correctness milestone that proves all the individually
verified sub-blocks actually work together end-to-end. A 5-stage
pipelined version with hazard detection/forwarding is the natural,
larger next project built on top of these same blocks.

## Covers
R-type ALU ops, I-type ALU ops, loads (LB/LH/LW/LBU/LHU), stores
(SB/SH/SW), all 6 branches, JAL, JALR, LUI, AUIPC. (CSR/trap
instructions from [project 10](../10_riscv_csr) aren't wired in yet —
noted as a follow-on.)

## Architecture
```
        ┌─────────┐    ┌─────────┐    ┌───────────┐
   PC ─▶│  imem   │───▶│ decoder │───▶│ regfile   │
        └─────────┘    └─────────┘    │ (rs1,rs2) │
             ▲                        └─────┬─────┘
             │                              │
        pc_next                      ┌──────▼──────┐
     (branch/jump/+4)                │     ALU     │──▶ dmem addr
                                      └──────┬──────┘
                                             │
                                      writeback mux ◀── dmem rdata
                                     (ALU / mem / PC+4 / imm / PC+imm)
```
- `riscv_alu.v` is a **new** ALU (not the [8-bit ALU project](../01_alu)) —
  RV32I needs SLT/SLTU and a full 5-bit shift amount (0-31), neither
  of which the simpler 8-bit design supports.
- `riscv_imem.v` / `riscv_dmem.v` are simple word/byte-addressable
  memories; instruction memory is loaded via `$readmemh` from
  `program.hex`, mirroring how a real flow loads a compiled program
  image.
- Branch comparisons (`BLT`/`BGE`/`BLTU`/`BGEU`) are computed with
  dedicated signed/unsigned comparators rather than reusing the ALU's
  SLT/SLTU — keeps the ALU's job limited to what the instruction
  actually asks it to compute, and the branch decision independent of
  it (matches how most real single-cycle designs separate the two).

## Test program (`tb/program.hex`)
Hand-assembled (not compiled by a toolchain) to exercise every
instruction class. Equivalent assembly:
```asm
0:  addi x1, x0, 5          # x1 = 5
1:  addi x2, x0, 10         # x2 = 10
2:  add  x3, x1, x2         # x3 = 15
3:  sub  x4, x2, x1         # x4 = 5
4:  sw   x3, 0(x0)          # mem[0..3] = 15
5:  lw   x5, 0(x0)          # x5 = 15
6:  beq  x3, x5, 8          # taken -> skip instr 7
7:  addi x6, x0, 99         # SKIPPED
8:  addi x7, x0, 7          # branch target
9:  jal  x8, 8              # x8 = link addr, jump -> skip instr 10
10: addi x9, x0, 55         # SKIPPED
11: addi x10, x0, 11        # jump target
12: slt  x11, x1, x2        # 5 < 10 signed -> 1
13: sltu x12, x2, x1        # 10 < 5 unsigned -> 0
14: and  x13, x3, x4        # 15 & 5 = 5
15: or   x14, x3, x4        # 15 | 5 = 15
16: xor  x15, x3, x4        # 15 ^ 5 = 10
17: sll  x16, x1, x1        # 5 << 5 = 160
18: srl  x17, x16, x1       # 160 >> 5 = 5
19: lui  x18, 0x12345       # x18 = 0x12345000
20: auipc x19, 0x1          # x19 = pc(80) + 0x1000 = 0x1050
21: sb   x3, 4(x0)          # mem[4] = 15
22: lbu  x20, 4(x0)         # x20 = 15
23: jal  x0, 0               # self-loop (halt)
```

## Files
```
rtl/riscv_regfile.v   - reused from project 08
rtl/riscv_decoder.v   - reused from project 09
rtl/riscv_alu.v       - new: RV32I-correct ALU (SLT/SLTU, 5-bit shifts)
rtl/riscv_imem.v      - instruction memory ($readmemh-loaded)
rtl/riscv_dmem.v      - byte-addressable data memory
rtl/riscv_core.v      - top-level datapath integration
tb/program.hex        - hand-assembled test program
tb/tb_riscv_core.v    - self-checking testbench
```

## Simulation (Icarus Verilog)
Must be run from the `tb/` directory so `$readmemh` finds `program.hex`
via its relative path:
```bash
cd tb
iverilog -o sim ../rtl/riscv_regfile.v ../rtl/riscv_decoder.v ../rtl/riscv_alu.v \
                ../rtl/riscv_imem.v ../rtl/riscv_dmem.v ../rtl/riscv_core.v tb_riscv_core.v
vvp sim
```
23 checks: every register the program touches (including confirming
the two *skipped* instructions never wrote their registers, proving
branch and jump control flow actually worked, not just that the
straight-line arithmetic was right), plus 3 data memory checks for
the word store and byte store. All 23 pass.

## Where this fits
This is the payoff of the whole RISC-V thread in this portfolio:
[register file](../08_riscv_regfile) → [decoder](../09_riscv_decoder) →
[CSR block](../10_riscv_csr) → this core, wiring the verified pieces
into something that actually runs a program. Natural next steps: wire
in the CSR block for `ECALL`/trap support, then pipeline it into a
5-stage core with forwarding and hazard detection.
