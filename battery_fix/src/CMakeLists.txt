cmake_minimum_required(VERSION 3.18)
project(battery_fix C)

set(CMAKE_C_STANDARD 11)

add_executable(battery_daemon
    battery_daemon.c
)

target_link_libraries(battery_daemon log)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_options(battery_daemon PRIVATE -Os -flto)
    target_link_options(battery_daemon PRIVATE -s -flto)
endif()
