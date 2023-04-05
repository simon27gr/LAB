.text
.align 4
.global fact

fact:
add x10,x0,x0
addi x12,x0,12
addi x13,x0,13
addi x14,x0,14

add x10,x12,x13
mul x15,x10,x14

done:
       jr ra 
