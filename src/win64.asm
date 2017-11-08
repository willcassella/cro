section .text
    extern cro_coroutine_root
    global cro_asm_init, cro_asm_suspend, cro_asm_resume

cro_asm_start:
; Pre: eax = should_unwind, rbx = cro::Coroutine*, rcx = cro_ThreadContext* rdi = userdata
    ; See if caller wants to unwind (special case: unwinding before ever calling to begin with)
    test eax, eax
    xor eax, eax
    jnz cro_restore_outer
; Post: rax = return code (0), rcx = cro_ThreadContext*

    ; Move arguments into Win64 convention
    mov rcx, rbx
    mov rdx, rdi

    ; Allocate shadow space
    sub rsp, 32

    ; Call into coroutine
    call cro_coroutine_root

    ; Restore outer
    mov rcx, rax
    xor eax, eax
    jmp cro_restore_outer
; Post: eax = return code (0), rcx = cro_ThreadContext*

cro_asm_init:
; Pre: rcx = cro::FiberContext_Win64*, rdx = stack, r8 = stack_size, r9 = coroutine, [rsp + 40] = arg
    ; Create base pointer
    add rdx, r8
    mov qword [rcx + 8], rdx
    mov qword [rdx], 0

    ; Create stack pointer and write return address (cro_asm_start) to stack
    sub rdx, 8
    lea rax, [rel cro_asm_start]
    mov qword [rdx], rax

    ; Write stack pointer
    mov qword [rcx], rdx

    ; Assign arguments
    mov rax, qword [rsp + 40]
    mov qword [rcx + 16], r9
    mov qword [rcx + 24], rax

    ret
; Post:

cro_asm_resume:
; Pre: rcx = cro_ThreadContext*, rdx = cro::FiberContext_Win64*, r8 = userdata, r9d = should_unwind
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
    push qword [rcx + 16]

    ; Save new thread context
    mov qword [rcx], rdx
    mov qword [rcx + 8], rsp
    mov qword [rcx + 16], r8

    ; Restore non-volatile registers from fiber
    mov rsp, qword [rdx]
    mov rbp, qword [rdx + 8]
    mov rbx, qword [rdx + 16]
    mov rdi, qword [rdx + 24]
    mov rsi, qword [rdx + 32]
    mov r12, qword [rdx + 40]
    mov r13, qword [rdx + 48]
    mov r14, qword [rdx + 56]
    mov r15, qword [rdx + 64]

    ; Call back into fiber code
    mov eax, r9d
    ret
; Post: eax = should_unwind, rcx = cro_ThreadContext*

cro_asm_suspend:
; Pre: rcx = cro_ThreadContext*
    ; Fiber called suspend, so they still have more to do
    mov eax, 1

    ; Get cro::FiberContext*
    mov rdx, qword [rcx]

    ; Save non-volatile registers
    mov qword [rdx], rsp
    mov qword [rdx + 8], rbp
    mov qword [rdx + 16], rbx
    mov qword [rdx + 24], rdi
    mov qword [rdx + 32], rsi
    mov qword [rdx + 40], r12
    mov qword [rdx + 48], r13
    mov qword [rdx + 56], r14
    mov qword [rdx + 64], r15
; Post: eax = return code (1), rcx = cro_ThreadContext*

cro_restore_outer:
; Pre: rax = return code, rcx = cro_ThreadContext*
    ; Restore outer stack pointer
    mov rsp, qword [rcx + 8]

    ; Restore previous thread context
    pop qword [rcx + 16]
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
; Post: eax = return code, back in outer state
