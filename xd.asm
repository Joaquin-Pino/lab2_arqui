.data 0x10010200  # recomendado por gemini, el output se imprime mal si esto no esta
    
    largo_arreglo:   .asciiz "Ingrese la cantidad de numeros (de 1 a 8): "
    error_larg:      .asciiz "Tamano ingresado no corresponde\n"
    mensaje_input:   .asciiz "Ingrese un numero: "
    arreglo_entrada: .asciiz "\nArreglo original: "
    arreglo_ordenado:.asciiz "\nArreglo ordenado: "   
    
    espacio: .asciiz ", " 

.text

.globl main


main:
    # pedir cantidad de elementos del arreglo
    li $v0, 4               
    la $a0, largo_arreglo
    syscall                 

    # leer el entero n desde la consola
    li $v0, 5               
    syscall                 
    move $s0, $v0 # guardamos n en s0 para no perderlo

    # validar que el tamano sea correcto (entre 1 y 8)
    blt $s0, 1, error_largo
    bgt $s0, 8, error_largo

    # preparar para recibir el arreglo
    li $t0, 0 # contador i = 0
    la $t1, 0x10010000 # direccion de memoria de entrada (origen)

recibir_elementos:
    beq $t0, $s0, copiar # si i == n, terminamos de leer y pasamos a copiar
    
    # mostrar mensaje para pedir un numero
    li $v0, 4
    la $a0, mensaje_input
    syscall
    
    # leer el numero entero ingresado
    li $v0, 5
    syscall

    # guardar el numero en 0x10010000 + offset
    sll $t2, $t0, 2  # calcular desplazamiento: i * 4
    add $t3, $t1, $t2   # calcular direccion exacta: base + offset
    sw $v0, 0($t3) # guardar el valor en memoria

    addi $t0, $t0, 1 # i++
    j recibir_elementos  # repetir ciclo

copiar:
    # copiar el arreglo de entrada a la direccion de salida (para no perder el original al ordenar)
    li $t0, 0   # reiniciar contador i = 0
    la $t1, 0x10010000   # direccion origen
    la $t2, 0x10010080 # direccion destino (salida)

copiar_loop:
    beq $t0, $s0, imprimir_arreglo # si terminamos de copiar, ir a imprimir

    # calcular direcciones para el elemento actual
    sll $t3, $t0, 2 # offset = i * 4
    add $t4, $t1, $t3 # direccion elemento origen
    add $t5, $t2, $t3 # direccion elemento destino

    lw $t6, 0($t4) # cargar dato del origen
    sw $t6, 0($t5)# guardar dato en el destino

    addi $t0, $t0, 1# i++
    j copiar_loop # repetir

imprimir_arreglo:
    # mostrar mensaje del arreglo original
    li $v0, 4               
    la $a0, arreglo_entrada
    syscall                 
    
    la $t1, 0x10010000 # apuntar a la direccion original
    li $t0, 0 # reiniciar contador

loop_imprimir:
    beq $t0, $s0, ordenar # al terminar de imprimir, ir a ordenar

    sll $t3, $t0, 2 # calcular direccion elemento actual
    add $t4, $t1, $t3

    # imprimir el numero
    li $v0, 1
    lw $a0, 0($t4)
    syscall

    # imprimir coma y espacio
    li $v0, 4               
    la $a0, espacio
    syscall

    addi $t0, $t0, 1 # i++
    j loop_imprimir# repetir

ordenar:
    # preparar parametros para mergesort 
    li $a0, 0x10010080 # ordenar sobre la direccion de salida (la copia)
    li $a1, 0 # low = 0
    sub $a2, $s0, 1 # high = n - 1

    jal mergesort # llamar a la funcion recursiva
    
    # mostrar mensaje de resultado
    li $v0, 4
    la $a0, arreglo_ordenado
    syscall
    
    la $t1, 0x10010080 # apuntar a la direccion de salida (ya ordenada)
    li $t0, 0 # reiniciar contador

loop_imprimir_final:
    beq $t0, $s0, exit # si terminamos, salir
    
    sll $t3, $t0, 2  # calcular direccion elemento actual
    add $t4, $t1, $t3
    
    # imprimir numero ordenado
    li $v0, 1
    lw $a0, 0($t4)
    syscall
    
    # imprimir espacio
    li $v0, 4
    la $a0, espacio
    syscall
    
    addi $t0, $t0, 1 # i++
    j loop_imprimir_final # repetir

exit:
    # terminar el programa
    li $v0, 10
    syscall

error_largo:
    # mostrar mensaje de error de tamano
    li $v0, 4
    la $a0, error_larg
    syscall
    j main # volver a empezar

# ------------------- funciones recursivas -----------------------------

mergesort:
    # guardar contexto en la pila
    addi $sp, $sp, -16 # reservar 4 espacios
    sw $ra, 12($sp) # guardar direccion de retorno
    sw $a0, 8($sp) # guardar direccion base
    sw $a1, 4($sp) # guardar low
    sw $a2, 0($sp) # guardar high
    
    # caso base: si low >= high, retornar
    bge $a1, $a2, fin_mergesort
    
    # calcular punto medio: mid = (low + high) / 2
    add $t0, $a1, $a2
    sra $t0, $t0, 1         
    
    # llamada recursiva izquierda: mergesort(arr, low, mid)
    move $a2, $t0  # high = mid
    jal mergesort           
    
    # recuperar registros despues de la llamada
    lw $a0, 8($sp)          
    lw $a1, 4($sp)          
    lw $a2, 0($sp)          

    # recalcular mid
    add $t0, $a1, $a2
    sra $t0, $t0, 1

    # llamada recursiva derecha: mergesort(arr, mid + 1, high)
    addi $a1, $t0, 1 # low = mid + 1
    jal mergesort
    
    # combinar: merge(arr, low, mid, high)
    lw $a0, 8($sp) # recuperar arr
    lw $a1, 4($sp) # recuperar low
    lw $a2, 0($sp)  # recuperar high

    add $t0, $a1, $a2 # recalcular mid
    sra $t0, $t0, 1
    
    move $a3, $a2 # pasar high en a3
    move $a2, $t0 # pasar mid en a2
    
    jal merge # saltar a funcion merge

fin_mergesort:
    # restaurar pila y retornar
    lw $ra, 12($sp)
    lw $a0, 8($sp)
    lw $a1, 4($sp)
    lw $a2, 0($sp)
    
    addi $sp, $sp, 16       
    jr $ra

# funcion merge (usando direccion manual para temporal)
merge:
    # guardar registros s0-s3 en la pila
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)
    sw $s3, 0($sp)

    # inicializar indices
    move $s0, $a1 # i = low (inicio izquierda)
    addi $s1, $a2, 1 # j = mid + 1 (inicio derecha)
    li $s2, 0 # k = 0 (indice temporal)
    
    # cargar manualmente la direccion temporal
    li $s3, 0x10010100      

bucle_merge:
    # mientras queden elementos en ambas mitades
    bgt $s0, $a2, copiar_resto_izq   
    bgt $s1, $a3, copiar_resto_izq   

    # cargar arr[i]
    sll $t0, $s0, 2
    add $t0, $a0, $t0
    lw $t1, 0($t0)          

    # cargar arr[j]
    sll $t2, $s1, 2
    add $t2, $a0, $t2
    lw $t3, 0($t2)          

    # comparar: si izq < der, guardar izq
    blt $t1, $t3, guardar_izq

    # guardar derecha en temporal
    sll $t4, $s2, 2
    add $t4, $s3, $t4
    sw $t3, 0($t4)
    addi $s1, $s1, 1 # j++
    addi $s2, $s2, 1 # k++
    j bucle_merge

guardar_izq:
    # guardar izquierda en temporal
    sll $t4, $s2, 2
    add $t4, $s3, $t4
    sw $t1, 0($t4)
    addi $s0, $s0, 1 # i++
    addi $s2, $s2, 1 # k++
    j bucle_merge

copiar_resto_izq:
    # copiar sobrantes de la izquierda
    bgt $s0, $a2, copiar_resto_der
    
    sll $t0, $s0, 2
    add $t0, $a0, $t0
    lw $t1, 0($t0)
    
    sll $t4, $s2, 2
    add $t4, $s3, $t4
    sw $t1, 0($t4)
    
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    j copiar_resto_izq

copiar_resto_der:
    # copiar sobrantes de la derecha
    bgt $s1, $a3, copiar_a_original
    
    sll $t2, $s1, 2
    add $t2, $a0, $t2
    lw $t3, 0($t2)
    
    sll $t4, $s2, 2
    add $t4, $s3, $t4
    sw $t3, 0($t4)
    
    addi $s1, $s1, 1
    addi $s2, $s2, 1
    j copiar_resto_der

copiar_a_original:
    # copiar del temporal de vuelta al arreglo real
    li $t0, 0 # k = 0
    move $t1, $a1 # p = low

bucle_final:
    bgt $t1, $a3, fin_merge
    
    # leer del temporal
    sll $t2, $t0, 2
    add $t2, $s3, $t2
    lw $t5, 0($t2)
    
    # escribir en el original
    sll $t4, $t1, 2
    add $t4, $a0, $t4
    sw $t5, 0($t4)
    
    addi $t0, $t0, 1 # k++
    addi $t1, $t1, 1  # p++
    j bucle_final

fin_merge:
    # restaurar registros y retornar
    lw $s3, 0($sp)
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra