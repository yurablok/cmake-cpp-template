cmake_minimum_required(VERSION 3.12)

project(static LANGUAGES CXX)

#NOTE: set(CMAKE_CXX_STANDARD xx) is prohibited in static libs

add_library(${PROJECT_NAME} STATIC
    "static.cpp"
    "static.hpp"
)
set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "")
target_include_directories(${PROJECT_NAME} PUBLIC "${CMAKE_CURRENT_LIST_DIR}")
