// FiberContext.cpp

#include <assert.h>
#include <string.h>
#include "../include/cro/FiberContext.h"

thread_local struct cro_ThreadContext {
    cro::FiberContext* current_fiber = nullptr;
    cro::FiberContext thread_main;
} cro_thread_context;

using cro_RootFn = cro::FiberContext*(
    cro::FiberFn* fiber_fn,
    void* arg
);

extern "C" void cro_asm_init(
    cro::FiberContext* ctx,
    void* stack,
    size_t stack_size,
    cro_RootFn* root_fn,
    cro::FiberFn* fiber_fn,
    void* arg
);

extern "C" cro::SuspendResult cro_asm_switch(
    cro::FiberContext* from,
    cro::FiberContext* to,
    cro::SuspendResult should_unwind
);

struct cro_UnwindException {
};

extern "C" cro::FiberContext* cro_fiber_root(
    cro::FiberFn* fiber_fn,
    void* arg
) {
    try {
        fiber_fn(arg);
    }
    catch (cro_UnwindException) {
    }

    cro_thread_context.current_fiber->state = cro::FiberState::FINISHED;
    return &cro_thread_context.thread_main;
}

cro::FiberContext cro::init_fiber_context(
    void* stack,
    size_t stack_size,
    FiberFn* fiber_fn,
    void* arg
) {
    FiberContext ctx;
    ctx.state = FiberState::NOT_STARTED;
    cro_asm_init(&ctx, stack, stack_size, &cro_fiber_root, fiber_fn, arg);
    return ctx;
}

bool cro::resume(
    FiberContext& fiber_ctx,
    SuspendResult should_unwind
) {
    // Attempting to resume a currently running fiber is a design error and should never be permitted to occur
    assert(fiber_ctx.state != FiberState::RUNNING);

    // If they're trying to resume a fiber that's already completed
    if (fiber_ctx.state == FiberState::FINISHED)
    {
        return false;
    }

    // If they're trying to unwind a fiber that hasn't started yet
    if (fiber_ctx.state == FiberState::NOT_STARTED && should_unwind)
    {
        fiber_ctx.state = FiberState::FINISHED;
        return false;
    }

    fiber_ctx.state = FiberState::RUNNING;

    // If the current thread is not a fiber
    if (!cro_thread_context.current_fiber) {
        cro_thread_context.current_fiber = &fiber_ctx;
        cro_asm_switch(&cro_thread_context.thread_main, &fiber_ctx, should_unwind);
        cro_thread_context.current_fiber = nullptr;
        return fiber_ctx.state != FiberState::FINISHED;
    }

    cro_thread_context.current_fiber->state = FiberState::SUSPENDED;
    cro_thread_context.current_fiber = &fiber_ctx;
    SuspendResult const should_i_unwind = cro_asm_switch(cro_thread_context.current_fiber, &fiber_ctx, should_unwind);

    // Note: CANNOT access 'cro_thread_context' below here, otherwise run risk of writing to different thread's context!

    if (should_i_unwind) {
        throw cro_UnwindException{};
    }

    return fiber_ctx.state != FiberState::FINISHED;
}

void cro::suspend(
) {
    // If the current thread is not a fiber
    if (!cro_thread_context.current_fiber) {
        return;
    }

    cro_thread_context.current_fiber->state = FiberState::SUSPENDED;
    SuspendResult const should_i_unwind = cro_asm_switch(cro_thread_context.current_fiber, &cro_thread_context.thread_main, SR_CONTINUE);

    // Note: CANNOT access 'cro_thread_context' below here, otherwise run risk of writing to different thread's context!

    if (should_i_unwind) {
        throw cro_UnwindException{};
    }
}
