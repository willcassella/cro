// FiberContext.h
#pragma once

namespace cro
{
    enum class FiberState
    {
        FINISHED,
        NOT_STARTED,
        RUNNING,
        SUSPENDED,
    };

    struct FiberContext
    {
        /* All platform-specific registers are stored on the stack. */
        void* stack_pointer = nullptr;

        /* Current state of this fiber */
        FiberState state = FiberState::FINISHED;
    };

    using FiberFn = void(void*);

    enum SuspendResult {
        SR_CONTINUE = 0,
        SR_UNWIND = 1,
    };

    FiberContext init_fiber_context(
        void* stack,
        size_t stack_size,
        FiberFn* fiber_fn,
        void* arg
    );

    bool resume(
        FiberContext& fiber_ctx,
        SuspendResult should_unwind = SR_CONTINUE
    );

    void suspend(
    );
}
