cmake_minimum_required(VERSION 3.22)
project(hgengine_android LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# melonDS (GPL-3.0) provides the DS emulation core. It's pinned to a known-good
# commit and downloaded at configure time. To build against a local checkout
# instead, pass -DFETCHCONTENT_SOURCE_DIR_MELONDS=/path/to/melonDS.
set(MELONDS_COMMIT 906e9ebb27da8c6a715cd7abab4abfe8a8d29427)

include(FetchContent)
FetchContent_Declare(melonds
    URL https://github.com/melonDS-emu/melonDS/archive/${MELONDS_COMMIT}.tar.gz
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE)

# Core only: no Qt/SDL frontend, no desktop OpenGL renderer, no debugger.
set(BUILD_QT_SDL OFF CACHE BOOL "" FORCE)
set(ENABLE_OGLRENDERER OFF CACHE BOOL "" FORCE)
set(ENABLE_GDBSTUB OFF CACHE BOOL "" FORCE)
set(ENABLE_LTO_RELEASE OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(melonds)

add_library(hgengine_native STATIC
    bps.cpp
    emulator.cpp
    platform_android.cpp)
target_include_directories(hgengine_native PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(hgengine_native PUBLIC core)

if (ANDROID)
    add_library(hgengine SHARED jni_bridge.cpp)
    find_library(log-lib log)
    target_link_libraries(hgengine PRIVATE hgengine_native ${log-lib})
    target_link_libraries(hgengine_native PRIVATE ${log-lib})
else()
    # Host-side smoke tests: `cmake -S . -B build && cmake --build build && ./build/hge_tests`
    find_package(JNI QUIET)
    add_executable(hge_tests tests/host_tests.cpp)
    target_link_libraries(hge_tests PRIVATE hgengine_native)
    if (JNI_FOUND)
        # Compile-check the JNI bridge against the host JDK headers.
        add_library(hgengine_jni_check OBJECT jni_bridge.cpp)
        target_include_directories(hgengine_jni_check PRIVATE ${JNI_INCLUDE_DIRS})
        target_link_libraries(hgengine_jni_check PRIVATE hgengine_native)
    endif()
endif()
