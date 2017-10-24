;;; EAX  Arithmetic, Return Value
;;; EBX
;;; ECX - Counter ; We should probably use Saved register for counter instead.
;;; EDX
;;; ESI
;;; EDI
;;; ESP  Stack Pointer
;;; EBP  Stack Frame Base
;;; “Dirty Registers”: EAX, EDX, ECX: These can be overwritten at any time
;;; “Saved Registers”: EBP, EBX, ESI, EDI: These must be saved and restored within the function if used
;;;
        ;; import functions from libc
        extern printf
        extern exit
        extern atoi
        extern itoa

        section .bss
some_array:     resd 1000         ; reserve 100 4-byte value which will be used to store int
tmp_array:      resd 1000

number_of_int:  resd 1
        
        section .data
nl:
        db "", 0x0A, 0

dformat:
        db "%d ", 0x00           ; decimal foramt
        
print_byte:
        db "0x%X", 0x0A, 0x00   ; hex foramt

basic_byte:
        db 4

length:
        dd 0

        section .text
        
        global main             ; the standard gcc entry point, 
main:                        ; the program label for the entry point .We export main so libc can find it
        ;; make new stack frame
        push    ebp                ; save the stack frame base
        mov     ebp, esp           ; ebp get the value of esp(stack poniter)
        mov     edx, [ebp+12]      ; edx now is the adrress of atgv[0]

        
        ;; check if first argument(ebp+8) is 1, if so there is nothing to sort so just end.
        mov     ebx, dword[ebp+8]
        sub     ebx, 1
        cmp     ebx, 0
        je      end_program

        mov    [length], ebx
        ;; ebx*4
        add     ebx, ebx
        add     ebx, ebx
        
        mov     ecx, 0
        .loop:
        cmp     ecx, ebx     ; ebx now is the total number of integers * 4
        jge     .L2

        push    ecx             ;
        push    edx              ; edx will be polluted by atoi call so we need to save it now.
        ;; 
        push    dword[edx+4+ecx]     ; edx+4 is argv[1] which is the first integer
        call    atoi            ; after this call, a converted int should be stored in eax, now.
        add     esp, 4          ; move esp back, which also means discard the pushed value
        pop     edx             ; since the atoi call ended, we can take back our saved edx
        pop     ecx
        
        mov     dword[some_array+ecx], eax
        add     ecx, 4
        jmp     .loop

        .L2:
        
        ;; can use this to print the array and it works!!!
        push    dword[length]                ; push the size of the array
        ;;         push    some_array
        push    some_array
        call    print_array

        
        mov     ecx, dword[length]
        sub     ecx, 1
        push    ecx
        push    0
        push    some_array
        call    quick_sort


        ;; can use this to print the array and it works!!!
        push    dword[length]             ; push the size of the array
        ;;         push    some_array
        push    tmp_array             ; the quick_sort call return value to somewhere I don't know
        call    print_array

        call    end_program


;;;-----------------------------------------------------------------                                
;;; void asm_quick_sort(int* elems, int startindex, int endindex)
;;; Params:
;;;     elems - pointer to elements to sort - [ebp + 0x8]
;;;     sid - start index of items - [ebp + 0xC]
;;;     eid - end index of items - [ebp + 0x10]
        
quick_sort:
        ;; start the stack frame
        push    ebp
        mov     ebp, esp

        ;; The following three registers are all saved registers that must be saved and restored within the funtion if used
        push    edi
        push    esi
        push    ebx

        mov     eax, dword [ebp + 0xC]  ; store start index,  = i
        mov     ebx, dword [ebp + 0x10] ; store end index
        mov     esi, dword [ebp + 0x8]  ; store pointer to first element in esi

        ;; Jump if eax(startindex) is not less than ebx(endindex)
        cmp     eax, ebx        ; if(startindex >= endindex)
        jge     .qsort_done      ; exit

        mov     ecx, eax                        ; ecx = j, = startindex
        mov     edx, dword [esi + (0x4 * ebx)]  ; pivot element, elems[endindex], edx = pivot
        jmp     .qsort_part_loop

.qsort_part_loop:
        ;; for j = startindex; j < endindex; j++
        cmp     ecx, ebx                    ; if ecx < end index
        jnb     .qsort_end_part
        
        ;; if elems[j] <= pivot
        cmp     edx, dword [esi + (0x4*ecx)]
        jb     .qsort_cont_loop             ; jump if edx(pivot) is below or equal to elems[j]

        ;; do swap, elems[i], elems[j]
        push    edx                         ; save pivot for now     
        mov     edx, dword [esi + (0x4*ecx)]        ; edx = elems[j]
        mov     edi, dword [esi + (0x4*eax)]        ; edi = elems[i]
        mov     dword [esi + (0x4*eax)], edx        ; elems[i] = elems[j]
        mov     dword [esi + (0x4*ecx)], edi        ; elems[j] = elems[i]
        pop     edx ; restore pivot
        
        ;; i++
        add     eax, 0x1
        jmp     .qsort_cont_loop
        
