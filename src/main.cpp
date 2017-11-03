// main.cpp

#include <stdio.h>
#include "../include/cro/Context.h"

void test_coroutine(cro::Context* ctx)
{
    printf("Coroutine started\n");

    for (int i = 0; i < 5; ++i)
    {
        printf("i = %d\n pausing coroutine...\n", i);

        /* Pause the current function! */
        ctx->suspend();

        printf("...coroutine resumed\n");
    }

    printf("Coroutine finished\n");
}

int main()
{
    /* Initialize a coroutine */
    cro::Context ctx = cro::Context::init(1024 * 64, test_coroutine);

    // Keep calling until completion
    while (ctx.resume())
    {
        printf("Back in main\n");
    }

    getchar();
}
