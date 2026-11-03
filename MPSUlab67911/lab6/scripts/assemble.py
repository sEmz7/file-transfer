#!/usr/bin/env python3
"""Small RV32I/Zicsr assembler for the bundled lab programs (no pseudo-ops)."""
import argparse
import re
from pathlib import Path

CSR = {"mie": 0x304, "mtvec": 0x305, "mscratch": 0x340,
       "mepc": 0x341, "mcause": 0x342}
R_OPS = {"add": (0, 0), "sub": (0, 32), "sll": (1, 0),
         "slt": (2, 0), "sltu": (3, 0), "xor": (4, 0),
         "srl": (5, 0), "sra": (5, 32), "or": (6, 0), "and": (7, 0)}
I_OPS = {"addi": 0, "slti": 2, "sltiu": 3, "xori": 4, "ori": 6, "andi": 7}
LOADS = {"lb": 0, "lh": 1, "lw": 2, "lbu": 4, "lhu": 5}
STORES = {"sb": 0, "sh": 1, "sw": 2}
BRANCHES = {"beq": 0, "bne": 1, "blt": 4, "bge": 5, "bltu": 6, "bgeu": 7}
CSRS = {"csrrw": 1, "csrrs": 2, "csrrc": 3,
        "csrrwi": 5, "csrrsi": 6, "csrrci": 7}


def reg(value):
    if not re.fullmatch(r"x(?:[0-9]|[12][0-9]|3[01])", value):
        raise ValueError("Expected register x0..x31: " + value)
    return int(value[1:])


def number(value):
    return int(value, 0)


def signed(value, bits):
    if not -(1 << (bits - 1)) <= value < (1 << (bits - 1)):
        raise ValueError(f"Immediate {value} does not fit signed {bits} bits")
    return value & ((1 << bits) - 1)


def assemble(source):
    labels, instructions = {}, []
    pc = 0
    for line_no, raw in enumerate(source.splitlines(), 1):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        if ":" in line:
            label, line = line.split(":", 1)
            if label.strip() in labels:
                raise ValueError("Duplicate label: " + label)
            labels[label.strip()] = pc
            line = line.strip()
        if not line:
            continue
        if line.startswith(".org "):
            target = number(line.split()[1])
            if target < pc or target % 4:
                raise ValueError(".org must move forward to a word boundary")
            while pc < target:
                instructions.append((pc, line_no, "addi x0, x0, 0"))
                pc += 4
            continue
        instructions.append((pc, line_no, line))
        pc += 4

    words = []
    for pc, line_no, line in instructions:
        try:
            op, *a = [t for t in re.split(r"[\s,()]+", line) if t]
            if op == ".word":
                word = number(a[0])
                if not 0 <= word <= 0xffffffff:
                    raise ValueError(".word must fit 32 bits")
            elif op in R_OPS:
                f3, f7 = R_OPS[op]
                word = (f7 << 25) | (reg(a[2]) << 20) | (reg(a[1]) << 15) | (f3 << 12) | (reg(a[0]) << 7) | 0x33
            elif op in I_OPS:
                word = (signed(number(a[2]), 12) << 20) | (reg(a[1]) << 15) | (I_OPS[op] << 12) | (reg(a[0]) << 7) | 0x13
            elif op in ("slli", "srli", "srai"):
                shift = number(a[2])
                if not 0 <= shift < 32:
                    raise ValueError("Shift must be in 0..31")
                imm = shift | (0x400 if op == "srai" else 0)
                word = (imm << 20) | (reg(a[1]) << 15) | ((1 if op == "slli" else 5) << 12) | (reg(a[0]) << 7) | 0x13
            elif op in ("lui", "auipc"):
                imm = number(a[1])
                if not 0 <= imm < (1 << 20):
                    raise ValueError("Upper immediate must fit 20 bits")
                word = (imm << 12) | (reg(a[0]) << 7) | (0x37 if op == "lui" else 0x17)
            elif op in LOADS or op == "jalr":
                word = (signed(number(a[1]), 12) << 20) | (reg(a[2]) << 15) | ((LOADS[op] if op in LOADS else 0) << 12) | (reg(a[0]) << 7) | (3 if op in LOADS else 0x67)
            elif op in STORES:
                imm = signed(number(a[1]), 12)
                word = ((imm >> 5) << 25) | (reg(a[0]) << 20) | (reg(a[2]) << 15) | (STORES[op] << 12) | ((imm & 31) << 7) | 0x23
            elif op in BRANCHES or op == "jal":
                dest = a[-1]
                offset = labels[dest] - pc if dest in labels else number(dest)
                if offset % 2:
                    raise ValueError("Branch/jump displacement must be even")
                imm = signed(offset, 21 if op == "jal" else 13)
                if op == "jal":
                    word = (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3ff) << 21) | (((imm >> 11) & 1) << 20) | (((imm >> 12) & 0xff) << 12) | (reg(a[0]) << 7) | 0x6f
                else:
                    word = (((imm >> 12) & 1) << 31) | (((imm >> 5) & 63) << 25) | (reg(a[1]) << 20) | (reg(a[0]) << 15) | (BRANCHES[op] << 12) | (((imm >> 1) & 15) << 8) | (((imm >> 11) & 1) << 7) | 0x63
            elif op in CSRS:
                addr = CSR[a[1]] if a[1] in CSR else number(a[1])
                value = reg(a[2]) if CSRS[op] < 5 else number(a[2])
                if not 0 <= addr < 4096 or not 0 <= value < 32:
                    raise ValueError("Invalid CSR address/source")
                word = (addr << 20) | (value << 15) | (CSRS[op] << 12) | (reg(a[0]) << 7) | 0x73
            elif op in ("mret", "ecall", "ebreak"):
                word = {"mret": 0x30200073, "ecall": 0x73, "ebreak": 0x100073}[op]
            else:
                raise ValueError("Unsupported instruction: " + op)
            words.append(word)
        except (ValueError, IndexError, KeyError) as error:
            raise ValueError(f"Line {line_no}: {line}: {error}") from error
    if len(words) > 128:
        raise ValueError("Program exceeds the lab's 512-byte instruction memory")
    return words


def write_image(source, target):
    words = assemble(Path(source).read_text(encoding="utf-8"))
    Path(target).write_text("".join(f"{word:08x}\n" for word in words))
    return len(words)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    print(f"Assembled {write_image(args.source, args.output)} instructions -> {args.output}")
