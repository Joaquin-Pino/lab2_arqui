# ==============================================================================
# Laboratorio 2: Merge Sort Recursivo en MIPS
# Autor: (Tu Nombre / Grupo)
# Descripción: Ordena un arreglo de enteros usando Merge Sort.
# Entradas: Arreglo en 0x10010000 (Max 8 elementos)
# Salidas: Arreglo ordenado en 0x10010080
# ==============================================================================

.data
    # Definición de direcciones de memoria solicitadas en el PDF
    .eqv SOURCE_ADDR 0x10010000
    .eqv DEST_ADDR   0x10010080
    
    # Mensajes para el usuario
    msg_size:    .asciiz "Ingrese el tamaño del arreglo (Max 8): "
    msg_elem:    .asciiz "Ingrese elemento: "
    msg_orig:    .asciiz "\nArreglo original: "
    msg_sort:    .asciiz "\nArreglo ordenado: "
    msg_sep:     .asciiz ", "
    msg_bracket_o: .asciiz "["
    msg_bracket_c: .asciiz "]"
    
    # --- CORRECCIÓN AQUÍ ---
    # Alineamos la memoria a palabra (4 bytes) antes de declarar el array
    .align 2  
    # Buffer temporal para la función merge (Variable auxiliar)
    temp_array:  .space 32  # 8 enteros * 4 bytes
.text
.globl main

# ==============================================================================
# MAIN
# ==============================================================================
main:
    # 1. Pedir tamaño del arreglo (N)
    li $v0, 4
    la $a0, msg_size
    syscall

    li $v0, 5
    syscall
    move $s0, $v0           # $s0 = N (Tamaño del arreglo)

    # Validar que N > 0 y N <= 8 (Opción de seguridad básica)
    blez $s0, exit
    li $t0, 8
    bgt $s0, $t0, exit

    # 2. Leer elementos y guardarlos en SOURCE_ADDR (0x10010000) 
    li $t0, 0               # Índice i = 0
    li $t1, SOURCE_ADDR     # Dirección base origen

input_loop:
    beq $t0, $s0, copy_process # Si i == N, terminar lectura

    # Prompt número
    li $v0, 4
    la $a0, msg_elem
    syscall

    # Leer entero
    li $v0, 5
    syscall
    
    # Guardar en memoria (Base + offset)
    sll $t2, $t0, 2         # Offset = i * 4
    add $t3, $t1, $t2       # Dirección efectiva
    sw $v0, 0($t3)          # Store word

    addi $t0, $t0, 1        # i++
    j input_loop

copy_process:
    # 3. Copiar arreglo de Origen (0x10010000) a Destino (0x10010080)
    # El ordenamiento se hará sobre la dirección de destino para preservar el original.
    li $t0, 0
    li $t1, SOURCE_ADDR
    li $t2, DEST_ADDR
    
copy_loop:
    beq $t0, $s0, start_sort
    
    sll $t3, $t0, 2         # Offset
    add $t4, $t1, $t3       # Dir Origen
    add $t5, $t2, $t3       # Dir Destino
    
    lw $t6, 0($t4)          # Cargar de origen
    sw $t6, 0($t5)          # Guardar en destino
    
    addi $t0, $t0, 1
    j copy_loop

start_sort:
    # 4. Mostrar arreglo original [cite: 43]
    li $v0, 4
    la $a0, msg_orig
    syscall
    
    move $a0, $s0           # Tamaño
    li $a1, SOURCE_ADDR     # Dirección
    jal print_array

    # 5. Llamada a Merge Sort [cite: 34]
    # Argumentos: $a0 = dirección base, $a1 = low (0), $a2 = high (N-1)
    li $a0, DEST_ADDR       # Ordenamos el arreglo en la dirección de salida 
    li $a1, 0               # low = 0
    sub $a2, $s0, 1         # high = N - 1
    
    jal mergesort

    # 6. Mostrar arreglo ordenado [cite: 43]
    li $v0, 4
    la $a0, msg_sort
    syscall
    
    move $a0, $s0           # Tamaño
    li $a1, DEST_ADDR       # Dirección (Ya ordenado)
    jal print_array

exit:
    li $v0, 10              # Syscall exit
    syscall

# ==============================================================================
# FUNCION: mergesort(arr, low, high)
# Descripción: Divide el arreglo recursivamente.
# ==============================================================================
mergesort:
    # Manejo de la pila (Prólogo) 
    addi $sp, $sp, -16      # Reservar espacio para 4 items
    sw $ra, 12($sp)         # Guardar dirección de retorno
    sw $a0, 8($sp)          # Guardar dirección base arreglo
    sw $a1, 4($sp)          # Guardar low
    sw $a2, 0($sp)          # Guardar high

    # Caso Base: si low >= high, retornar
    bge $a1, $a2, ms_end

    # Calcular mid = (low + high) / 2
    add $t0, $a1, $a2
    sra $t0, $t0, 1         # División por 2 (shift right arithmetic)
    
    # --- Llamada Recursiva Izquierda: mergesort(arr, low, mid) ---
    # $a0 (arr) se mantiene
    # $a1 (low) se mantiene
    move $a2, $t0           # high = mid
    jal mergesort           # Llamada recursiva [cite: 35]

    # Recuperar valores para la siguiente llamada (mid se perdió, hay que recalcular o cargar)
    lw $a0, 8($sp)          # Recuperar arr
    lw $a1, 4($sp)          # Recuperar low
    lw $a2, 0($sp)          # Recuperar high
    
    # Recalcular mid
    add $t0, $a1, $a2
    sra $t0, $t0, 1

    # --- Llamada Recursiva Derecha: mergesort(arr, mid + 1, high) ---
    # $a0 (arr) se mantiene
    addi $a1, $t0, 1        # low = mid + 1
    # $a2 (high) se mantiene
    jal mergesort

    # --- Llamada a Merge: merge(arr, low, mid, high) ---
    lw $a0, 8($sp)          # Recuperar arr
    lw $a1, 4($sp)          # Recuperar low
    lw $a2, 0($sp)          # Recuperar high
    
    # Necesitamos pasar mid como tercer argumento.
    # Recalculamos mid una última vez
    add $t0, $a1, $a2
    sra $t0, $t0, 1
    
    # Argumentos para merge: $a0=arr, $a1=low, $a2=mid, $a3=high
    move $a3, $a2           # Mover high a $a3
    move $a2, $t0           # Mover mid a $a2
    jal merge               # Combinar [cite: 36]

