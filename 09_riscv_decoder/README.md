# RISC-V RV32I Instruction Decoder

Decodes a 32-bit RV32I instruction word into its raw fields (opcode,
rd, funct3, rs1, rs2, funct7), a correctly sign-extended immediate for
every RV32I instruction format, and the standard Decode-stage control
signals a pipeline datapath consumes.

## Instruction formats handled

| Format | Instructions | Immediate layout |
|--------|--------------|-------------------|
| R | ADD/SUB/AND/OR/XOR/SLT/SLL/SRL/SRA | none |
| I | ADDI/SLTI/ANDI/ORI/XORI/SLLI/SRLI/SRAI, loads, JALR | `instr[31:20]`, sign-extended |
| S | SB/SH/SW | `instr[31:25]` + `instr[11:7]`, sign-extended |
| B | BEQ/BNE/BLT/BGE/BLTU/BGEU | `instr[31\|7\|30:25\|11:8]`, LSB implicit 0 |
| U | LUI, AUIPC | `instr[31:12]` << 12 |
| J | JAL | `instr[31\|19:12\|20\|30:21]`, LSB implicit 0 |

The B-type and J-type immediates use RISC-V's deliberately scrambled
bit layout (chosen by the ISA designers to minimize hardware — it
keeps the sign bit in the same position, `instr[31]`, across every
format). Getting this bit-reordering exactly right, in both the RTL
*and* independently in the testbench's instruction encoder, is the
easiest place to introduce a silent bug in a RISC-V decoder — which
is exactly why the testbench builds real encoded instructions rather
than just checking the decode logic against itself.

## Control signals produced
`reg_write`, `alu_src` (ALU operand B: register vs immediate),
`mem_read`, `mem_write`, `mem_to_reg` (writeback source: ALU vs
memory), `branch`, `jump`, and `invalid` (unrecognized opcode).

## Files
```
rtl/riscv_decoder.v
tb/tb_riscv_decoder.v   - self-checking testbench with real instruction encodings
```

## Simulation (Icarus Verilog)
```bash
iverilog -o sim rtl/riscv_decoder.v tb/tb_riscv_decoder.v
vvp sim
```
14 tests, one (or more) per instruction format: ADD/SUB (R-type),
ADDI with a negative immediate, LW (load), SW with a negative offset
(store), BEQ and BNE with a negative branch offset, JAL, JALR, LUI,
AUIPC, and an unrecognized-opcode case. All 14 pass.

## Where this fits
Feeds directly into the [RISC-V Register File](../08_riscv_regfile) —
`rs1`/`rs2`/`rd` here are exactly the address inputs that module's read
and write ports expect. Next natural step: a CSR block, then wiring
decoder + register file + ALU together into a working single-cycle or
5-stage RV32I datapath.
