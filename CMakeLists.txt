cmake_minimum_required(VERSION 3.12)
include("CMakeUtils.cmake")

project(application)

init_project(
    "${PROJECT_NAME} --test-arg"
    "tests"
)

#NOTE: Specify the C++ standard only in main CMakeLists before subdirectories
set(CMAKE_CXX_STANDARD 20)
#NOTE: When it's not required, it will be the maximum available
set(CMAKE_CXX_STANDARD_REQUIRED OFF)
#NOTE: Always disable C++ extensions for maximum compatibility
set(CMAKE_CXX_EXTENSIONS OFF)

add_subdirectory("deps/shared")
add_subdirectory("deps/static")

add_subdirectory("application")
add_subdirectory("tests")

#  #define OPTION_TEST_BOOL 1
add_option(BOOL TEST_BOOL TRUE
    TARGETS application
)

#  #define OPTION_TEST_ENUM "IMX6"
#  #define OPTION_TEST_ENUM_IMX6 1
add_option(ENUM TEST_ENUM IMX6 ROCKPI DESKTOP
    TARGETS application
    COMMENT " Specify the target platform"
            "one more comment row; and a word"
)

#  #define OPTION_TEST_STRING "John Smith"
add_option(STRING TEST_STRING "John Smith"
    TARGETS application
    COMMENT " Specify the author"
)

#  #define OPTION_TEST_DIR "~/directory/"
add_option(DIR TEST_DIR "~/directory/"
    TARGETS application
    COMMENT " Specify the directory"
)

#  #define OPTION_TEST_FILE "~/file"
add_option(FILE TEST_FILE "~/file"
    TARGETS application
    COMMENT " Specify the file"
)