.qsort_cont_loop:
        add     ecx, 0x1                ; j++
        jmp     .qsort_part_loop
        
.qsort_end_part:
    ;; do swap, elems[i], elems[eid]
        mov     edx, dword [esi + (0x4*eax)]        ; edx = elems[i]
        mov     edi, dword [esi + (0x4*ebx)]        ; edi = elems[eid]
        mov     dword [esi + (0x4*ebx)], edx        ; elems[eidx] = elems[i]
        mov     dword [esi + (0x4*eax)], edi        ; elems[i] = elems[eidx]

    ;; qsort(elems, sid, i - 1)
    ;; qsort(elems, i + 1, eid)
        sub     eax, 0x1        ; i-1
        push    eax             ; push i-1
        push    dword [ebp + 0xC]  ; push start index
        push    dword [ebp + 0x8]  ; push elems vector
        call    quick_sort
        add     esp, 0x8        ; discard the two item on the stack
        pop     eax             ; eax stores i-1
        add     eax, 0x2        ; eax stores i+1
        push    dword [ebp + 0x10] ; push end index
        push    eax                ; push i+1
        push    dword [ebp + 0x8]  ; push elems vector
        call    quick_sort
        add     esp, 0xC        ; discard three items on the stack
        jmp     .qsort_done

.qsort_done:
        mov     eax, esi        ; store the first pointer to array into eax


        
        ;; rearrange to avoid negative appending-bug

        mov     ebx, 0          ;ebx is the counter for how many negative are there
        mov     ecx, -1
        .negative_loop:
        add     ecx, 1
        cmp     ecx, [length]     ; if all the items have been compared then jump
        jge     .preparasion

        ;; if integer is great or equal than 0 then next tiem
        cmp     dword[eax + (0x4*ecx)] , 0
        jge     .negative_loop

        ;; otherwise push it into tmp_array
        mov     edx, [eax+(ecx*4)]
        mov     dword[tmp_array + (0x4*ebx)], edx
        add     ebx, 1          ; the total number of negative +1
        jmp     .negative_loop

        .preparasion:
        ;;         push    dword[length]             ; push the size of the array
        ;;         push    some_array
        ;;         push    tmp_array
        ;;         call    print_array
        ;;         add     esp, 8
        mov     ecx, -1
        jmp     .positive_loop
        
        .positive_loop:
        add     ecx, 1
        cmp     ecx, [length]     ; if all the items have been compared then jump
        jge     .L2

        ;; if int is less than 0 then next item
        mov     edx, [eax+(ecx*4)]
        cmp     edx, 0
        jl      .positive_loop

        ;; otherwise push it into tmp_array
        add     ecx,    ebx
        mov     dword[tmp_array + (0x4*ecx)], edx
        sub     ecx,    ebx
        jmp     .positive_loop
        
        
.L2:


        
        pop     ebx
        pop     esi
        pop     edi

        mov     esp, ebp
        pop     ebp
        ret

;;;-----------------------------------------------------------------
;;; PrintArray(int array[], int length)
;;; this function outputs the array elements
print_array: 
        push    ebp                     ; set up the stack pointer
        mov     ebp, esp
        
        push    esi                     ; save used regs
        push    ecx
        
        mov     esi, [ebp+8]            ; esi points to the array
        mov     ecx, [ebp+12]             ; ecx = array.length

        .L1:
        push    esi                     ; save esi and ecx from
        push    ecx                     ; trashing by printf
        push    dword [esi]             ; output array[i]
        push    dformat                 ; decimal format
        call    printf
        add     esp, 8                   ; clean up the stack
        pop     ecx                      ; restore save regs for printf
        pop     esi
        add     esi, 4                   ; advance the array pointer by 4
        loop    .L1

        push    nl              ; start new line
        call    printf
        add     esp, 4

        ;; end the function
        pop     ecx                      ; restore used regs and exit
        pop     esi
        pop     ebp
        ret     8               ; This will also pop out 8 

end_program:
        ;; try exit using libc
        call    exit
        
        ;; end the program
        mov     esp, ebp	; takedown stack frame
        pop     ebp		; same as "leave" op

	mov	eax,0		; normal, no error, return value
	ret			; return

        leave
        ret
