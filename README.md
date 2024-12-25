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
- `add_metainfo` that allows adding icon, version, and other information to binary files
  in different ways at the same time:
  - Universal: generated source code `{application}.metainfo.h & c`:
    <details>
      <summary>Example</summary>

      ```cmake
      add_metainfo(${PROJECT_NAME}
          VERSION 1.2.3.4-alpha5
          DESCRIPTION "Application Template"
          PRODUCT "CMake C++ Template"
          COMPANY "HOME Co."
          COPYRIGHT "© 2007-2024 HOME Co. All rights reserved."
          ICON "icon"
      )
      ```
      ```c
      const char* application_Version(); // "1.2.3.4-alpha5"
      uint16_t application_VersionMajor(); // 1
      uint16_t application_VersionMinor(); // 2
      uint16_t application_VersionPatch(); // 3
      uint16_t application_VersionBuild(); // 4
      const char* application_VersionQualifier(); // "alpha5"
      uint32_t application_VersionU32(); // if it fits into 4 bytes
      uint64_t application_VersionU64(); // if it fits into 8 bytes
      ```
      ```cmake
      add_metainfo(${PROJECT_NAME}
          VERSION 3333-pre-release
      )
      ```
      ```c
      const char* application_Version(); // "3333-pre-release"
      uint16_t application_VersionMajor(); // 3333
      uint16_t application_VersionMinor(); // 0
      uint16_t application_VersionPatch(); // 0
      uint16_t application_VersionBuild(); // 0
      const char* application_VersionQualifier(); // "pre-release"
      uint64_t application_VersionU64(); // 0x0D05'0000'0000'0000
      ```
    </details>
  - Universal: embedded strings in non-strict according to
    [SCCS](https://en.wikipedia.org/wiki/Source_Code_Control_System).
  - Platform-specific: Windows-resource `.rc`, ELF-sections,
    MacOS-resource TODO:`Info.plist`.
    <details>
      <summary>Examples of working with SCCS and ELF-sections</summary>
    
      ```shell
      $ grep --binary-files=text "@(#)" application
      @(#) Version: v1.2.3.4-alpha5
      @(#) Description: Application Template
      @(#) Product Name: CMake C++ Template
      @(#) Company Name: HOME Co.
      @(#) Copyright: © 2007-2024 HOME Co. All rights reserved.
      ```
      ```shell
      $ grep --binary-files=text "\$Id:" application
      $Id: v1.2.3.4-alpha5 | Application Template | CMake C++ Template | HOME Co. | © 2007-2024 HOME Co. All rights reserved. $
      ```
      ```shell
      $ readelf -p .note.version -p .note.description -p .note.product -p .note.company -p .note.copyright application

      String dump of section '.note.company':
        [     c]  company
        [    14]  HOME Co.


      String dump of section '.note.copyright':
        [     4]  +
        [     c]  copyright
        [    18]   2007-2024 HOME Co. All rights reserved.


      String dump of section '.note.description':
        [     c]  description
        [    18]  Application Template


      String dump of section '.note.product':
        [     c]  product
        [    14]  CMake C++ Template


      String dump of section '.note.version':
        [     c]  version
        [    14]  1.2.3.4-alpha5
      ```
      ```shell
      $ readelf -n application

      Displaying notes found in: .note.company
        Owner                Data size        Description
        company              0x00000009       NT_VERSION (version)
         description data: 48 4f 4d 45 20 43 6f 2e 00

      Displaying notes found in: .note.copyright
        Owner                Data size        Description
        copyright            0x0000002b       NT_VERSION (version)
         description data: 20 32 30 30 37 2d 32 30 32 34 20 48 4f 4d 45 20 43 6f 2e 20 41 6c 6c 20 72 69 67 68 74 73 20 72 65 73 65 72 76 65 64 2e 00 00 00

      Displaying notes found in: .note.description
        Owner                Data size        Description
        description          0x00000015       NT_VERSION (version)
         description data: 41 70 70 6c 69 63 61 74 69 6f 6e 20 54 65 6d 70 6c 61 74 65 00

      Displaying notes found in: .note.product
        Owner                Data size        Description
        product              0x00000013       NT_VERSION (version)
         description data: 43 4d 61 6b 65 20 43 2b 2b 20 54 65 6d 70 6c 61 74 65 00

      Displaying notes found in: .note.version
        Owner                Data size        Description
        1.2.3.4-alpha5       0x0000000f       NT_VERSION (version)
         description data: 2e 32 2e 33 2e 34 2d 61 6c 70 68 61 35 00 00
      ```
      ```shell
      $ readelf -p .sccsid application

      String dump of section '.sccsid':
        [     2]  @(#) Version: v1.2.3.4-alpha5\n
                  @(#) Description: Application Template\n
                  @(#) Product Name: CMake C++ Template\n
                  @(#) Company Name: HOME Co.\n
                  @(#) Copyright: � 2007-2024 HOME Co. All rights reserved.\n
                  $Id: v1.2.3.4-alpha5 | Application Template | CMake C++ Template | HOME Co. | � 2007-2024 HOME Co. All rights reserved. $\n
      ```
    </details>
- `add_option` as a better variant of `set(...CACHE...)` that has the next features:
  - More simple and intuitive interface.
  - 5 data types with some strict rules.
  - All the options have `OPTION_` prefix that simplifies working with CMakeCache
    when you have only a text editor.
  - All the options are automatically defined as macros for desired targets.
- Git utilities.
  - `fetch_git` as a better variant of `FetchContent_...` that is useful for additional
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
