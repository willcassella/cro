// Job.h
#pragma once

#include <thread>
#include <atomic>
#include <vector>
#include <functional>
#include "FiberContext.h"

namespace cro
{
    using JobFn = std::function<void(void*)>;

    enum class JobPriority {
        LOW,
        MEDIUM,
        HIGH,
    };

    struct JobFiber {
        JobFn job_fn;
        JobPriority parent_priority;
        uint32_t parent_index;
        std::atomic_uint32_t dependencies;
    };

    struct JobStack {
        void* addr;
        size_t size;
    };

    class JobManager {
    public:

        virtual void append_job();
    };
}
