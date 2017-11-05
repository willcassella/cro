section .text
    extern cro_get_thread_ctx
    global cro_asm_init, cro_asm_suspend, cro_asm_resume

cro_asm_init:
; Pre: rcx = cro::FiberContext_Win64*, rdx = stack, r8 = stack_size, r9 = coroutine
    ; Create base pointer
    add rdx, r8
    mov qword [rcx + 16], rdx

    ; Account for space for shadow + return address
    sub rdx, 40

    ; Write return address for coroutine to stack
    lea rax, [rel cro_asm_terminate]
    mov qword [rdx], rax

    ; Write to fiber context
    mov qword [rcx + 8], rdx
    mov qword [rcx], r9
    ret
; Post:

cro_asm_terminate:
; Pre:
    call cro_get_thread_ctx
    mov rcx, rax
    xor eax, eax
    lea rdx, [rel cro_restore_outer]
    jmp rdx
; Post: rax = return code (0), rcx = cro_ThreadContext*

cro_asm_resume:
; Pre: rcx = cro_ThreadContext*, rdx = cro::FiberContext_Win64*
    ; Save non-volatile from outer to stack
    push rbp
    push rbx
    push rdi
    push rsi
    push r12
    push r13
    push r14
    push r15

    ; Back up existing thread context
    push qword [rcx]
    push qword [rcx + 8]

    ; Save new thread context
    mov qword [rcx], rdx
    mov qword [rcx + 8], rsp

    ; Restore non-volatile registers from fiber
    mov rsp, qword [rdx + 8]
    mov rbp, qword [rdx + 16]
    mov rbx, qword [rdx + 24]
    mov rdi, qword [rdx + 32]
    mov rsi, qword [rdx + 40]
    mov r12, qword [rdx + 48]
    mov r13, qword [rdx + 56]
    mov r14, qword [rdx + 64]
    mov r15, qword [rdx + 72]

    ; Call back into fiber code
    jmp qword [rdx]
; Post: Prevous state on outer stack, available from thread context. Thread back in fiber state

cro_asm_suspend:
; Pre: rcx = cro_ThreadContext*
    mov rdx, qword [rcx]

    ; Fiber called suspend, so they still have more to do
    mov rax, 1

    ; Save fiber return address
    mov r9, qword [rsp]
    mov qword [rdx], r9

    ; Save non-volatile registers
    mov qword [rdx + 8], rsp
    mov qword [rdx + 16], rbp
    mov qword [rdx + 24], rbx
    mov qword [rdx + 32], rdi
    mov qword [rdx + 40], rsi
    mov qword [rdx + 48], r12
    mov qword [rdx + 56], r13
    mov qword [rdx + 64], r14
    mov qword [rdx + 72], r15
; Post: rax = return code (1), rcx = cro_ThreadContext*

cro_restore_outer:
; Pre: rax = return code, rcx = cro_ThreadContext*
    ; Restore outer stack pointer
    mov rsp, qword [rcx + 8]

    ; Restore previous thread context
    pop qword [rcx + 8]
    pop qword [rcx]

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
; Post: rax = return code, back in outer state
