// FiberContext.h
#pragma once

#include "FiberContext_Win64.h"

namespace cro
{
#ifdef _WIN64
    using FiberContext = FiberContext_Win64;
#else
#   error Compiling cro on unsupported platform
#endif

    using Coroutine = void(void*);

    enum SuspendResult {
        SR_CONTINUE = 0,
        SR_UNWIND = 1,
    };

    FiberContext init_fiber_context(
        void* stack,
        size_t stack_size,
        Coroutine coroutine,
        void* arg
    );

    int resume(
        FiberContext& fiber_ctx,
        void* userdata
    );

    SuspendResult suspend(
    );

    void unwind(
        FiberContext& fiber_ctx
    );
}
