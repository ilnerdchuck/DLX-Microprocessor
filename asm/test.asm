nop
addi r1,r1,#5
lw r2, 4(r1)
addi r2,r1,#1
sw 8(r1), r2
lw r3, 8(r1)
addi r6,r3,#1
jal target
addi r1,r6,#6
addi r1,r2,#5
target:
add r1,r2,#1
addi r1,r2,#2
sub r1,r2,r3
subi r1,r2,#5
and r1,r3,r1
andi r1,r3,#15
or r1,r3,r1
ori r1,r3,#4
xor r1,r1,r1
xori r1,r3,#3
sne r1,r2,r3
snei r1,r2,#4
sle r1,r2,r5
slei r1,r2,#10
sge r1,r2,r10
slli r1,r2,#5
srli r1,r2,#3
beqz r5,target