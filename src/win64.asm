section .text
    global cro_suspend, cro_resume

cro_resume:
    ; Save non-volatile from outer to stack
    push rbp
    push rbx
    push rdi
    push rsi
    push r12
    push r13
    push r14
    push r15

    ; Swap outer stack pointer with fiber stack pointer
    mov rdx, rsp
    mov rsp, qword [rcx + 8]
    mov qword [rcx + 8], rdx

    ; Restore non-volatile registers from fiber
    mov rbp, qword [rcx + 16]
    mov rbx, qword [rcx + 24]
    mov rdi, qword [rcx + 32]
    mov rsi, qword [rcx + 40]
    mov r12, qword [rcx + 48]
    mov r13, qword [rcx + 56]
    mov r14, qword [rcx + 64]
    mov r15, qword [rcx + 72]

    ; Push context onto stack, in case we return
    push rcx

    ; Call back into fiber code
    call [rcx]

    ; If we return here, that means fiber exited
    pop rcx
    mov rax, 0
    jmp cro_restore_outer

cro_suspend:
    ; Fiber called suspend, so they still have more to do
    mov rax, 1

    ; Save fiber return address
    mov rdx, qword [rsp]
    mov qword [rcx], rdx

    ; Save non-volatile registers
    mov qword [rcx + 16], rbp
    mov qword [rcx + 24], rbx
    mov qword [rcx + 32], rdi
    mov qword [rcx + 40], rsi
    mov qword [rcx + 48], r12
    mov qword [rcx + 56], r13
    mov qword [rcx + 64], r14
    mov qword [rcx + 72], r15

cro_restore_outer:

    ; Swap fiber stack pointer with outer stack pointer
    mov rdx, rsp
    mov rsp, qword [rcx + 8]
    mov qword [rcx + 8], rdx

    ; Restore outer's non-volatile from stack
    pop r15
    pop r14
    pop r13
    pop r12
    pop rsi
    pop rdi
    pop rbx
    pop rbp

    ; Return to outer
    ret
