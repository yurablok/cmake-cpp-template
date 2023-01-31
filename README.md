# CMake C++ Project Template

This template is designed for organizing cross-platform C++ projects, aimed at
solving the main issues of maintaining a clean project structure and convenient
work using VSCode and MS VisualStudio.

## Benefits and features

- Based on `CMakePresets.json`.
- The default release build now includes minimal debug info, that is useful for backtracing.  
  - `RelWithDebInfo` renamed to `Release` and cofigured, `Release` renamed to `RelNoDebInfo`.
- Target binaries are placed separately from all other build artifacts.
  - `build/arch_type_platform/`
- CMake cache and other build artifacts are placed into separate directories to minimize
  rebuilding when the build type changes.
  - `build/.cmake/arch_type_platform/`
- A single shared working directory to minimize duplication of runtime resources.
  - `workdir/`
- `add_option` as better variant of `set(...CACHE...)` that has the next features:
  - More simple and intuitive interface.
  - 5 data types with some strict rules.
  - All the options have `OPTION_` prefix that simplifies working with CMakeCache
    when you have only a text editor.
  - All the options are automatically defined as macros for desired targets.
- Git utilities.
  - `fetch_git` as better variant of `FetchContent_...` that is useful for additional
    projects such as examples or tests (for main projects use classic git submodules
    or package managers) and has the next features:
    - More simple and intuitive interface.
    - Better work speed.
    - Aimed to work as classic git submodules.
  - `git_commits_count_by_regex` & `git_commits_count_by_tag`.
- Qt5 support.
  - Autosearch (simple) for Qt5 libraries if `Qt5_DIR` is not specified.
  - Custom `qt5_create_ts_and_qm(...)` that minimizes calls of `lrelease` if `lupdate`
    returns zero changes.
- MS Visual Studio support.
  - Generating of `.vs/launch.vs.json`.  
    NOTE: You have to [constantly choose the right debug target](https://developercommunity.visualstudio.com/t/Auto-previous-debug-target-with-CMake/10116208)
    for the workdir and Qt libraries to work.
- VSCode support.
  - Lots of tweaks in `.vscode/settings.json`.

## Steps terminology

| № |    Step   |   Participants   |
|:-:|:---------:|:----------------:|
| 1 |  prepare  |     git, etc     |
| 2 | configure |    cmake, git    |
| 3 |  compile  | compilers, cmake |
| 4 |    run    |   applications   |

## TODO

Clang, cross-compilation, TODO

## Multiprocessor compilation

|  Tool  | Compiler | Platform | Parameter |
|:------:|:--------:|:--------:|:----------|
| VSCode |   GCC    |  Linux   | `.vscode/settings.json`: `"cmake.parallelJobs": N`
| VSCode |  Clang   |  Linux   |   TODO
| VSCode |   MSVC   | Windows  |   TODO
| VSCode |  Clang   | Windows  |   TODO
|  MSVS  |   MSVC   | Windows  | `CMakeUtils.cmake`: `target_compile_options /MP`
|  MSVS  |  Clang   | Windows  |   TODO
| cmake  |   GCC    |  Linux   | `make -jN`, `ninja -jN`
| cmake  |  Clang   |  Linux   | `make -jN`, `ninja -jN`

## Program's arguments

|  Tool  | Platform | Parameter |
|:------:|:--------:|:----------|
| VSCode |  Linux   | `.vscode/settings.json`: `"args": []`
|  MSVS  | Windows  | `init_project("client --ip=localhost" "server")`
| VSCode | Windows  |   TODO

> NOTE: VSCode: workdir can't be configured when running target without debugging
