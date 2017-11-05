// FiberContext_Win64.h
#pragma once

#include <stdint.h>

namespace cro
{
    struct FiberContext_Win64 {
        /* Basic pointers (return address, stack, base) */
        void const* ret;
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
    };
}
