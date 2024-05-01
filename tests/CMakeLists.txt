cmake_minimum_required(VERSION 3.12)

project(tests VERSION 0.0.1 LANGUAGES CXX C)

add_executable(${PROJECT_NAME})
copy_release_app_to_workdir("${PROJECT_NAME}")

if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE
        /W4 # Warning Level
    )
else()
    target_compile_options(${PROJECT_NAME} PRIVATE
        -Wall
        -Wextra
        -Wpedantic
        -Wno-float-conversion
    )
endif()


# headeronly
target_include_directories(${PROJECT_NAME} PRIVATE "${CMAKE_SOURCE_DIR}/deps/headeronly")


# shared
target_link_libraries(${PROJECT_NAME} PRIVATE shared)
copy_release_lib_to_workdir("shared")


# static
target_link_libraries(${PROJECT_NAME} PRIVATE static)


if(UNIX)
    target_link_libraries(${PROJECT_NAME} PRIVATE
        pthread
    )
endif()


#target_precompile_headers(${PROJECT_NAME} PRIVATE "pch.h")
target_sources(${PROJECT_NAME} PRIVATE
    "main.cpp"
)
