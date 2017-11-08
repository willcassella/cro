// main.cpp

#include <stdio.h>
#include <stdlib.h>
#include "../include/cro/FiberContext.h"

struct RAII {
    ~RAII() {
        printf("Destructor called\n");
    }
};

void test_coroutine(void* const arg)
{
    puts("Coroutine started");
    RAII raii;

    int* const out = (int*)arg;

    for (int i = 0; i < 5; ++i)
    {
        printf("i = %d\n pausing coroutine...\n", i);

        /* Pause the current function! */
        *out = i;
        cro::suspend();

        puts("...coroutine resumed");
    }

    puts("Coroutine finished");
}

int main()
{
    /* Initialize a coroutine */
    void* stack = malloc(1024 * 64);
    int i = 0;
    auto ctx = cro::init_fiber_context(stack, 1024 * 64, test_coroutine, &i);

    // Keep calling until completion
    while (cro::resume(ctx, nullptr))
    {
        puts("Back in main");
    }

    getchar();
    free(stack);
}
