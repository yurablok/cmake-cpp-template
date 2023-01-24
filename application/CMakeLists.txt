cmake_minimum_required(VERSION 3.12)

project(application VERSION 0.0.1 LANGUAGES CXX C)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

# Qt
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

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


# Qt
if(Qt5_DIR)
    find_package(Qt5 COMPONENTS
        Core Network REQUIRED)
    target_compile_definitions(${PROJECT_NAME} PRIVATE QT_USE_QSTRINGBUILDER)
    target_link_libraries(${PROJECT_NAME} PRIVATE
        Qt5::Core Qt5::Network)
    #qt5_add_resources(PROJECT_RESOURCES "resources.qrc")
    qt5_create_ts_and_qm(
        SOURCES "."
        TS_FILES "resources/ts_chi.ts" # For example, ISO 639-2/B
                 "resources/ts_spa.ts"
                 "resources/ts_eng.ts"
                 "resources/ts_por.ts"
                 "resources/ts_rus.ts"
                 "resources/ts_jpn.ts"
                 "resources/ts_kor.ts"
                 "resources/ts_fre.ts"
                 "resources/ts_ger.ts"
                 "resources/ts_ita.ts"
        QM_DIR "resources"
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


#if(WIN32)
#    set(WIN32_RESOURCES "${CMAKE_CURRENT_SOURCE_DIR}/resources/resources.rc")
#else()
#    set(WIN32_RESOURCES "")
#endif()

#target_precompile_headers(${PROJECT_NAME} PRIVATE "pch.h")
target_sources(${PROJECT_NAME} PRIVATE
    "main.cpp"

    #"${PROJECT_RESOURCES}"
    #"${WIN32_RESOURCES}"
)
