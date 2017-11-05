// main.cpp

#include <stdio.h>
#include <stdlib.h>
#include "../include/cro/FiberContext.h"

void test_coroutine()
{
    printf("Coroutine started\n");

    for (int i = 0; i < 5; ++i)
    {
        printf("i = %d\n pausing coroutine...\n", i);

        /* Pause the current function! */
        cro::suspend();

        printf("...coroutine resumed\n");
    }

    printf("Coroutine finished\n");
}

int main()
{
    /* Initialize a coroutine */
    void* stack = malloc(1024 * 64);
    auto ctx = cro::init_fiber_context(stack, 1024 * 64, test_coroutine);

    // Keep calling until completion
    while (cro::resume(&ctx));
    {
        printf("Back in main\n");
    }

    getchar();
    free(stack);
}
