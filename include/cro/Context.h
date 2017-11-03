// Context.h
#pragma once

#include <stdlib.h>
#include <stdint.h>
#include <string.h>

namespace cro
{
    struct Context_win64;
    using Coroutine_win64 = void(Context_win64*);

    struct Context_win64 {
        /* Basic pointers (return address, stack, base) */
        Coroutine_win64* ret;
        void* rsp;
        void* rbp;

        /* Non-volatile registers */
        uint64_t rbx;
        uint64_t rdi;
        uint64_t rsi;
        uint64_t r12;
        uint64_t r13;
        uint64_t r14;
        uint64_t r15;

        static Context_win64 init(
            size_t const stack_size,
            Coroutine_win64* const fn
        ) {
            Context_win64 ctx;
            memset(&ctx, 0, sizeof(ctx));

            // Initialize stack
            char* const buff = (char*)malloc(stack_size);
            ctx.rbp = buff + stack_size;
            ctx.rsp = buff + stack_size - 16;

            // Initialize calling address
            ctx.ret = fn;
            return ctx;
        }

        int resume();
        void suspend();
    };

    typedef Context_win64 Context;
}

/* Restores the state of the currently executing thread from the given context object.
* Returns if the coroutine has completed. */
extern "C" int cro_resume(
    cro::Context const* ctx
);

/* Suspends the state of the currently executing thread to the given context object. */
extern "C" void cro_suspend(
    cro::Context* ctx
);

inline int cro::Context_win64::resume() {
    return cro_resume(this);
}

inline void cro::Context_win64::suspend() {
    cro_suspend(this);
}
