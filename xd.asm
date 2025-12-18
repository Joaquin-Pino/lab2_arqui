.data
	largo_arreglo: .asciiz "Ingrese la cantidad de numeros (de 1 a 8): "
	error_larg: .asciiz "Tamano ingresado no corresponde\n"
	mensaje_input: .asciiz "Ingrese un numero: "
	arreglo_entrada: .asciiz "Arreglo original: "
	espacio: .asciiz " "
.text

main:
# pedir tamano del arreglo
	li $v0, 4 #codigo de escribir string
	la $a0, largo_arreglo
	syscall #imprimir string para pedir N

	li $v0, 5 #codigo para recibir string
	syscall #esperar el valor de N
	move $s0, $v0 #en $s0 esta N

	#validar tamano del arreglo
	blt $s0, 1, error_largo
	bgt $s0, 8, error_largo

	# pedir arreglo
	li $t0, 0 
    la $t1, 0x10010000 #direccion de memoria donde pedir

recibir_elementos:
	beq $t0, $s0, copiar
	#imprimir string para pedir 1 numero
	li $v0, 4
    la $a0, mensaje_input
    syscall
	#esperar el numero
	li $v0, 5
    syscall

	# lo guadramos en la direccion de entrada 0x10010000 con correspondietne offset
	sll $t2, $t0, 2 #avanza el inidice en 1
    add $t3, $t1, $t2 #prepara arreglo[i]
    sw $v0, 0($t3) #guarda el valor recibido en arreglo[i]

    addi $t0, $t0, 1 #aumentar contador
    j recibir_elementos #otro ciclo


copiar:
	#copiamos el arreglo recibido a la direccion de salida 0x10010080 y trabajaremos sobre este
	li $t0, 0 #reiniciar contador
	la $t1, 0x10010000 #cargar direccion de memoria para la entrada
	la $t2, 0x10010080 #cargar direccion de memoria para la salida

copiar_loop:
	beq $t0, $s0, imprimir_arreglo #comprobar

	sll $t3, $t0, 2
    add $t4, $t1, $t3
    add $t5, $t2, $t3

    lw $t6, 0($t4)
    sw $t6, 0($t5)

    addi $t0, $t0, 1
    j copiar_loop


imprimir_arreglo:
	li $v0, 4 #codigo de escribir string
	la $a0, arreglo_entrada
	syscall #mostrar mensaje
	la $t1, 0x10010000 #cargar direccion de memoria del arreglo cargado
	li $t0, 0 #reiniciar contador

loop_imprimir:
	beq $t0, $s0, exit

	# recorre el arreglo
	sll $t3, $t0, 2
    add $t4, $t1, $t3

	# imprime numero en pantalla
    li $v0, 1
    lw $a0, 0($t4)
    syscall

	li $v0, 4 #codigo de escribir string
	la $a0, espacio
	syscall

    addi $t0, $t0, 1
    j loop_imprimir

exit:
	li $v0, 10
	syscall

error_largo:
	li $v0, 4
	la $a0, error_larg
	syscall
	j main