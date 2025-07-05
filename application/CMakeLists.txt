cmake_minimum_required(VERSION 3.12)

project(application LANGUAGES CXX C)

# Qt
if(Qt5_DIR)
    set(CMAKE_AUTOUIC ON)
    set(CMAKE_AUTOMOC ON)
    set(CMAKE_AUTORCC ON)
endif()

add_executable(${PROJECT_NAME})

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
    #qt5_add_resources(QT_RESOURCES "resources.qrc")
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


# static
target_link_libraries(${PROJECT_NAME} PRIVATE static)


if(UNIX)
    target_link_libraries(${PROJECT_NAME} PRIVATE
        pthread
    )
endif()


#if(WIN32)
#    set(WIN32_RESOURCES "${CMAKE_CURRENT_SOURCE_DIR}/resources/resources.rc")
#endif()

target_precompile_headers(${PROJECT_NAME} PRIVATE
    "$<$<COMPILE_LANGUAGE:C>:pch.h>"
    "$<$<COMPILE_LANGUAGE:CXX>:pch.hpp>"
)
target_sources(${PROJECT_NAME} PRIVATE
    "main.cpp"
    "pch.h"
    "pch.hpp"

    #"${QT_RESOURCES}"
    #"${WIN32_RESOURCES}"
)

string(TIMESTAMP CURRENT_YEAR "%Y")
add_metainfo(${PROJECT_NAME}
    VERSION 1.2.3.4-alpha5
    DESCRIPTION "Application Template"
    PRODUCT "CMake C++ Template"
    COMPANY "HOME Co."
    COPYRIGHT "© 2007-${CURRENT_YEAR} HOME Co. All rights reserved."
    ICON "icon"
)
#dump_syms_and_strip(${PROJECT_NAME} WORKDIR)
copy_release_binary(${PROJECT_NAME} WORKDIR)