ms_end:
    # Manejo de la pila (Epílogo)
    lw $ra, 12($sp)
    lw $a0, 8($sp)
    lw $a1, 4($sp)
    lw $a2, 0($sp)
    addi $sp, $sp, 16       # Liberar espacio
    jr $ra

# ==============================================================================
# FUNCION: merge(arr, low, mid, high)
# Descripción: Combina dos subarreglos ordenados.
# Argumentos: $a0=base, $a1=low, $a2=mid, $a3=high
# ==============================================================================
merge:
    # Guardar registros temporales importantes ($s0-$s7 deben preservarse si se usan)
    addi $sp, $sp, -20
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    sw $s3, 4($sp)
    sw $ra, 0($sp)

    # Inicializar índices
    move $s0, $a1           # i = low (índice subarreglo izquierdo)
    addi $s1, $a2, 1        # j = mid + 1 (índice subarreglo derecho)
    li $s2, 0               # k = 0 (índice arreglo temporal)
    
    # Dirección de temp_array
    la $s3, temp_array

while_merge:
    # Condiciones del while: (i <= mid) && (j <= high)
    bgt $s0, $a2, copy_remain_right  # Si i > mid, copiar resto derecha
    bgt $s1, $a3, copy_remain_left   # Si j > high, copiar resto izquierda

    # Cargar arr[i]
    sll $t0, $s0, 2
    add $t0, $a0, $t0
    lw $t1, 0($t0)          # $t1 = arr[i]

    # Cargar arr[j]
    sll $t2, $s1, 2
    add $t2, $a0, $t2
    lw $t3, 0($t2)          # $t3 = arr[j]

    # Comparar
    blt $t1, $t3, take_left # Si arr[i] < arr[j], tomar izquierdo

    # Tomar derecho (arr[j])
    sll $t4, $s2, 2
    add $t4, $s3, $t4
    sw $t3, 0($t4)          # temp[k] = arr[j]
    addi $s1, $s1, 1        # j++
    addi $s2, $s2, 1        # k++
    j while_merge

take_left:
    # Tomar izquierdo (arr[i])
    sll $t4, $s2, 2
    add $t4, $s3, $t4
    sw $t1, 0($t4)          # temp[k] = arr[i]
    addi $s0, $s0, 1        # i++
    addi $s2, $s2, 1        # k++
    j while_merge

copy_remain_left:
    bgt $s0, $a2, copy_back # Si i > mid, terminar
    
    sll $t0, $s0, 2
    add $t0, $a0, $t0
    lw $t1, 0($t0)
    
    sll $t4, $s2, 2
    add $t4, $s3, $t4
    sw $t1, 0($t4)
    
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    j copy_remain_left

copy_remain_right:
    bgt $s1, $a3, copy_back # Si j > high, terminar
    
    sll $t2, $s1, 2
    add $t2, $a0, $t2
    lw $t3, 0($t2)
    
    sll $t4, $s2, 2
    add $t4, $s3, $t4
    sw $t3, 0($t4)
    
    addi $s1, $s1, 1
    addi $s2, $s2, 1
    j copy_remain_right

copy_back:
    # Copiar desde temp_array de vuelta a arr[low...high]
    # k reinicia a 0. El destino empieza en low ($a1)
    li $t0, 0               # k = 0
    move $t1, $a1           # p = low (puntero en arreglo original)

loop_copy_back:
    bgt $t1, $a3, merge_done # Si p > high, fin
    
    # Cargar de temp[k]
    sll $t2, $t0, 2
    add $t2, $s3, $t2
    lw $t3, 0($t2)
    
    # Guardar en arr[p]
    sll $t4, $t1, 2
    add $t4, $a0, $t4
    sw $t3, 0($t4)
    
    addi $t0, $t0, 1        # k++
    addi $t1, $t1, 1        # p++
    j loop_copy_back

merge_done:
    # Epílogo Merge
    lw $s0, 16($sp)
    lw $s1, 12($sp)
    lw $s2, 8($sp)
    lw $s3, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 20
    jr $ra

# ==============================================================================
# UTILIDAD: print_array(size, address)
# ==============================================================================
print_array:
    move $t0, $a0           # size
    move $t1, $a1           # address
    li $t2, 0               # index
    
    li $v0, 4
    la $a0, msg_bracket_o   # "["
    syscall

print_loop:
    beq $t2, $t0, print_end
    
    # Cargar numero
    sll $t3, $t2, 2
    add $t3, $t1, $t3
    lw $a0, 0($t3)
    li $v0, 1               # print int
    syscall
    
    # Imprimir coma si no es el último
    sub $t4, $t0, 1
    beq $t2, $t4, skip_comma
    li $v0, 4
    la $a0, msg_sep
    syscall
skip_comma:
    addi $t2, $t2, 1
    j print_loop

print_end:
    li $v0, 4
    la $a0, msg_bracket_c   # "]"
    syscall
    jr $ra