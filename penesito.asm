.data 0x10010200  # recomendado por gemini ya que el output no se mostraba bien
    
    largo_arreglo:   .asciiz "Ingrese la cantidad de numeros (de 1 a 8): "
    error_larg:      .asciiz "Tamano ingresado no corresponde\n"
    mensaje_input:   .asciiz "Ingrese un numero: "
    arreglo_entrada: .asciiz "\nArreglo original: "
    arreglo_ordenado:.asciiz "\nArreglo ordenado: "   
    
    espacio: .asciiz ", " 

.text

.globl main


main:
    # pedir tamano del arreglo
    li $v0, 4               
    la $a0, largo_arreglo
    syscall                 

    li $v0, 5               
    syscall                 
    move $s0, $v0           # $s0 = N

    # validar tamano
    blt $s0, 1, error_largo
    bgt $s0, 8, error_largo

    # pedir arreglo
    li $t0, 0 
    la $t1, 0x10010000      # direccion ENTRADA

recibir_elementos:
    beq $t0, $s0, copiar
    
    li $v0, 4
    la $a0, mensaje_input
    syscall
    
    li $v0, 5
    syscall

    # Guardar en 0x10010000 + offset
    sll $t2, $t0, 2         
    add $t3, $t1, $t2       
    sw $v0, 0($t3)          

    addi $t0, $t0, 1        
    j recibir_elementos     

copiar:
    # Copiar de Entrada (10000) a Salida (10080)
    li $t0, 0               
    la $t1, 0x10010000      
    la $t2, 0x10010080      # direccion SALIDA

copiar_loop:
    beq $t0, $s0, imprimir_arreglo 

    sll $t3, $t0, 2
    add $t4, $t1, $t3
    add $t5, $t2, $t3

    lw $t6, 0($t4)
    sw $t6, 0($t5)

    addi $t0, $t0, 1
    j copiar_loop

imprimir_arreglo:
    li $v0, 4               
    la $a0, arreglo_entrada
    syscall                 
    
    la $t1, 0x10010000      
    li $t0, 0               

loop_imprimir:
    beq $t0, $s0, ordenar   # Al terminar, vamos a ordenar

    sll $t3, $t0, 2
    add $t4, $t1, $t3

    li $v0, 1
    lw $a0, 0($t4)
    syscall

    li $v0, 4               
    la $a0, espacio
    syscall

    addi $t0, $t0, 1
    j loop_imprimir

ordenar:
    # Parametros para mergesort 
    li $a0, 0x10010080      # Ordenamos sobre la dirección de SALIDA
    li $a1, 0               # low = 0
    sub $a2, $s0, 1         # high = N - 1

    jal mergesort
    
    # Imprimir resultado
    li $v0, 4
    la $a0, arreglo_ordenado
    syscall
    
    la $t1, 0x10010080      # Leemos de la direccion de salida
    li $t0, 0               

loop_imprimir_final:
    beq $t0, $s0, exit      
    
    sll $t3, $t0, 2
    add $t4, $t1, $t3
    
    li $v0, 1
    lw $a0, 0($t4)
    syscall
    
    li $v0, 4
    la $a0, espacio
    syscall
    
    addi $t0, $t0, 1
    j loop_imprimir_final

exit:
    li $v0, 10
    syscall

error_largo:
    li $v0, 4
    la $a0, error_larg
    syscall
    j main

# ==============================================================================
# FUNCIONES RECURSIVAS
# ==============================================================================

mergesort:
    addi $sp, $sp, -16      
    sw $ra, 12($sp)         
    sw $a0, 8($sp)          
    sw $a1, 4($sp)          
    sw $a2, 0($sp)          
    
    bge $a1, $a2, fin_mergesort
    
    # mid = (low + high) / 2
    add $t0, $a1, $a2
    sra $t0, $t0, 1         
    
    # mergesort(arr, low, mid)
    move $a2, $t0           
    jal mergesort           
    
    lw $a0, 8($sp)          
    lw $a1, 4($sp)          
    lw $a2, 0($sp)          

    # Recalcular mid
    add $t0, $a1, $a2
    sra $t0, $t0, 1

    # mergesort(arr, mid + 1, high)
    addi $a1, $t0, 1        
    jal mergesort
    
    # merge(arr, low, mid, high)
    lw $a0, 8($sp)          
    lw $a1, 4($sp)          
    lw $a2, 0($sp)          

    add $t0, $a1, $a2
    sra $t0, $t0, 1
    
    move $a3, $a2           # high -> a3
    move $a2, $t0           # mid -> a2
    
    jal merge

fin_mergesort:
    lw $ra, 12($sp)
    lw $a0, 8($sp)
    lw $a1, 4($sp)
    lw $a2, 0($sp)
    
    addi $sp, $sp, 16       # Liberar pila
    jr $ra

# ==============================================================================
# FUNCION MERGE (Usando direccion manual para temporal)
# ==============================================================================
merge:
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)
    sw $s3, 0($sp)

    move $s0, $a1           # i = low
    addi $s1, $a2, 1        # j = mid + 1
    li $s2, 0               # k = 0
    
    # --- CAMBIO AQUI ---
    # En lugar de usar una etiqueta, cargamos manualmente la dirección
    li $s3, 0x10010100      # Direccion TEMPORAL (segura y vacia)

bucle_merge:
    bgt $s0, $a2, copiar_resto_izq   
    bgt $s1, $a3, copiar_resto_izq   

    sll $t0, $s0, 2
    add $t0, $a0, $t0
    lw $t1, 0($t0)          # arr[i]

    sll $t2, $s1, 2
    add $t2, $a0, $t2
    lw $t3, 0($t2)          # arr[j]

    blt $t1, $t3, guardar_izq

    # Guardar derecha
    sll $t4, $s2, 2
    add $t4, $s3, $t4
    sw $t3, 0($t4)
    addi $s1, $s1, 1
    addi $s2, $s2, 1
    j bucle_merge

guardar_izq:
    # Guardar izquierda
    sll $t4, $s2, 2
    add $t4, $s3, $t4
    sw $t1, 0($t4)
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    j bucle_merge

copiar_resto_izq:
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
    li $t0, 0               # k = 0
    move $t1, $a1           # p = low

bucle_final:
    bgt $t1, $a3, fin_merge
    
    sll $t2, $t0, 2
    add $t2, $s3, $t2
    lw $t5, 0($t2)
    
    sll $t4, $t1, 2
    add $t4, $a0, $t4
    sw $t5, 0($t4)
    
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j bucle_final

fin_merge:
    lw $s3, 0($sp)
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra