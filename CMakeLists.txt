cmake_minimum_required(VERSION 3.12)
include("CMakeUtils.cmake")

check_build_directory()

project(application)

init_project(
	"${PROJECT_NAME} --test-arg"
	"tests"
)

add_subdirectory("${CMAKE_SOURCE_DIR}/deps/shared" shared)
add_subdirectory("${CMAKE_SOURCE_DIR}/deps/static" static)

add_subdirectory(application)
add_subdirectory(tests)
