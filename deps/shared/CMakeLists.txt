cmake_minimum_required(VERSION 3.12)

project(shared LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)

add_library(${PROJECT_NAME} SHARED
    "shared.cpp"
    "shared.hpp"
)
target_include_directories(${PROJECT_NAME} PUBLIC "${CMAKE_CURRENT_LIST_DIR}")
