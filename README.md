# cro
#### Coroutines/Fibers for C++

After spending some time trying to learn assembly, I wanted to actually make use of it by writing something that _couldn't_ be implemented
in standard C or C++: coroutines.

There is currenly a technical specification for making coroutines an official part of the C++ language, but that is for stackless
coroutines which make different tradeoffs than stackful ones do, and having both at your disposal is useful.

Current features:
- Ability to treat any argument-less, return-less function as a coroutine
- Windows x64 support

Planned features:
- System V ABI support (Linux, Mac)
- Investigate WASM support (may not be possible yet)
- Argument support
- Performance improvements
- Yield wrapper library
- Job-based parallelism wrapper library
- Support early destruction of coroutine objects

Not planned features:
- x86 support
