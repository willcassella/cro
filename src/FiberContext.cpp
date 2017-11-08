// FiberContext.cpp

#include <string.h>
#include "../include/cro/FiberContext.h"

thread_local struct cro_ThreadContext {
    cro::FiberContext* current_fiber;
    void* outer_sp;
    void* invoke_userdata;
} cro_thread_context;

extern "C" void cro_asm_init(
    cro::FiberContext* ctx,
    void* stack,
    size_t stack_size,
    cro::Coroutine* coroutine,
    void* arg
);

extern "C" int cro_asm_resume(
    cro_ThreadContext* thread_ctx,
    cro::FiberContext* fiber_ctx,
    void* userdata,
    cro::SuspendResult should_unwind
);

extern "C" cro::SuspendResult cro_asm_suspend(
    cro_ThreadContext* ctx
);

struct cro_UnwindException {
};

extern "C" cro_ThreadContext* cro_coroutine_root(
    cro::Coroutine* coroutine,
    void* arg
) {
    try {
        coroutine(arg);
    }
    catch (cro_UnwindException) {
    }

    return &cro_thread_context;
}

cro::FiberContext cro::init_fiber_context(
    void* stack,
    size_t stack_size,
    Coroutine coroutine,
    void* arg
) {
    FiberContext ctx;
    memset(&ctx, 0, sizeof(FiberContext));
    cro_asm_init(&ctx, stack, stack_size, coroutine, arg);
    return ctx;
}

int cro::resume(
    FiberContext& fiber_ctx,
    void* userdata
) {
    return cro_asm_resume(&cro_thread_context, &fiber_ctx, userdata, SR_CONTINUE);
}

cro::SuspendResult cro::suspend(
) {
    auto const should_unwind = cro_asm_suspend(&cro_thread_context);
    if (should_unwind) {
        throw cro_UnwindException{};
    }
    return should_unwind;
}

void cro::unwind(
    cro::FiberContext& fiber_ctx
) {
    cro_asm_resume(&cro_thread_context, &fiber_ctx, nullptr, SR_UNWIND);
}
