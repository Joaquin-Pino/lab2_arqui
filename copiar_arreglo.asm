.data

	arreglo: .word 1,2,3,4,5,6,7,8
.text


main:
	la $t0, arreglo
	la $t1, 0x10010080
	
	li $t2, 0
	
loop:
	beq $t2, 8, pre_print
	
	sll $t6, $t2, 2
	add $t3, $t6, $t1 # puntero arreglo copia
	add $t4, $t6, $t0 # puntero arreglo original
	
	lw $t5, 0($t4)
	
	sw $t5, 0($t3)
	
	addi $t2, $t2, 1
	j loop

pre_print:
	li $t2, 0

print_loop:
	beq $t2, 8, exit
	
	sll $t3, $t2, 2
	
	add $t4, $t3, $t1
	
	lw $a0, 0($t4)
	li $v0, 1
	syscall
	
	addi $t2, $t2, 1
	j print_loop

exit:
	li $v0, 10
    syscall


