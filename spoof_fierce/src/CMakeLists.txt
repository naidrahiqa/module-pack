cmake_minimum_required(VERSION 3.18)
project(spoof_fierce CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Zygisk native hook (.so)
add_library(spoof_fierce SHARED
    spoof_module.cpp
)
target_include_directories(spoof_fierce PRIVATE .)
target_link_libraries(spoof_fierce log)

# API handler (executable)
add_executable(spoof_api
    api_handler.c
    json_lite.c
)
target_link_libraries(spoof_api log)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_options(spoof_fierce PRIVATE -Os -flto)
    target_link_options(spoof_fierce PRIVATE -s -flto)
    target_compile_options(spoof_api PRIVATE -Os -flto)
    target_link_options(spoof_api PRIVATE -s -flto)
endif()
