    addi x1, x0, -8
    addi x2, x0, 3
    add x3, x1, x2
    sub x4, x2, x1
    and x5, x1, x2
    or x6, x1, x2
    xor x7, x1, x2
    sll x8, x2, x2
    srl x9, x1, x2
    sra x10, x1, x2
    slt x11, x1, x2
    sltu x12, x1, x2
    slli x13, x2, 31
    srli x14, x13, 31
    srai x15, x13, 31
    xori x16, x1, -1
    ori x17, x0, 0x55
    andi x18, x1, 15
    slti x19, x1, 0
    sltiu x20, x1, 1
    lui x21, 0xabcde
    auipc x22, 1
    addi x0, x0, 123
    addi x23, x0, 0
    beq x1, x2, fail
    bne x1, x2, b1
    jal x0, fail
b1:
    blt x1, x2, b2
    jal x0, fail
b2:
    bge x2, x1, b3
    jal x0, fail
b3:
    bltu x2, x1, b4
    jal x0, fail
b4:
    bgeu x1, x2, b5
    jal x0, fail
b5:
    beq x2, x2, loop_init
    jal x0, fail
loop_init:
    addi x24, x0, 3
loop:
    addi x23, x23, 1
    addi x24, x24, -1
    bne x24, x0, loop
    jal x25, jump_target
    jal x0, fail
jump_target:
    auipc x26, 0
    addi x26, x26, 13
    jalr x27, 0(x26)
    addi x28, x0, 0x123
    jal x0, done
fail:
    addi x28, x0, -1
    jal x0, fail
done:
    jal x0, done
