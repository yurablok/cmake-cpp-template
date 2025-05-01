# CMake Utils
# https://github.com/yurablok/cmake-cpp-template
#
# History:
# v0.11  2025-Apr-21    Added ' ' prefix into target names in `launch.vs.json`.
# v0.10  2024-Dec-27    Added `add_metainfo`.
#                       Added `copy_release_binary_to_workdir` instead of
#                         `copy_release_app_to_workdir` & `copy_release_lib_to_workdir`.
# v0.9   2024-Sep-23    Added `recursive` parameter to `fetch_git`.
# v0.8   2024-May-01    Added flags `-fvisibility=hidden`, `MSVC_CPU_AUTO_LIMIT`.
# v0.7   2023-Dec-27    Added `breakpad_dump_and_strip`.
# v0.6   2023-May-22    Added `--filter=tree:0` and removed `--single-branch` in `fetch_git`.
# v0.5   2023-Feb-22    Added `fetch_git`.
# v0.4   2023-Feb-20    Added git commands.
# v0.3   2023-Jan-24    Added `add_option`.
# v0.2   2022-Dec-24    Added support for Windows ARM64.
# v0.1   2022-Oct-18    First release.

# Include this file before the main `project(...)`


#  ██ ███    ██ ██ ████████     ██████  ██████   ██████       ██ ███████  ██████ ████████
#  ██ ████   ██ ██    ██        ██   ██ ██   ██ ██    ██      ██ ██      ██         ██
#  ██ ██ ██  ██ ██    ██        ██████  ██████  ██    ██      ██ █████   ██         ██
#  ██ ██  ██ ██ ██    ██        ██      ██   ██ ██    ██ ██   ██ ██      ██         ██
#  ██ ██   ████ ██    ██        ██      ██   ██  ██████   █████  ███████  ██████    ██
#
# Call it after the main `project(...)` and before any `add_subdirectory(...)`
# Example:
#   init_project("client --ip=localhost" "server")
function(init_project)
    if(NOT "${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
        message(WARNING "CMakeUtils.cmake is not in the root.")
        return()
    endif()

    cmake_parse_arguments(arg "" "" "" "${ARGN}")
    if(NOT DEFINED arg_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "At least one target must be specified.")
    endif()

    if("${BUILD_ARCH}" STREQUAL "")
        if(NOT "${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}" STREQUAL "")
            set(CMAKE_TARGET_ARCH ${CMAKE_CXX_COMPILER_ARCHITECTURE_ID})
        else()
            set(CMAKE_TARGET_ARCH ${CMAKE_SYSTEM_PROCESSOR})
        endif()
        message("CMAKE_TARGET_ARCH: ${CMAKE_TARGET_ARCH}")
        if("${CMAKE_TARGET_ARCH}" MATCHES "(arm|ARM|aarch).*")
            if(CMAKE_SIZEOF_VOID_P EQUAL 8)
                set(BUILD_ARCH "arm64")
            else()
                set(BUILD_ARCH "arm32")
            endif()
        else()
            if(CMAKE_SIZEOF_VOID_P EQUAL 8)
                set(BUILD_ARCH "x64")
            else()
                set(BUILD_ARCH "x32")
            endif()
        endif()
    endif()

    if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
        set(BUILD_TYPE "RelNoDebInfo")
    elseif("${CMAKE_BUILD_TYPE}" STREQUAL "RelWithDebInfo")
        set(BUILD_TYPE "Release")
    else()
        set(BUILD_TYPE "${CMAKE_BUILD_TYPE}")
    endif()

    if(UNIX)
        if(APPLE)
            set(BUILD_PLATFORM "Mac")
        else()
            set(BUILD_PLATFORM "Linux")
        endif()
    elseif(WIN32)
        set(BUILD_PLATFORM "Windows")
    else()
        set(BUILD_PLATFORM "Unknown")
    endif()

    set(BUILD_FOLDER "${BUILD_ARCH}-${BUILD_TYPE}-${BUILD_PLATFORM}")
    message("BUILD_FOLDER: ${BUILD_FOLDER}")

    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/build/${BUILD_FOLDER}" PARENT_SCOPE)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/build/${BUILD_FOLDER}" PARENT_SCOPE)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/build/${BUILD_FOLDER}" PARENT_SCOPE)
    set(CMAKE_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/workdir" PARENT_SCOPE)

    file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/build/.cmake")
    file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/workdir")

    if("${CMAKE_SYSROOT}" STREQUAL "")
        #NOTE: clangd linter config
        file(WRITE ".clangd" "CompileFlags:\n  CompilationDatabase: build/.cmake/${BUILD_FOLDER}\n")
        set(CMAKE_EXPORT_COMPILE_COMMANDS ON PARENT_SCOPE)
    endif()

    cmake_policy(SET CMP0069 NEW)
    set(CMAKE_POLICY_DEFAULT_CMP0069 NEW PARENT_SCOPE)
    if(NOT "${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        #NOTE: Link-Time Global Optimization
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
    endif()

    if(MSVC)
        if(NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
            message("Compiler: MSVC v${CMAKE_CXX_COMPILER_VERSION}")
            if(MSVC_CPU_AUTO_LIMIT)
                cmake_host_system_information(RESULT totalCPU QUERY NUMBER_OF_LOGICAL_CORES)
                message("NUMBER_OF_LOGICAL_CORES=${totalCPU}")
                cmake_host_system_information(RESULT totalRAM_MiB QUERY AVAILABLE_PHYSICAL_MEMORY)
                message("AVAILABLE_PHYSICAL_MEMORY=${totalRAM_MiB}")
                math(EXPR maxCPU "${totalRAM_MiB} / 4096" OUTPUT_FORMAT DECIMAL)
                message("maxCPU=${maxCPU}")
                if(${maxCPU} GREATER ${totalCPU})
                    set(maxCPU ${totalCPU})
                endif()
            endif()

            if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
                add_compile_options(
                    /ZI # Debug Information with Edit and Continue
                )
            endif()
            add_compile_options(
                /utf-8 # Set source and execution character sets to UTF-8
                /sdl # Enable Additional Security Checks
                "/MP ${maxCPU}" # Build with Multiple Processes
                /permissive- # Standards conformance
                /Zc:__cplusplus # Enable updated __cplusplus macro
            )
        else()
            message("Compiler: Clang v${CMAKE_CXX_COMPILER_VERSION}")
            add_compile_options(-fcolor-diagnostics)
        endif()

        if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
            add_compile_options(
                /JMC # Just My Code Debugging
            )
            add_link_options(
                /INCREMENTAL # For Edit and Continue
            )
        endif()

        #set(CMAKE_CXX_FLAGS_RELEASE = "/MD /O2 /Ob2 /DNDEBUG")

        # The /Zi option produces a separate PDB file that contains all the symbolic
        # debugging information for use with the debugger. The debugging information
        # isn't included in the object files or executable, which makes them much smaller.
        set(CMAKE_C_FLAGS_RELWITHDEBINFO "/MD /Zi /O2 /Ob2 /DNDEBUG" PARENT_SCOPE)
        set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MD /Zi /O2 /Ob2 /DNDEBUG" PARENT_SCOPE)

        #NOTE: When changing the Qt5_DIR, you may need to manually delete CMakeCache.txt
        __find_msvc_qt5("C;D;E" "5.15.2")
        __write_msvs_launch_vs_json("${arg_UNPARSED_ARGUMENTS}")
        #__crutch_for_msvs_bug_with_merges()

    elseif("${CMAKE_CXX_COMPILER_ID}" MATCHES "(GNU|Clang)")
        # -O3 -g0   3.4 MB  default Release
        # -O3 -g1   9.5 MB
        # -O2 -g1   9.3 MB
        # -O2 -g2  41.0 MB  default RelWithDebInfo
        # -O0 -g2  35.0 MB  default Debug
        # Level 1 produces minimal information, enough for making backtraces in parts
        # of the program that you don’t plan to debug. This includes descriptions of
        # functions and external variables, and line number tables, but no information
        # about local variables.
        set(CMAKE_C_FLAGS_RELWITHDEBINFO "-O2 -g1 -DNDEBUG" PARENT_SCOPE)
        set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O2 -g1 -DNDEBUG" PARENT_SCOPE)

        add_compile_options(-fvisibility=hidden)

        if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
            message("Compiler: GCC v${CMAKE_CXX_COMPILER_VERSION}")
            add_compile_options(-fdiagnostics-color=always)
            if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 9.0)
                add_link_options(-fuse-ld=gold)
            elseif(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 12.1)
                #add_link_options(-fuse-ld=mold)
                if(${CMAKE_INTERPROCEDURAL_OPTIMIZATION})
                    add_compile_options(-flto=auto)
                endif()
            endif()
        elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
            message("Compiler: Clang v${CMAKE_CXX_COMPILER_VERSION}")
            add_compile_options(-fcolor-diagnostics)
        endif()

        __find_gcc_qt5("5.15.2")

    else()
        message(FATAL_ERROR "Unknown compiler: ${CMAKE_CXX_COMPILER_ID}")
    endif()

    if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.25)
        set(CMAKE_CXX_STANDARD 26 PARENT_SCOPE)
    elseif(CMAKE_VERSION VERSION_GREATER_EQUAL 3.20)
        set(CMAKE_CXX_STANDARD 23 PARENT_SCOPE)
    else()
        set(CMAKE_CXX_STANDARD 20 PARENT_SCOPE)
    endif()
    set(CMAKE_CXX_STANDARD_REQUIRED OFF PARENT_SCOPE)
    set(CMAKE_CXX_EXTENSIONS OFF PARENT_SCOPE)

    if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.21)
        set(CMAKE_C_STANDARD 23 PARENT_SCOPE)
    else()
        set(CMAKE_C_STANDARD 11 PARENT_SCOPE)
    endif()
    set(CMAKE_C_STANDARD_REQUIRED OFF PARENT_SCOPE)
    set(CMAKE_C_EXTENSIONS OFF PARENT_SCOPE)
    set(CMAKE_INCLUDE_CURRENT_DIR ON PARENT_SCOPE)

    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(Qt5Path "${Qt5x64Path}" PARENT_SCOPE)
    else()
        set(Qt5Path "${Qt5x32Path}" PARENT_SCOPE)
    endif()
    if(Qt5_DIR)
        set(Qt5_DIR "${Qt5_DIR}" PARENT_SCOPE)
    endif()

    set(BUILD_ARCH "${BUILD_ARCH}" PARENT_SCOPE)
    set(BUILD_TYPE "${BUILD_TYPE}" PARENT_SCOPE)
    set(BUILD_PLATFORM "${BUILD_PLATFORM}" PARENT_SCOPE)
    set(BUILD_FOLDER "${BUILD_FOLDER}" PARENT_SCOPE)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ${CMAKE_INTERPROCEDURAL_OPTIMIZATION} PARENT_SCOPE)
