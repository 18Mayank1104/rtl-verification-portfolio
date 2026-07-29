# 8-bit ALU

A parameterized 8-bit combinational ALU supporting arithmetic, logic, and
shift operations, with zero/carry/overflow flag generation.

## Operations

| op_sel | Operation |
|--------|-----------|
| 000    | ADD       |
| 001    | SUB       |
| 010    | AND       |
| 011    | OR        |
| 100    | XOR       |
| 101    | NOT (of `a`) |
| 110    | Shift left (`a << b`) |
| 111    | Shift right (`a >> b`) |

## Flags
- **zero**     — asserted when `result == 0`
- **carry**    — carry-out on ADD, borrow on SUB, shifted-out bit on shifts
- **overflow** — signed overflow, valid for ADD/SUB only

## Files
```
rtl/alu.v        - ALU design
tb/tb_alu.v       - self-checking testbench (11 directed test cases)
```

## Simulation (Icarus Verilog)
```bash
iverilog -o sim rtl/alu.v tb/tb_alu.v
vvp sim
```
All 11 tests pass, covering normal arithmetic, wraparound, borrow,
all logic ops, both shift directions, and the zero-flag edge case.
