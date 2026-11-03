    lui x1, 0x80ff8
    addi x1, x1, -255
    sw x1, 0(x0)
    lb x2, 0(x0)
    lb x3, 1(x0)
    lb x4, 2(x0)
    lb x5, 3(x0)
    lbu x6, 2(x0)
    lbu x7, 3(x0)
    lh x8, 0(x0)
    lh x9, 2(x0)
    lhu x10, 2(x0)
    lw x11, 0(x0)
    addi x12, x0, 165
    sb x12, 1(x0)
    addi x12, x0, -1
    sh x12, 2(x0)
    lw x13, 0(x0)
    sw x13, 4(x0)
    lw x14, 4(x0)
    addi x15, x0, 42
    sw x15, 8(x0)
    lw x15, 8(x0)
    addi x16, x15, 1
done:
    jal x0, done
