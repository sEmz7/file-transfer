    addi x1, x0, 0x60
    csrrw x0, mtvec, x1
    addi x2, x0, 5
    csrrw x0, mscratch, x2
    lui x3, 0x10
    csrrw x0, mie, x3
interrupted:
    csrrwi x4, mscratch, 9
    csrrs x5, mscratch, x0
done:
    jal x0, done
.org 0x60
handler:
    csrrs x20, mscratch, x0
    csrrs x21, mcause, x0
    mret
