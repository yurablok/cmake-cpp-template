# CMake C++ Project Template

This template is designed for organizing cross-platform C++ projects, aimed at
solving the main issues of maintaining a clean project structure and convenient
work using VSCode and MS VisualStudio.

## TODO

Clang, cross-compilation, TODO

## Project's tree

TODO: `build/.cmake/arch/...`, `deps`, `workdir/bin`...

## Multiprocessor compilation

|  Tool  | Compiler | Platform | Parameter |
|:------:|:--------:|:--------:|:----------|
| VSCode |   GCC    |  Linux   | `.vscode/settings.json`: `"cmake.parallelJobs": N`
| VSCode |  Clang   |  Linux   |   TODO
| VSCode |   MSVC   | Windows  |   TODO
| VSCode |  Clang   | Windows  |   TODO
|  MSVS  |   MSVC   | Windows  | `application/CMakeLists.txt`: `target_compile_options /MP`
|  MSVS  |  Clang   | Windows  |   TODO
| cmake  |   GCC    |  Linux   | `make -jN`
| cmake  |  Clang   |  Linux   |   TODO

## Program's arguments

|  Tool  | Platform | Parameter |
|:------:|:--------:|:----------|
| VSCode |  Linux   | `.vscode/settings.json`: `"args": []`
|  MSVS  | Windows  | `init_project("app" "--arg1 --arg2")`
| VSCode | Windows  |   TODO

> NOTE: VSCode: workdir can't be configured when running target without debugging

## Qt support

TODO: translations, `.gitattributes`...

