.code
cro_asm_start proc frame
.setframe rbp, 0
.endprolog
; Pre: rbx = fiber_fn:cro::FiberFn*, rdi = root_fn:cro_RootFn*, rsi = arg:void*
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
cro_asm_start endp

cro_asm_init proc
; Pre: rcx = ctx:cro::FiberContext*, rdx = stack:void*, r8 = stack_size:size_t, r9 = root_fn:cro_RootFn*, [rsp+40] = coroutine_fn:cro::Coroutine*, [rsp+48] = arg:void*
    ; Create base pointer
    add rdx, r8
    sub rdx, 24

    ; Write null for base pointer and return address to fiber stack
    mov qword ptr [rdx + 8], 0
    mov qword ptr [rdx + 16], 0

    ; Write return address to fiber stack
    lea rax, cro_asm_start
    mov qword ptr [rdx], rax

    ; Write base pointer (rbp) to fiber stack
    lea rax, [rdx + 8]
    mov qword ptr [rdx - 8], rax

    ; Write fiber_fn (rbx) to fiber stack
    mov rax, qword ptr [rsp + 40]
    mov qword ptr [rdx - 16], rax

    ; Write root_fn (rdi) to fiber stack
    mov qword ptr [rdx - 24], r9

    ; Write arg (rsi) to fiber stack
    mov rax, qword ptr [rsp + 48]
    mov qword ptr [rdx - 32], rax

    ; Compute stack pointer (account for r12 - r15, xmm6 - xmm15) and write to ctx
    sub rdx, 224
    mov qword ptr [rcx], rdx

    ret
; Post:
cro_asm_init endp

cro_asm_switch proc
; Pre: rcx = from:cro::FiberContext*, rdx = to:cro::FiberContext*, r8d = should_unwind:cro::SuspendResult
    ; Back up non-volatile GP registers
    push rbp
    push rbx
    push rdi
    push rsi
    push r12
    push r13
    push r14
    push r15

    ; Back up xmm registers
    sub rsp, 160
    movdqu xmmword ptr [rsp + 144], xmm6
    movdqu xmmword ptr [rsp + 128], xmm7
    movdqu xmmword ptr [rsp + 112], xmm8
    movdqu xmmword ptr [rsp + 96], xmm9
    movdqu xmmword ptr [rsp + 80], xmm10
    movdqu xmmword ptr [rsp + 64], xmm11
    movdqu xmmword ptr [rsp + 48], xmm12
    movdqu xmmword ptr [rsp + 32], xmm13
    movdqu xmmword ptr [rsp + 16], xmm14
    movdqu xmmword ptr [rsp], xmm15

    ; Save stack pointer
    mov qword ptr [rcx], rsp
; Post: rdx = to:cro::FiberContext*, r8d = should_unwind:cro::SuspendResult

cro_asm_restore label ptr
; Pre: rdx = to:cro::FiberContext*, r8d = should_unwind:cro::SuspendResult
    ; Restore stack pointer from 'to'
    mov rsp, qword ptr [rdx]

    ; Null out the stack pointer to ensure they don't end up re-resuming this fiber accidentally
    mov qword ptr [rdx], 0

    ; Restore xmm registers
    movdqu xmm15, xmmword ptr [rsp]
    movdqu xmm14, xmmword ptr [rsp + 16]
    movdqu xmm13, xmmword ptr [rsp + 32]
    movdqu xmm12, xmmword ptr [rsp + 48]
    movdqu xmm11, xmmword ptr [rsp + 64]
    movdqu xmm10, xmmword ptr [rsp + 80]
    movdqu xmm9, xmmword ptr [rsp + 96]
    movdqu xmm8, xmmword ptr [rsp + 112]
    movdqu xmm7, xmmword ptr [rsp + 128]
    movdqu xmm6, xmmword ptr [rsp + 144]
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
cro_asm_switch endp
end
