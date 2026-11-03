# Variant 21: sum the four nibbles of sw_i[15:0].
# For the RISC-V version sw_i is a constant; result is returned in x10.
# sw_i = 0x1230 -> 0 + 3 + 2 + 1 = 6.
    lui  x1, 0x1
    addi x1, x1, 0x230
    andi x10, x1, 15
    srli x2, x1, 4
    andi x2, x2, 15
    add  x10, x10, x2
    srli x2, x1, 8
    andi x2, x2, 15
    add  x10, x10, x2
    srli x2, x1, 12
    andi x2, x2, 15
    add  x10, x10, x2
    sw   x10, 0(x0)
done:
    jal  x0, done
