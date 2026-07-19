cmake_minimum_required(VERSION 3.18)
project(ui_enhance C)

set(CMAKE_C_STANDARD 11)

add_executable(ui_daemon ui_daemon.c)

target_link_libraries(ui_daemon log)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_options(ui_daemon PRIVATE -Os -flto)
    target_link_options(ui_daemon PRIVATE -s -flto)
endif()
