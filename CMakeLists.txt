cmake_minimum_required(VERSION 3.12)
include("CMakeUtils.cmake")

check_build_directory()

project(application)

init_project(
    "${PROJECT_NAME} --test-arg"
    "tests"
)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED OFF)
set(CMAKE_CXX_EXTENSIONS OFF)

add_subdirectory("${CMAKE_SOURCE_DIR}/deps/shared" shared)
add_subdirectory("${CMAKE_SOURCE_DIR}/deps/static" static)

add_subdirectory(application)
add_subdirectory(tests)

add_option(BOOL TEST_BOOL TRUE
    TARGETS application
)

add_option(ENUM TEST_ENUM IMX6 ROCKPI DESKTOP
    TARGETS application
    COMMENT " Specify the target platform"
            "one more comment row; and a word"
)

add_option(STRING TEST_STRING "John Smith"
    TARGETS application
    COMMENT " Specify the author"
)

add_option(DIR TEST_DIR "~/directory/"
    TARGETS application
    COMMENT " Specify the directory"
)

add_option(FILE TEST_FILE "~/file"
    TARGETS application
    COMMENT " Specify the file"
)
