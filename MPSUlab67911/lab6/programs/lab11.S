# Original lab 10/11 demonstration, without pseudo-instructions.
    addi x2, x0, 0x1f0
    addi x3, x0, 0
    addi x5, x0, 0x38
    csrrw x0, mtvec, x5
    addi x5, x0, 0xf0
    csrrw x0, mscratch, x5
    addi x5, x0, -1
    csrrw x0, mie, x5
    addi x5, x0, 1
    sw x5, 0(x3)
    addi x6, x0, 0
    addi x7, x0, 0
    ecall
main:
    beq x0, x0, main
trap_handler:
    csrrw x2, mscratch, x2
    addi x2, x2, -16
    sw x6, 0(x2)
    sw x7, 4(x2)
    csrrs x6, mcause, x0
    lui x7, 0x80000
    addi x7, x7, 16
    bne x6, x7, exc_handler
    lw x7, 0(x3)
    addi x7, x7, 3
    sw x7, 0(x3)
    jal x0, done
exc_handler:
    addi x7, x0, 2
    bne x6, x7, done
    csrrs x6, mepc, x0
    lw x7, 0(x6)
    addi x6, x6, 4
    csrrw x0, mepc, x6
    jal x0, done
done:
    lw x6, 0(x2)
    lw x7, 4(x2)
    addi x2, x2, 16
    csrrw x2, mscratch, x2
    mret
