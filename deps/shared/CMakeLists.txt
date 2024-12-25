cmake_minimum_required(VERSION 3.12)

project(shared LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)

add_library(${PROJECT_NAME} SHARED
    "shared.cpp"
    "shared.hpp"
)
set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "")
target_include_directories(${PROJECT_NAME} PUBLIC "${CMAKE_CURRENT_LIST_DIR}")

add_metainfo(${PROJECT_NAME}
    VERSION 1.2.3.4-alpha5
    DESCRIPTION "Shared Library Template"
    PRODUCT "CMake C++ Template"
    COMPANY "HOME Co."
    COPYRIGHT "© 2007-2024 HOME Co. All rights reserved."
)
copy_release_binary_to_workdir(${PROJECT_NAME} "shared_test")
