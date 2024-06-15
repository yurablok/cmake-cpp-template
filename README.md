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

Clang, TODO

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

## Cross-compilation with Docker

1. Prepare a copy of target sysroot. For example:
```sh
rsync -az --progress login@ip:/etc sysroot
rsync -az --progress login@ip:/lib sysroot
rsync -az --progress login@ip:/usr/include sysroot/usr
rsync -az --progress login@ip:/usr/lib/aarch64-linux-gnu sysroot/usr/lib
rsync -az --progress login@ip:/usr/lib/qt5 sysroot/usr/lib
rm -rf sysroot/usr/lib/aarch64-linux-gnu/dri
https://raw.githubusercontent.com/riscv/riscv-poky/master/scripts/sysroot-relativelinks.py sysroot
tar cf - sysroot -P | gzip > sysroot.tar.gz
```

2. Example of a `Dockerfile`:
```Dockerfile
# GCC 10.5, GCC 12.3, CMake 3.22
FROM ubuntu:22.04
# GCC 10.5, GCC 13, CMake 3.25
#FROM ubuntu:23.04

RUN mkdir /sysroot
ADD sysroot.tar.gz /

# Optional, for dumping debug symbols
ADD --chmod=755 breakpad_dump_syms /usr/local/bin/

RUN apt update \
 && apt -y install --no-install-recommends \
    cmake \
    xz-utils \
    wget \
    ninja-build \
    git \
    ssh \
    sshpass \
    pkg-config \
    libudev-dev \
    build-essential \
    binutils-aarch64-linux-gnu \
    gcc-12-aarch64-linux-gnu \
    g++-12-aarch64-linux-gnu \
    g++-12 \
    qtbase5-dev \
 && apt clean \
 && rm -rf /var/lib/apt/lists/* \
 && mv /sysroot/usr/lib/aarch64-linux-gnu/qt5/bin/ \
       /sysroot/usr/lib/aarch64-linux-gnu/qt5/bin.arm/ \
 && cp -RL /usr/lib/x86_64-linux-gnu/qt5/bin/ \
           /sysroot/usr/lib/aarch64-linux-gnu/qt5/ \
 && mv /sysroot/usr/lib/qt5/bin/ \
       /sysroot/usr/lib/qt5/bin.arm/ \
 && cp -RL /usr/lib/x86_64-linux-gnu/qt5/bin/ \
           /sysroot/usr/lib/qt5/bin/ \
 \
 && git config --global http.sslverify false \
 && git config --global --add safe.directory "*" \
 \
# https://github.com/rui314/mold/blob/main/dist.sh
 && git clone --branch v2.4.0 --filter=tree:0 --recurse-submodules https://github.com/rui314/mold.git /mold \
 && cd /mold \
 && cmake -DCMAKE_BUILD_TYPE=Release -DMOLD_MOSTLY_STATIC=On . \
 && cmake --build . -j$(nproc) \
 && cmake --install . --strip \
 && rm -rf /mold \
 && ln -s /usr/local/bin/mold /usr/bin/aarch64-linux-gnu-ld.mold \
 \
 && apt -y purge g++-12

RUN echo "#!/usr/bin/bash\n\
cmake \$@ \
-DCMAKE_CXX_COMPILER_ARCHITECTURE_ID=aarch64 \
-DCMAKE_CXX_COMPILER=/bin/aarch64-linux-gnu-g++-12 \
-DCMAKE_C_COMPILER=/bin/aarch64-linux-gnu-gcc-12 \
-DCMAKE_STRIP=/bin/aarch64-linux-gnu-strip \
-DCMAKE_SYSROOT=/sysroot \
-DQt5_DIR=/sysroot/usr/lib/aarch64-linux-gnu/cmake/Qt5 \
-DBREAKPAD_DUMP_SYMS=/usr/local/bin/breakpad_dump_syms \
-DCMAKE_BUILD_RPATH=\"\
/sysroot/usr/lib;\
/sysroot/lib/aarch64-linux-gnu;\
/sysroot/usr/lib/aarch64-linux-gnu\
\"" \
    > /usr/bin/crosscmake.sh \
 && chmod +x /usr/bin/crosscmake.sh
```

3. Run crosscmake.sh in `build/.cmake/{configuration}` on the root of your project:
```python
from ntpath import join
import os, sys

args = "../../.. "
if len(sys.argv) > 1:
    args += " ".join(sys.argv[1:])

os.system("docker run"
    " --rm"
    " -v " + os.getcwd() + ":/project"
    " -w /project/build/.cmake/arm64-Release-Linux"
    " my_docker_image_crosscompiler:latest"
    " /usr/bin/crosscmake.sh -G Ninja -DBUILD_ARCH=arm64 "
    + args)
```

4. Build:
```python
import os

os.system("docker run"
    " --rm"
    " -t"
    " -v " + os.getcwd() + ":/project"
    " -w /project/build/.cmake/arm64-Release-Linux"
    " my_docker_image_crosscompiler:latest"
    " ninja")
```