endfunction(init_project)


#   █████  ██████  ██████       ██████  ██████  ████████ ██  ██████  ███    ██
#  ██   ██ ██   ██ ██   ██     ██    ██ ██   ██    ██    ██ ██    ██ ████   ██
#  ███████ ██   ██ ██   ██     ██    ██ ██████     ██    ██ ██    ██ ██ ██  ██
#  ██   ██ ██   ██ ██   ██     ██    ██ ██         ██    ██ ██    ██ ██  ██ ██
#  ██   ██ ██████  ██████       ██████  ██         ██    ██  ██████  ██   ████
#
# @param [0]                Type: BOOL | ENUM | STRING | DIR | FILE
# @param [1]                Option's name. Prefix "OPTION_" will be added.
# @param [2] (optional)     Default variant
# @param [n] (optional)     Other variants
# @param TARGETS            Targets
# @param COMMENT (optional) Comment
function(add_option)
    set(argIdx -1)
    set(optionDefault "")
    set(optionVariants "")
    set(isTargets FALSE)
    set(optionTargets "")
    set(isComment FALSE)
    set(optionComment "")
    foreach(arg ${ARGN})
        math(EXPR argIdx "${argIdx}+1")
        if(${argIdx} EQUAL 0)
            set(optionType "${arg}")

        elseif(${argIdx} EQUAL 1)
            set(optionName "OPTION_${arg}")

        elseif("${arg}" STREQUAL "TARGETS")
            set(isTargets TRUE)
            set(isComment FALSE)

        elseif("${arg}" STREQUAL "COMMENT")
            set(isTargets FALSE)
            set(isComment TRUE)

        elseif(${isTargets})
            list(APPEND optionTargets "${arg}")

        elseif(${isComment})
            list(APPEND optionComment "${arg}")

        else()
            if(${argIdx} EQUAL 2)
                set(optionDefault "${arg}")
            endif()
            list(APPEND optionVariants "${arg}")
        endif()
    endforeach()
    string(REPLACE ";" "\n " optionComment "${optionComment}")

    if("${optionName}" STREQUAL "")
        message(FATAL_ERROR "add_option: <NAME> must be specified.")

    elseif("${optionType}" STREQUAL "")
        message(FATAL_ERROR "add_option: <TYPE> must be specified.")

    elseif("${optionTargets}" STREQUAL "")
        message(FATAL_ERROR "add_option: <TARGETS> must be specified.")

    elseif("${optionType}" STREQUAL "BOOL")
        if(NOT "${optionDefault}" MATCHES "^(ON|OFF|TRUE|FALSE|YES|NO)$")
            message(FATAL_ERROR "add_option: BOOL: <DEFAULT> must be one of (ON | OFF | TRUE | FALSE | YES | NO).")
        endif()
        list(LENGTH optionVariants size)
        if(NOT ${size} EQUAL 1)
            message(FATAL_ERROR "add_option: BOOL: too many defaults.")
        endif()
        if("${optionComment}" STREQUAL "")
            set(optionComment " Boolean option")
        endif()

        if(NOT "${${optionName}}" STREQUAL "")
            set(optionDefault ${${optionName}})
        endif()
        set(${optionName} ${optionDefault} CACHE BOOL "${optionComment}" FORCE)

        foreach(optionTarget ${optionTargets})
            if(${optionDefault})
                target_compile_definitions(${optionTarget} PRIVATE ${optionName}=1)
            else()
                target_compile_definitions(${optionTarget} PRIVATE ${optionName}=0)
            endif()
        endforeach()

    elseif("${optionType}" STREQUAL "ENUM")
        if("${optionVariants}" MATCHES ".* .*")
            message(FATAL_ERROR "add_option: ENUM: variants must not contain spaces in their names.")
        endif()
        list(LENGTH optionVariants size)
        if(${size} LESS 2)
            message(FATAL_ERROR "add_option: ENUM: too few variants.")
        endif()
        if(NOT "${optionComment}" STREQUAL "")
            string(APPEND optionComment "\n")
        endif()
        string(APPEND optionComment " Enum variants: ${optionVariants}")

        if(NOT "${${optionName}}" STREQUAL "")
            set(optionDefault ${${optionName}})
            list(FIND optionVariants ${optionDefault} result)
            if(${result} LESS 0)
                message(FATAL_ERROR "add_option: ENUM: unknown variant ${optionDefault}.")
            endif()
        endif()
        set(${optionName} ${optionDefault} CACHE STRING "${optionComment}" FORCE)
        set_property(CACHE ${optionName} PROPERTY STRINGS ${optionVariants})

        foreach(optionTarget ${optionTargets})
            target_compile_definitions(${optionTarget} PRIVATE ${optionName}="${optionDefault}")
            target_compile_definitions(${optionTarget} PRIVATE ${optionName}_${optionDefault}=1)
        endforeach()

    elseif("${optionType}" STREQUAL "STRING")
        list(LENGTH optionVariants size)
        if(${size} GREATER 1)
            message(FATAL_ERROR "add_option: STRING: too many defaults.")
        endif()
        if("${optionComment}" STREQUAL "")
            set(optionComment " String option")
        endif()

        if(DEFINED ${optionName})
            set(optionDefault ${${optionName}})
        endif()
        set(${optionName} ${optionDefault} CACHE STRING "${optionComment}" FORCE)

        foreach(optionTarget ${optionTargets})
            target_compile_definitions(${optionTarget} PRIVATE ${optionName}="${optionDefault}")
        endforeach()

    elseif("${optionType}" STREQUAL "DIR")
        list(LENGTH optionVariants size)
        if(${size} GREATER 1)
            message(FATAL_ERROR "add_option: DIR: too many defaults.")
        endif()
        if("${optionComment}" STREQUAL "")
            set(optionComment " Directory option")
        endif()

        if(DEFINED ${optionName})
            set(optionDefault ${${optionName}})
        endif()
        set(${optionName} ${optionDefault} CACHE PATH "${optionComment}" FORCE)

        foreach(optionTarget ${optionTargets})
            target_compile_definitions(${optionTarget} PRIVATE ${optionName}="${optionDefault}")
        endforeach()

    elseif("${optionType}" STREQUAL "FILE")
        list(LENGTH optionVariants size)
        if(${size} GREATER 1)
            message(FATAL_ERROR "add_option: FILE: too many defaults.")
        endif()
        if("${optionComment}" STREQUAL "")
            set(optionComment " File option")
        endif()

        if(DEFINED ${optionName})
            set(optionDefault ${${optionName}})
        endif()
        set(${optionName} ${optionDefault} CACHE FILEPATH "${optionComment}" FORCE)

        foreach(optionTarget ${optionTargets})
            target_compile_definitions(${optionTarget} PRIVATE ${optionName}="${optionDefault}")
        endforeach()

    else()
        message(FATAL_ERROR "add_option: <TYPE> must be one of (BOOL | ENUM | STRING | DIR | FILE).")
    endif()

