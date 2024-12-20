section .data
    ; Pointer to the dynamically allocated array for the heap
    heap_ptr dd 0
    ; Size of the heap (number of items)
    heap_size dd 0
    ; Capacity of the heap (total allocated space)
    heap_capacity dd 0

section .text
    extern malloc
    extern free
    global insert_element
    global remove_max

; Function: insert_element
; Input:
;   EAX: Priority (Value to insert)
insert_element:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ebx

    ; Load current heap size
    mov esi, [heap_size]

    ; Check if we need to resize
    mov edi, [heap_capacity]
    cmp esi, edi
    jl .insert_no_resize

    ; Resize: Double the capacity or initialize if 0
    add edi, edi
    test edi, edi
    jnz .resize_nonzero
    mov edi, 1  ; Initial capacity if it was 0

.resize_nonzero:
    push edi
    call malloc  ; Allocate new space
    add esp, 4

    ; Check if malloc was successful
    test eax, eax
    jz .allocation_error

    ; Copy old heap to new space if it exists
    mov ebx, [heap_ptr]
    test ebx, ebx
    jz .no_old_heap

    push esi  ; Number of bytes to copy
    push ebx  ; Source
    push eax  ; Destination
    call memcpy
    add esp, 12

    ; Free old memory
    push ebx
    call free
    add esp, 4

.no_old_heap:
    mov [heap_ptr], eax
    mov [heap_capacity], edi

.insert_no_resize:
    ; Store the new element at the end of the heap
    mov edi, [heap_ptr]
    lea edi, [edi + esi * 4]
    mov [edi], eax

    ; Increment size
    inc dword [heap_size]

    ; Heapify Up
    mov ecx, esi
    dec ecx  ; Adjust for 0-based indexing

.heapify_up_loop:
    cmp ecx, 0
    je .done_insert

    ; Calculate parent index
    mov ebx, ecx
    shr ebx, 1

    ; Compare with parent
    mov eax, [edi]
    mov edx, [heap_ptr + ebx * 4]
    cmp eax, edx
    jle .done_insert

    ; Swap if necessary
    xchg eax, edx
    mov [edi], eax
    mov [heap_ptr + ebx * 4], edx

    mov ecx, ebx
    lea edi, [heap_ptr + ecx * 4]
    jmp .heapify_up_loop

.done_insert:
    xor eax, eax  ; Return success (0)
    jmp .exit_insert

.allocation_error:
    mov eax, -1  ; Error code for allocation failure

.exit_insert:
    pop ebx
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret

; Function: remove_max
; Output:
;   EAX: Maximum priority (or error code)
remove_max:
    push ebp
    mov ebp, esp
    push esi
    push edi

    ; Check if heap is empty
    mov esi, [heap_size]
    test esi, esi
    jz .empty

    ; Move last element to root
    dec esi
    mov eax, [heap_ptr + esi * 4]
    mov edx, [heap_ptr]
    mov [heap_ptr], eax

    ; Decrease size
    mov [heap_size], esi

    ; Heapify Down
    mov ecx, 0
.heapify_down_loop:
    mov eax, [heap_ptr + ecx * 4]  ; Current node
    mov ebx, ecx
    shl ebx, 1  ; Left child index
    inc ebx  ; Adjust for 1-based child indexing

    ; Check if there's a left child
    cmp ebx, [heap_size]
    jg .done_remove

    ; Check if there's a right child
    mov edx, ebx
    inc edx
    cmp edx, [heap_size]
    jg .no_right

    ; Compare left and right child
    mov edx, [heap_ptr + (ebx - 1) * 4]  ; Left child
    mov edi, [heap_ptr + edx * 4]  ; Right child
    cmp edx, edi
    jl .use_right
    jmp .use_left

.use_right:
    mov ebx, edx
.use_left:
    ; Compare with current node
    mov edx, [heap_ptr + (ebx - 1) * 4]
    cmp eax, edx
    jge .done_remove

    ; Swap and continue down
    xchg eax, edx
    mov [heap_ptr + ecx * 4], eax
    mov [heap_ptr + (ebx - 1) * 4], edx
    mov ecx, ebx
    dec ecx  ; Adjust for loop's child index calculation
    jmp .heapify_down_loop

.no_right:
.done_remove:
    mov eax, edx  ; Return the max element (now at root)
    jmp .exit_remove

.empty:
    mov eax, -1  ; Error code for empty heap

.exit_remove:
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret

; Helper function to copy memory, similar to C's memcpy
; Parameters: 
;   [esp+4] = dst
;   [esp+8] = src
;   [esp+12] = n
memcpy:
    push ebp
    mov ebp, esp
    push esi
    push edi

    mov edi, [ebp+8]  ; Destination
    mov esi, [ebp+12] ; Source
    mov ecx, [ebp+16] ; Number of bytes

    rep movsb

    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret
