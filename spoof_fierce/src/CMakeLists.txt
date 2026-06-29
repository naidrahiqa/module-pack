cmake_minimum_required(VERSION 3.18)
project(spoof_fierce CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(spoof_fierce SHARED
    spoof_module.cpp
)

target_include_directories(spoof_fierce PRIVATE .)
target_link_libraries(spoof_fierce log)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_options(spoof_fierce PRIVATE -Os -flto)
    target_link_options(spoof_fierce PRIVATE -s -flto)
endif()