endfunction(add_option)


#  █████  ██████  ██████      ███    ███ ███████ ████████  █████  ██ ███    ██ ███████  ██████
# ██   ██ ██   ██ ██   ██     ████  ████ ██         ██    ██   ██ ██ ████   ██ ██      ██    ██
# ███████ ██   ██ ██   ██     ██ ████ ██ █████      ██    ███████ ██ ██ ██  ██ █████   ██    ██
# ██   ██ ██   ██ ██   ██     ██  ██  ██ ██         ██    ██   ██ ██ ██  ██ ██ ██      ██    ██
# ██   ██ ██████  ██████      ██      ██ ███████    ██    ██   ██ ██ ██   ████ ██       ██████
#
# @param targetName               EXECUTABLE or SHARED_LIBRARY target
# @param VERSION                  1.2.3.4-alpha5
# @param DESCRIPTION  (optional)  "Application Template"
# @param PRODUCT      (optional)  "CMake C++ Template"
# @param COMPANY      (optional)  "HOME Co."
# @param COPYRIGHT    (optional)  "© 2007-2024 HOME Co. All rights reserved."
# @param ICON         (optional)  "icon" (without the extension) -> Windows: .ico, MacOS: .icns
function(add_metainfo targetName)
    get_target_property(targetType ${targetName} TYPE)
    get_target_property(targetOutputName ${targetName} OUTPUT_NAME)
    if("${targetOutputName}" STREQUAL "targetOutputName-NOTFOUND")
        set(targetOutputName ${targetName})
    endif()

    cmake_parse_arguments(arg "" "VERSION;DESCRIPTION;COMPANY;PRODUCT;COPYRIGHT;ICON" "" "${ARGN}")

    string(REGEX MATCH "([0-9]+)\\.?([0-9]+)?\\.?([0-9]+)?\\.?([0-9]+)?-?([-0-9a-zA-Z]+)?" result ${arg_VERSION})
    if("${CMAKE_MATCH_1}" STREQUAL "")
        set(CMAKE_MATCH_1 "0")
    endif()
    if("${CMAKE_MATCH_2}" STREQUAL "")
        set(CMAKE_MATCH_2 "0")
    endif()
    if("${CMAKE_MATCH_3}" STREQUAL "")
        set(CMAKE_MATCH_3 "0")
    endif()
    if("${CMAKE_MATCH_4}" STREQUAL "")
        set(CMAKE_MATCH_4 "0")
    endif()

    if("${targetType}" STREQUAL "EXECUTABLE")
        set(targetOutputName "${targetOutputName}${CMAKE_EXECUTABLE_SUFFIX}")
    elseif("${targetType}" STREQUAL "SHARED_LIBRARY")
        if(NOT "${arg_ICON}" STREQUAL "")
            message(FATAL_ERROR "add_metainfo: ${targetName} is a library and can't has an icon")
        endif()
        set(targetOutputName "${targetOutputName}${CMAKE_SHARED_LIBRARY_SUFFIX}")
    else()
        message(FATAL_ERROR "add_metainfo: ${targetName} must be EXECUTABLE or SHARED_LIBRARY")
    endif()

    get_target_property(targetSources ${targetName} SOURCES)
    if("${targetSources}" STREQUAL "")
        message(FATAL_ERROR "add_metainfo: use it after specifying sources for ${targetName}")
    endif()

    set(cPath "${CMAKE_CURRENT_BINARY_DIR}/${targetName}.metainfo.c")
    set(c
"#include \"${targetName}.metainfo.h\"

#if defined(__unix__)
  __attribute__((used, section(\".sccsid\")))
#else
# if defined(__cplusplus)
    extern \"C\"
# else
    extern
# endif
#endif
// Source Code Control System (SCCS) convention
// grep --binary-files=text \"@(#)\" application
// readelf -p .sccsid {application}
const char sccsid[] = \"\\n\\n\"
    \"@(#) Version: v${arg_VERSION}\\n\"
    \"@(#) Description: ${arg_DESCRIPTION}\\n\"
    \"@(#) Product Name: ${arg_PRODUCT}\\n\"
    \"@(#) Company Name: ${arg_COMPANY}\\n\"
    \"@(#) Copyright: ${arg_COPYRIGHT}\\n\"
    \"\\n\"
    \"$Id: v${arg_VERSION} | ${arg_DESCRIPTION} | ${arg_PRODUCT}\"
    \" | ${arg_COMPANY} | ${arg_COPYRIGHT} $\\n\"
\"\\n\";

#if defined(__unix__)
// readelf -p .note.version {application}
// readelf -p .note.version -p .note.description -p .note.product -p .note.company -p .note.copyright application
// readelf -n {application}
#   define ADD_NOTE(TOKEN, NAME, TEXT) \\
        struct note_##TOKEN { \\
            uint32_t namesz; \\
            uint32_t descsz; \\
            uint32_t type; \\
            char name[sizeof(NAME)]; \\
            char desc[sizeof(TEXT)]; \\
        }; \\
        __attribute__((used, section(\".note.\" #TOKEN), aligned(4))) \\
        const struct note_##TOKEN g_##TOKEN = { \\
            .namesz = sizeof(NAME), \\
            .descsz = sizeof(TEXT), \\
            .type = 1, \\
            .name = NAME, \\
            .desc = TEXT \\
        }
    ADD_NOTE(version,     \"${arg_VERSION}\", \"${arg_VERSION}\");
    ADD_NOTE(description, \"description\",    \"${arg_DESCRIPTION}\");
    ADD_NOTE(product,     \"product\",        \"${arg_PRODUCT}\");
    ADD_NOTE(company,     \"company\",        \"${arg_COMPANY}\");
    ADD_NOTE(copyright,   \"copyright\",      \"${arg_COPYRIGHT}\");
#endif

const char* ${targetName}_Version() {
    return \"${arg_VERSION}\";
}
uint16_t ${targetName}_VersionMajor() {
    return ${CMAKE_MATCH_1};
}
uint16_t ${targetName}_VersionMinor() {
    return ${CMAKE_MATCH_2};
}
uint16_t ${targetName}_VersionPatch() {
    return ${CMAKE_MATCH_3};
}
uint16_t ${targetName}_VersionBuild() {
    return ${CMAKE_MATCH_4};
}
const char* ${targetName}_VersionQualifier() {
    return \"${CMAKE_MATCH_5}\";
}
")
    set(hPath "${CMAKE_CURRENT_BINARY_DIR}/${targetName}.metainfo.h")
    set(h
"#pragma once
#include <stdint.h>

#if defined(__cplusplus)
extern \"C\" {
#endif

const char* ${targetName}_Version();
uint16_t ${targetName}_VersionMajor();
uint16_t ${targetName}_VersionMinor();
uint16_t ${targetName}_VersionPatch();
uint16_t ${targetName}_VersionBuild();
const char* ${targetName}_VersionQualifier();
")

    if(${CMAKE_MATCH_1} LESS_EQUAL 0xFF AND ${CMAKE_MATCH_2} LESS_EQUAL 0xFF
            AND ${CMAKE_MATCH_3} LESS_EQUAL 0xFF AND ${CMAKE_MATCH_4} LESS_EQUAL 0xFF)
        set(h
"${h}uint32_t ${targetName}_VersionU32();
")
        set(c
"${c}uint32_t ${targetName}_VersionU32() {
    return (UINT32_C(${CMAKE_MATCH_1}) << 24) | (UINT32_C(${CMAKE_MATCH_2}) << 16) | (UINT32_C(${CMAKE_MATCH_3}) << 8) | (UINT32_C(${CMAKE_MATCH_4}));
}
")
    endif()
    if(${CMAKE_MATCH_1} LESS_EQUAL 0xFFFF AND ${CMAKE_MATCH_2} LESS_EQUAL 0xFFFF
            AND ${CMAKE_MATCH_3} LESS_EQUAL 0xFFFF AND ${CMAKE_MATCH_4} LESS_EQUAL 0xFFFF)
        set(h
"${h}uint64_t ${targetName}_VersionU64();
")
        set(c
"${c}uint64_t ${targetName}_VersionU64() {
    return (UINT64_C(${CMAKE_MATCH_1}) << 48) | (UINT64_C(${CMAKE_MATCH_2}) << 32) | (UINT64_C(${CMAKE_MATCH_3}) << 16) | (UINT64_C(${CMAKE_MATCH_4}));
}
")
    endif()
    set(h "${h}
#if defined(__cplusplus)
} // extern \"C\"
#endif
")

    string(SHA256 verHash "${c}|${arg_ICON}")
    if("${${targetName}_verHashCached}" STREQUAL ${verHash})
        set(isChanged NO)
    else()
        set(${targetName}_verHashCached ${verHash} CACHE INTERNAL "")
        set(isChanged YES)
    endif()

    if(isChanged)
        file(WRITE "${hPath}" "${h}")
        file(WRITE "${cPath}" "${c}")
        message("Generated ${targetName}.metainfo.h & c")
    endif()

    target_include_directories(${targetName} PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
    list(APPEND targetSources "${hPath}" "${cPath}")

    if(WIN32)
        if(NOT "${arg_ICON}" STREQUAL "")
            set(icon "\nIDI_ICON1 ICON DISCARDABLE \"${arg_ICON}.ico\"\n")
        endif()
        set(rcPath "${CMAKE_CURRENT_BINARY_DIR}/${targetName}.metainfo.rc")
        set(rc
"#include <windows.h>
${icon}
VS_VERSION_INFO VERSIONINFO
    FILEVERSION ${CMAKE_MATCH_1},${CMAKE_MATCH_2},${CMAKE_MATCH_3},${CMAKE_MATCH_4}
    FILEFLAGSMASK 0xFFL
# ifdef NDEBUG
    FILEFLAGS 0
# else
    FILEFLAGS VS_FF_DEBUG
# endif
BEGIN
    BLOCK \"StringFileInfo\"
    BEGIN
        BLOCK \"000004B0\"
        BEGIN
            VALUE \"FileDescription\", \"${arg_DESCRIPTION}\\0\"
            VALUE \"ProductName\", \"${arg_PRODUCT}\\0\"
            VALUE \"ProductVersion\", \"${arg_VERSION}\\0\"
            VALUE \"CompanyName\", \"${arg_COMPANY}\\0\"
            VALUE \"LegalCopyright\", \"${arg_COPYRIGHT}\\0\"
            VALUE \"OriginalFilename\", \"${targetOutputName}\\0\"
        END
    END
    BLOCK \"VarFileInfo\"
    BEGIN
        VALUE \"Translation\", 0x0000, 0x04B0
    END
END
")
        if(isChanged)
            # ClangCL: UTF-16 (LE) byte order mark detected in '***.rc', but encoding is not supported
            if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
                file(WRITE "${rcPath}" "${rc}")
                message(WARNING "ClanCL supports only ASCII .rc")
            else()
                file(WRITE "${rcPath}.utf8" "${rc}")
                execute_process(
                    COMMAND powershell
                        Get-Content '${targetName}.metainfo.rc.utf8' -Raw -Encoding utf8
                        | Out-File '${targetName}.metainfo.rc' -Encoding unicode
                    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
                )
            endif()
            message("Generated ${targetName}.metainfo.rc")
        endif()
        list(APPEND targetSources "${rcPath}")
    elseif(APPLE)
        #TODO: Generate Info.plist
        if(NOT "${arg_ICON}" STREQUAL "")
            set(iconPath "${arg_ICON}.icns")
            set_source_files_properties(${iconPath} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
            list(APPEND targetSources "${iconPath}")
        endif()
    endif()
    target_sources(${targetName} PRIVATE "${targetSources}")
endfunction(add_metainfo)


#   ██████  ██ ████████     ██    ██ ████████ ██ ██      ██ ████████ ███████ ███████
#  ██       ██    ██        ██    ██    ██    ██ ██      ██    ██    ██      ██
#  ██   ███ ██    ██        ██    ██    ██    ██ ██      ██    ██    █████   ███████
#  ██    ██ ██    ██        ██    ██    ██    ██ ██      ██    ██    ██           ██
#   ██████  ██    ██         ██████     ██    ██ ███████ ██    ██    ███████ ███████

# @param directory  Target directory to download sources.
# @param address    Git-compatible address of a repository.
# @param tag        Desired branch | tag | hash.
# @param recursive  YES/NO to fetch recursively.
function(fetch_git directory address tag recursive)
    get_filename_component(absolutePath ${directory} ABSOLUTE)
    file(RELATIVE_PATH relativePath ${CMAKE_SOURCE_DIR} ${absolutePath})
    message("fetch_git: checking \"${relativePath}\"...")

    if(recursive)
        set(recursive "--recurse-submodules")
    else()
        set(recursive "")
    endif()

    if(NOT EXISTS "${absolutePath}/.git/HEAD")
        message("fetch_git: downloading \"${relativePath}\"...")

        get_filename_component(absoluteParentPath "${absolutePath}/../" ABSOLUTE)
        file(MAKE_DIRECTORY ${absoluteParentPath})

        string(LENGTH ${absoluteParentPath} length)
        math(EXPR length "${length}+1")
        string(SUBSTRING ${absolutePath} ${length} -1 folder)

        execute_process(
            WORKING_DIRECTORY ${absoluteParentPath}
            COMMAND git clone --branch ${tag} --filter=tree:0 ${recursive} ${address} ${folder}
            OUTPUT_VARIABLE output
            ERROR_VARIABLE error
            RESULT_VARIABLE result
        )
        # Normal + branch | tag
        #   output=
        #   error=Cloning into 'repo123'...
        #   result=0
        # Normal + hash
        #   output=
        #   error=Cloning into 'repo123'...
        #         warning: Could not find remote branch 1234567 to clone.
        #         fatal: Remote branch 1234567 not found in upstream origin
        #   result=128
        # Error 128 (not empty)
        #   output=
        #   error=fatal: destination path 'repo123' already exists and is not an empty directory.
        #   result=128
        # Error 128 (unreachable)
        #   output=
        #   error=Cloning into 'repo123'...
        #         fatal: unable to access 'https://....': Could not resolve host: ....
        #   result=128
        if(NOT ${result} EQUAL 0)
            string(FIND "${error}" "not found in upstream" result)
            if(${result} GREATER 0)
                execute_process(
                    WORKING_DIRECTORY ${absoluteParentPath}
                    COMMAND git clone --filter=tree:0 ${recursive} ${address} ${folder}
                    OUTPUT_VARIABLE output
                    ERROR_VARIABLE error
                    RESULT_VARIABLE result
                )
                if(NOT ${result} EQUAL 0)
                    message(FATAL_ERROR "fetch_git: ${error}")
                endif()

                execute_process(
                    WORKING_DIRECTORY ${absolutePath}
                    COMMAND git checkout ${recursive} ${tag}
                    OUTPUT_VARIABLE output
                    ERROR_VARIABLE error
                    RESULT_VARIABLE result
                )
                # Normal + hash
                #   output=
                #   error=Note: switching to '1234567'.
                #         You are in 'detached HEAD' state.
                #   result=0
                # Error 1
                #   output=
                #   error=error: pathspec '1234567' did not match any file(s) known to git
                #   result=1
            endif()
        endif()

        if(NOT ${result} EQUAL 0)
            message(FATAL_ERROR "fetch_git: ${error}")
        endif()

    else()
        execute_process(
            WORKING_DIRECTORY ${absolutePath}
            COMMAND git checkout ${recursive} ${tag}
            OUTPUT_VARIABLE output
            ERROR_VARIABLE error
            RESULT_VARIABLE result
        )
        # Error 1 (no match)
        #   output=
        #   error=error: pathspec '2.5.1' did not match any file(s) known to git
        #   result=1
        if(NOT ${result} EQUAL 0)
            message("fetch_git: fetching \"${relativePath}\"...")
            file(REMOVE "${absolutePath}/.git/index.lock")

            execute_process(
                WORKING_DIRECTORY ${absolutePath}
                COMMAND git fetch --all --tags ${recursive}
                OUTPUT_VARIABLE output
                ERROR_VARIABLE error
                RESULT_VARIABLE result
            )
            if(NOT ${result} EQUAL 0)
                message(FATAL_ERROR "fetch_git: ${error}")
            endif()

            execute_process(
                WORKING_DIRECTORY ${absolutePath}
                COMMAND git checkout ${recursive} --force ${tag}
                OUTPUT_VARIABLE output
                ERROR_VARIABLE error
                RESULT_VARIABLE result
            )
        endif()

        if(NOT ${result} EQUAL 0)
            message(FATAL_ERROR "fetch_git: ${error}")
        endif()

    endif()

    message("fetch_git: \"${relativePath}\" is ready")
endfunction(fetch_git)


# @param[out] OUT_RESULT        Resulting output of our command
# @param      COMMAND_          Our git command
function(git_do_command OUT_RESULT COMMAND_)
    set(_execute_command git ${COMMAND_} ${ARGN})

    execute_process(COMMAND ${_execute_command}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE output
        ERROR_VARIABLE error_output
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(NOT error_output STREQUAL "")
        set(${OUT_RESULT} ${error_output} PARENT_SCOPE)
        return()
    endif()
    set(${OUT_RESULT} ${output} PARENT_SCOPE)
endfunction(git_do_command)


# @param[out] OUT_BRANCH         Resulting name of the current branch if not detached
function(git_branch OUT_BRANCH)
    git_do_command(output rev-parse --abbrev-ref HEAD)
    set(${OUT_BRANCH} ${output} PARENT_SCOPE)
endfunction(git_branch)


# @param      REGEX              Desired regex to match a commit by its message
# @param[out] OUT_COMMITS_COUNT  Resulting number of commits from HEAD to the first matched commit
# @param[out] GIT_COMMIT_HASH    Resulting hash of the first matched commit
function(git_commits_count_by_regex REGEX OUT_COMMITS_COUNT)
    git_do_command(commit_hash rev-list HEAD --grep=\"${REGEX}\" -n 1)
    if("${commit_hash}" STREQUAL "")
        message(FATAL_ERROR "[git_commits_count_by_regex] Bad git revision")
    endif()
    git_do_command(output rev-list --count HEAD ^${commit_hash})

    set(${OUT_COMMITS_COUNT} ${output} PARENT_SCOPE)
    set(${GIT_COMMIT_HASH} ${commit_hash} PARENT_SCOPE)
endfunction(git_commits_count_by_regex)

# @param      TAG                Desired tag to counting to
# @param[out] OUT_COMMITS_COUNT  Resulting number of commits to the desired tag
function(git_commits_count_by_tag TAG OUT_COMMITS_COUNT)
    git_do_command(output rev-list --count HEAD ^${TAG})
    set(${OUT_COMMITS_COUNT} ${output} PARENT_SCOPE)
endfunction(git_commits_count_by_tag)


#   ██████  ████████     ██    ██ ████████ ██ ██      ██ ████████ ███████ ███████
#  ██    ██    ██        ██    ██    ██    ██ ██      ██    ██    ██      ██
#  ██    ██    ██        ██    ██    ██    ██ ██      ██    ██    █████   ███████
#  ██ ▄▄ ██    ██        ██    ██    ██    ██ ██      ██    ██    ██           ██
#   ██████     ██         ██████     ██    ██ ███████ ██    ██    ███████ ███████
#      ▀▀

# @param SOURCES    Directory where lupdate will look for C++ sources
# @param TS_FILES   List of generated *.ts files
# @param QM_DIR     Directory for generated *.qm files
function(qt5_create_ts_and_qm)
    set(options)
    set(oneValueArgs SOURCES QM_DIR)
    set(multiValueArgs TS_FILES)
    cmake_parse_arguments(arg "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    file(MAKE_DIRECTORY "${arg_QM_DIR}")

    foreach(tsFile ${arg_TS_FILES})
        get_filename_component(tsFileName "${tsFile}" NAME_WLE)
        #add_custom_command(
        #    TARGET ${PROJECT_NAME} PRE_BUILD
        #    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        #    COMMAND "${Qt5Path}/bin/lupdate"
        #    ARGS -locations none ${arg_SOURCES} -ts ${tsFile}
        #)
        #add_custom_command(
        #    TARGET ${PROJECT_NAME} PRE_BUILD
        #    DEPENDS "${tsFile}"
        #    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        #    COMMAND "${Qt5Path}/bin/lrelease"
        #    ARGS ${tsFile} -qm ${arg_QM_DIR}/${tsFileName}.qm
        #)

        add_custom_command(
            TARGET ${PROJECT_NAME} PRE_BUILD
            COMMAND ${CMAKE_COMMAND}
                -DRUN=qt5_create_ts_and_qm

                -DLUPDATE=${Qt5Path}/bin/lupdate
                -DLRELEASE=${Qt5Path}/bin/lrelease
                -DWORKDIR=${CMAKE_CURRENT_SOURCE_DIR}
                -DDIRECTORY=${arg_SOURCES}
                -DTSFILE=${tsFile}
                -DQMFILE=${arg_QM_DIR}/${tsFileName}.qm

                -P ${CMAKE_SOURCE_DIR}/CMakeUtils.cmake
        )
    endforeach()
endfunction(qt5_create_ts_and_qm)

function(__qt5_create_ts_and_qm_impl)
    # lupdate directory -ts file.ts -locations none
    execute_process(
        WORKING_DIRECTORY ${WORKDIR}
        COMMAND ${LUPDATE} -locations none ${DIRECTORY} -ts ${TSFILE}
        OUTPUT_VARIABLE result
    )
    if("${result}" STREQUAL "")
        return()
    endif()

    # Found 0 source text(s) (0 new and 0 already existing)
    string(REGEX MATCH "([0-9]+)[ a-z()]+([0-9]+)[ a-z()]+([0-9]+)" result ${result})
    message("lupdate: ${CMAKE_MATCH_1} found, ${CMAKE_MATCH_2} new, ${CMAKE_MATCH_3} exists")

    if(EXISTS "${WORKDIR}/${QMFILE}" AND "${CMAKE_MATCH_2}" STREQUAL "0")
        #NOTE: Remove *.qm files after editing *.ts files!
        return()
    endif()

    # lrelease file.ts -qm file.qm
    execute_process(
        WORKING_DIRECTORY ${WORKDIR}
        COMMAND ${LRELEASE} ${TSFILE} -qm ${QMFILE}
        OUTPUT_VARIABLE result
    )
    if("${result}" STREQUAL "")
        return()
    endif()

    # Generated 0 translation(s) (0 finished and 0 unfinished)
    #string(REGEX MATCH "([0-9]+)[ a-z()]+([0-9]+)[ a-z()]+([0-9]+)" result ${result})
    message("lrelease: ${QMFILE}")
endfunction(__qt5_create_ts_and_qm_impl)


function(__find_gcc_qt5 qtVersion)
    set(qtPath "~/Qt/${qtVersion}/gcc_64")
    if(EXISTS "${qtPath}")
        set(Qt5x64Path "${qtPath}" PARENT_SCOPE)
    else()
        set(qtPath "")
    endif()

    if(NOT "${qtPath}" STREQUAL "")
        if(${BUILD_ARCH} STREQUAL "x64")
            set(Qt5_DIR "${qtPath}/lib/cmake/Qt5" PARENT_SCOPE)
        endif()
        message("Qt5x64Path: ${qtPath}")
    endif()
endfunction(__find_gcc_qt5)

function(__find_msvc_qt5 drives qtVersion)
    foreach(drive ${drives})
        set(qtPath "${drive}:/Qt/${qtVersion}/msvc2019")
        if(EXISTS "${qtPath}")
            set(Qt5x32Path "${qtPath}" PARENT_SCOPE)
            break()
        endif()
        set(qtPath "${drive}:/Qt/${qtVersion}/msvc2017")
        if(EXISTS "${qtPath}")
            set(Qt5x32Path "${qtPath}" PARENT_SCOPE)
            break()
        endif()
        set(qtPath "")
    endforeach(drive)
    if(NOT "${qtPath}" STREQUAL "")
        if(CMAKE_SIZEOF_VOID_P EQUAL 4)
            set(Qt5_DIR "${qtPath}/lib/cmake/Qt5" PARENT_SCOPE)
        endif()
        message("Qt5x32Path: ${qtPath}")
    endif()

    foreach(drive ${drives})
        set(qtPath "${drive}:/Qt/${qtVersion}/msvc2019_64")
        if(EXISTS "${qtPath}")
            set(Qt5x64Path "${qtPath}" PARENT_SCOPE)
            break()
        endif()
        set(qtPath "${drive}:/Qt/${qtVersion}/msvc2017_64")
        if(EXISTS "${qtPath}")
            set(Qt5x64Path "${qtPath}" PARENT_SCOPE)
            break()
        endif()
        set(qtPath "")
    endforeach(drive)
    if(NOT "${qtPath}" STREQUAL "")
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
            set(Qt5_DIR "${qtPath}/lib/cmake/Qt5" PARENT_SCOPE)
        endif()
        message("Qt5x64Path: ${qtPath}")
    endif()
endfunction(__find_msvc_qt5)


#  ██████  ██████  ███████  █████  ██   ██ ██████   █████  ██████      ██    ██ ████████ ██ ██      ██ ████████ ███████ ███████
#  ██   ██ ██   ██ ██      ██   ██ ██  ██  ██   ██ ██   ██ ██   ██     ██    ██    ██    ██ ██      ██    ██    ██      ██
#  ██████  ██████  █████   ███████ █████   ██████  ███████ ██   ██     ██    ██    ██    ██ ██      ██    ██    █████   ███████
#  ██   ██ ██   ██ ██      ██   ██ ██  ██  ██      ██   ██ ██   ██     ██    ██    ██    ██ ██      ██    ██    ██           ██
#  ██████  ██   ██ ███████ ██   ██ ██   ██ ██      ██   ██ ██████       ██████     ██    ██ ███████ ██    ██    ███████ ███████

# @param targetName             Target name for which the symbols will be dumped
# @param BREAKPAD_DUMP_SYMS     Path to the Breakpad's dump_syms executable.
# @param CMAKE_STRIP (optional) Path to the strip executable if the target platform is different.
function(breakpad_dump_and_strip targetName)
    if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        return()
    endif()
    if(NOT TARGET ${targetName})
        message(FATAL_ERROR "breakpad_dump_and_strip: wrong target ${targetName}")
    endif()
    if(${BUILD_PLATFORM} STREQUAL "Windows")
        return()
    elseif(NOT ${BUILD_PLATFORM} STREQUAL "Linux")
        message(WARNING "breakpad_dump_and_strip: ${BUILD_PLATFORM} platform has not been tested")
        return()
    endif()
    if("${BREAKPAD_DUMP_SYMS}" STREQUAL "")
        message(WARNING "breakpad_dump_and_strip: BREAKPAD_DUMP_SYMS is not specified")
        return()
    endif()
    if(NOT EXISTS "${BREAKPAD_DUMP_SYMS}")
        message(FATAL_ERROR "breakpad_dump_and_strip: dump_syms is not found (path: ${BREAKPAD_DUMP_SYMS})")
    endif()

    add_custom_command(
        VERBATIM
        TARGET ${targetName} POST_BUILD
        WORKING_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}"
        COMMAND ${CMAKE_COMMAND}
            -DRUN=breakpad_dump_and_strip

            -DBREAKPAD_DUMP_SYMS=${BREAKPAD_DUMP_SYMS}
            -DCMAKE_STRIP=${CMAKE_STRIP}
            -DTARGET_FILE=${targetName}

            -P ${CMAKE_SOURCE_DIR}/CMakeUtils.cmake
    )
endfunction(breakpad_dump_and_strip)

function(__breakpad_dump_and_strip)
    execute_process(
        COMMAND "${BREAKPAD_DUMP_SYMS}" -i ${TARGET_FILE}
        OUTPUT_VARIABLE result
    )
    # "MODULE Linux arm64 912C385C93DFB00C2B4D31F83BFF5BF90 TARGET_FILE"
    string(REGEX MATCH "MODULE[ ]+[a-zA-Z0-9]+[ ]+[a-zA-Z0-9]+[ ]+([a-zA-Z0-9]+)[ ]+" result ${result})
    set(buildId "${CMAKE_MATCH_1}")
    message("${TARGET_FILE} build id: ${buildId}")
    file(MAKE_DIRECTORY "symbols/${TARGET_FILE}/${buildId}/")

    execute_process(
        COMMAND "${BREAKPAD_DUMP_SYMS}" ${TARGET_FILE}
        OUTPUT_VARIABLE result
    )
    file(WRITE "symbols/${TARGET_FILE}/${buildId}/${TARGET_FILE}.sym" "${result}")

    cmake_minimum_required(VERSION 3.18)
    file(ARCHIVE_CREATE
        OUTPUT "${TARGET_FILE}.sym.zip"
        PATHS "symbols/${TARGET_FILE}/${buildId}/${TARGET_FILE}.sym"
        FORMAT zip
    )
    file(REMOVE_RECURSE "symbols")

    if("${CMAKE_STRIP}" STREQUAL "")
        execute_process(
            COMMAND strip ${TARGET_FILE}
        )
    else()
        execute_process(
            COMMAND "${CMAKE_STRIP}" ${TARGET_FILE}
        )
    endif()

    message("${TARGET_FILE}.sym.zip created")
endfunction(__breakpad_dump_and_strip)


#  ██ ██████  ███████     ██    ██ ████████ ██ ██      ██ ████████ ███████ ███████
#  ██ ██   ██ ██          ██    ██    ██    ██ ██      ██    ██    ██      ██
#  ██ ██   ██ █████       ██    ██    ██    ██ ██      ██    ██    █████   ███████
#  ██ ██   ██ ██          ██    ██    ██    ██ ██      ██    ██    ██           ██
#  ██ ██████  ███████      ██████     ██    ██ ███████ ██    ██    ███████ ███████

function(__write_msvs_launch_vs_json targets)
    set(cfgPath "${CMAKE_SOURCE_DIR}/.vs/launch.vs.json")

    set(json "")
    set(json "${json}{\n")
    set(json "${json}  \"NOTE\": \"This file was generated by CMakeUtils.cmake\",\n")
    set(json "${json}  \"version\": \"0.2.1\",\n")
    set(json "${json}  \"configurations\": [\n")

    macro(add appPath qtPath targetName targetArgs)
        string(REPLACE "/" "\\\\" targetPath "${CMAKE_SOURCE_DIR}/build/${appPath}/${targetName}")
        set(json "${json}    {\n")
        set(json "${json}      \"type\": \"default\",\n")
        set(json "${json}      \"project\": \"CMakeLists.txt\",\n")
        set(json "${json}      \"projectTarget\": \"${targetName}.exe (${targetPath}.exe)\",\n")
        set(json "${json}      \"name\": \" ${targetName}\",\n") # ' ' for placing targets at the top
        set(json "${json}      \"args\": [\n")
        set(json "${json}        \"${targetArgs}\"\n")
        set(json "${json}      ],\n")
        set(json "${json}      \"currentDir\": \"\${workspaceRoot}/workdir\",\n")
        set(json "${json}      \"env\": {\n")
        set(json "${json}        \"PATH\": \"\${env.PATH};${qtPath}/bin\"\n")
        set(json "${json}      }\n")
        set(json "${json}    },\n")
    endmacro(add)

    foreach(target ${targets})
        string(REGEX MATCH "^([-_a-zA-Z0-9]+)[ ]*(.*)$" matched "${target}")
        if(${CMAKE_MATCH_COUNT} EQUAL 0)
            message(FATAL_ERROR "Wrong target format (actual='${target}', expected='name args').")
        endif()

        set(targetName ${CMAKE_MATCH_1})
        set(targetArgs ${CMAKE_MATCH_2})
        string(REPLACE "\"" "\\\\\"" targetArgs "${targetArgs}")
        #message("targetName=${targetName} targetArgs=[${targetArgs}]")

        add("x64-Debug-Windows/Debug"              "${Qt5x64Path}" "${targetName}" "${targetArgs}")
        add("arm64-Debug-Windows/Debug"            "${Qt5x64Path}" "${targetName}" "${targetArgs}")
        add("x32-Debug-Windows/Debug"              "${Qt5x32Path}" "${targetName}" "${targetArgs}")

        add("x64-Release-Windows/RelWithDebInfo"   "${Qt5x64Path}" "${targetName}" "${targetArgs}")
        add("arm64-Release-Windows/RelWithDebInfo" "${Qt5x64Path}" "${targetName}" "${targetArgs}")
        add("x32-Release-Windows/RelWithDebInfo"   "${Qt5x32Path}" "${targetName}" "${targetArgs}")

        add("x64-Debug-Windows"                    "${Qt5x64Path}" "${targetName}" "${targetArgs}")
        add("arm64-Debug-Windows"                  "${Qt5x64Path}" "${targetName}" "${targetArgs}")
        add("x32-Debug-Windows"                    "${Qt5x32Path}" "${targetName}" "${targetArgs}")

        add("x64-Release-Windows"                  "${Qt5x64Path}" "${targetName}" "${targetArgs}")
        add("arm64-Release-Windows"                "${Qt5x64Path}" "${targetName}" "${targetArgs}")
        add("x32-Release-Windows"                  "${Qt5x32Path}" "${targetName}" "${targetArgs}")
    endforeach()

    set(json "${json}  ]\n")
    set(json "${json}}\n")

    string(SHA256 jsonHash "${json}")
    if("${launchVsJsonHash}" STREQUAL "${jsonHash}")
        return()
    endif()
    set(launchVsJsonHash "${jsonHash}" CACHE INTERNAL "")

    message("Write ${cfgPath}")
    file(WRITE "${cfgPath}" "reload") # Reload the config by using some JSON-error
    file(WRITE "${cfgPath}" "${json}")
endfunction(__write_msvs_launch_vs_json)


# CPU leak by:
#  "C:/Program Files/Microsoft Visual Studio/2022/Community/Common7/ServiceHub/Hosts/ServiceHub.Host.Dotnet.arm64/ServiceHub.IndexingService.exe"
# Memory leak in:
#  "C:/..../myproject/.vs/myproject/FileContentIndex/merges"
# https://stackoverflow.com/questions/72237599/how-to-disable-that-new-filecontentindex-folder-and-vsidx-files-in-vs-2022
# "C:/Program Files/Microsoft Visual Studio/2022/Community/Common7/IDE/CommonExtensions/Microsoft/Editor/ServiceHub/Indexing.servicehub.service.json"
function(__crutch_for_msvs_bug_with_merges)
    get_filename_component(absolutePatentPath "${CMAKE_SOURCE_DIR}/../" ABSOLUTE)
    set(absolutePath "${CMAKE_SOURCE_DIR}")
    string(LENGTH ${absolutePatentPath} length)
    math(EXPR length "${length}+1")
    string(SUBSTRING ${absolutePath} ${length} -1 folder)
    set(mergesPath "${CMAKE_SOURCE_DIR}/.vs/${folder}/FileContentIndex/merges")

    if(EXISTS "${mergesPath}/")
        file(REMOVE_RECURSE "${mergesPath}/")
        file(TOUCH "${mergesPath}")
    endif()
endfunction(__crutch_for_msvs_bug_with_merges)


# @param targetName
# @param toPath  (optional)  "workdir/bin_***/{to/Path}.ext"
function(copy_release_binary_to_workdir targetName)
    get_target_property(targetType ${targetName} TYPE)
    get_target_property(targetOutputName ${targetName} OUTPUT_NAME)
    if("${targetOutputName}" STREQUAL "targetOutputName-NOTFOUND")
        set(targetOutputName ${targetName})
    endif()

    set(argIdx -1)
    set(toPath "${targetOutputName}")
    foreach(arg ${ARGN})
        math(EXPR argIdx "${argIdx}+1")
        if(${argIdx} EQUAL 0)
            set(toPath "${arg}")
        else()
            message(FATAL_ERROR "copy_release_binary_to_workdir: wrong aguments number for \"${targetName}\"")
        endif()
    endforeach()

    if("${targetType}" STREQUAL "EXECUTABLE")
        set(targetOutputName "${targetOutputName}${CMAKE_EXECUTABLE_SUFFIX}")
        set(toPath "${toPath}${CMAKE_EXECUTABLE_SUFFIX}")
    elseif("${targetType}" STREQUAL "SHARED_LIBRARY")
        set(targetOutputName "${targetOutputName}${CMAKE_SHARED_LIBRARY_SUFFIX}")
        set(toPath "${toPath}${CMAKE_SHARED_LIBRARY_SUFFIX}")
    else()
        message(FATAL_ERROR "copy_release_binary_to_workdir: \"${targetName}\" must be EXECUTABLE or SHARED_LIBRARY")
    endif()

    if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        return()
    endif()

    if(MSVC AND NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
        set(fullfrom "${CMAKE_SOURCE_DIR}/build/${BUILD_FOLDER}/${CMAKE_BUILD_TYPE}/${targetOutputName}")
    else()
        set(fullfrom "${CMAKE_SOURCE_DIR}/build/${BUILD_FOLDER}/${targetOutputName}")
    endif()
    set(fullto "${CMAKE_SOURCE_DIR}/workdir/bin_${BUILD_ARCH}/${toPath}")

    add_custom_command(
        TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${fullfrom}" "${fullto}"
    )
endfunction(copy_release_binary_to_workdir)


if("${RUN}" STREQUAL "")
    if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
        message(FATAL_ERROR
            "In-source builds not allowed. Please use a build directory.\n"
            "For example: \"build/.cmake/x64-Release-Linux\""
        )
    else()
        message("${CMAKE_BINARY_DIR}")
    endif()

    if("${CMAKE_BUILD_TYPE}" STREQUAL "")
        set(default_build_type "RelWithDebInfo")
        set(CMAKE_BUILD_TYPE "RelWithDebInfo")
    endif()

elseif("${RUN}" STREQUAL "qt5_create_ts_and_qm")
    __qt5_create_ts_and_qm_impl()

elseif("${RUN}" STREQUAL "breakpad_dump_and_strip")
    __breakpad_dump_and_strip()

endif()
