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

    using Coroutine = void();

    FiberContext init_fiber_context(
        void* stack,
        size_t stack_size,
        Coroutine* coroutine
    );

    int resume(
        FiberContext* fiber_ctx
    );

    void suspend(
    );
}
