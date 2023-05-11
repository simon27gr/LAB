.text
.align 4
.global fact

fact:

addi x2, x0, 0
addi x10,x0,14
addi x11,x0,13
addi x12,x0,12
addi x1,x0,69
addi x17,x0,10
addi x18,x0,27
addi x21,x0,69
addi x5,x0,69


sw  x1, 4(x2)
add x10,x11,x12
sub x15,x10,x17
lw  x8,4(x2)
mul x16,x8,x18
srl x17,x10,x21

done:
       jr ra 
