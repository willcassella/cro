section .text
    global cro_asm_init, cro_asm_switch

cro_asm_start:
; Pre: rbx = fiber_fn:cro::FiberFn*, rdi = root_fn:cro_RootFn*, rsi = arg:void*
    ; Patch callstack
    mov rbp, rax

    ; Move arguments into Win64 convention
    mov rcx, rbx
    mov rdx, rsi

    ; Allocate shadow space
    sub rsp, 32

    ; Call into coroutine
    call rdi

    ; Restore outer
    mov rdx, rax
    xor r8d, r8d
    jmp cro_asm_restore
; Post: rdx = to:cro::FiberContext*, r8d = should_unwind:cro::SuspendResult(SR_CONTINUE)

cro_asm_init:
; Pre: rcx = ctx:cro::FiberContext*, rdx = stack:void*, r8 = stack_size:size_t, r9 = root_fn:cro_RootFn*, [rsp+40] = coroutine_fn:cro::Coroutine*, [rsp+48] = arg:void*
    ; Create base pointer
    add rdx, r8
    sub rdx, 24

    ; Write null for base pointer and return address to fiber stack
    mov qword [rdx + 8], 0
    mov qword [rdx + 16], 0

    ; Write return address to fiber stack
    lea rax, [rel cro_asm_start]
    mov qword [rdx], rax

    ; Write base pointer (rbp) to fiber stack
    lea rax, [rdx + 8]
    mov qword [rdx - 8], rax

    ; Write fiber_fn (rbx) to fiber stack
    mov rax, qword [rsp + 40]
    mov qword [rdx - 16], rax

    ; Write root_fn (rdi) to fiber stack
    mov qword [rdx - 24], r9

    ; Write arg (rsi) to fiber stack
    mov rax, qword [rsp + 48]
    mov qword [rdx - 32], rax

    ; Compute stack pointer (account for r12 - r15, xmm6 - xmm15) and write to ctx
    sub rdx, 224
    mov qword [rcx], rdx

    ret
; Post:

cro_asm_switch:
; Pre: rcx = from:cro::FiberContext*, rdx = to:cro::FiberContext*, r8d = should_unwind:cro::SuspendResult
    ; Back up non-volatile GP registers
    push rbp
    mov rax, rsp
    push rbx
    push rdi
    push rsi
    push r12
    push r13
    push r14
    push r15

    ; Back up xmm registers
    sub rsp, 160
    movdqu oword [rsp + 144], xmm6
    movdqu oword [rsp + 128], xmm7
    movdqu oword [rsp + 112], xmm8
    movdqu oword [rsp + 96], xmm9
    movdqu oword [rsp + 80], xmm10
    movdqu oword [rsp + 64], xmm11
    movdqu oword [rsp + 48], xmm12
    movdqu oword [rsp + 32], xmm13
    movdqu oword [rsp + 16], xmm14
    movdqu oword [rsp], xmm15

    ; Save stack pointer
    mov qword [rcx], rsp
; Post: rdx = to:cro::FiberContext*, r8d = should_unwind:cro::SuspendResult

cro_asm_restore:
; Pre: rdx = to:cro::FiberContext*, r8d = should_unwind:cro::SuspendResult
    ; Restore stack pointer from 'to'
    mov rsp, qword [rdx]

    ; Null out the stack pointer to ensure they don't end up re-resuming this fiber accidentally
    mov qword [rdx], 0

    ; Restore xmm registers
    movdqu xmm15, oword [rsp]
    movdqu xmm14, oword [rsp + 16]
    movdqu xmm13, oword [rsp + 32]
    movdqu xmm12, oword [rsp + 48]
    movdqu xmm11, oword [rsp + 64]
    movdqu xmm10, oword [rsp + 80]
    movdqu xmm9, oword [rsp + 96]
    movdqu xmm8, oword [rsp + 112]
    movdqu xmm7, oword [rsp + 128]
    movdqu xmm6, oword [rsp + 144]
    add rsp, 160

    ; Restore non-volatile GP registers
    pop r15
    pop r14
    pop r13
    pop r12
    pop rsi
    pop rdi
    pop rbx
    pop rbp

    ; Jump back into fiber code
    mov eax, r8d
    ret
; Post: eax = should_unwind:cro::SuspendResult
