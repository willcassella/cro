// FiberContext.cpp

#include <string.h>
#include "../include/cro/FiberContext.h"

thread_local struct cro_ThreadContext {
    cro::FiberContext* current_fiber;
    void* outer_sp;
} cro_thread_context;

extern "C" cro_ThreadContext* cro_get_thread_ctx(
) {
    return &cro_thread_context;
}

extern "C" void cro_asm_init(
    cro::FiberContext* ctx,
    void* stack,
    size_t stack_size,
    cro::Coroutine* coroutine
);

extern "C" int cro_asm_resume(
    cro_ThreadContext* thread_ctx,
    cro::FiberContext* fiber_ctx
);

extern "C" void cro_asm_suspend(
    cro_ThreadContext* ctx
);

cro::FiberContext cro::init_fiber_context(
    void* stack,
    size_t stack_size,
    Coroutine* coroutine
) {
    FiberContext ctx;
    memset(&ctx, 0, sizeof(FiberContext));
    cro_asm_init(&ctx, stack, stack_size, coroutine);
    return ctx;
}

int cro::resume(
    FiberContext* fiber_ctx
) {
    return cro_asm_resume(&cro_thread_context, fiber_ctx);
}

void cro::suspend(
) {
    if (!cro_thread_context.current_fiber) {
        return;
    }

    cro_asm_suspend(&cro_thread_context);
}
