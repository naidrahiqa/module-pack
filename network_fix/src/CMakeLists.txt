cmake_minimum_required(VERSION 3.10)
project(network_fix C)

add_executable(network_daemon network_daemon.c)
target_link_libraries(network_daemon log)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_options(network_daemon PRIVATE -Os -flto)
    target_link_options(network_daemon PRIVATE -s -flto)
endif()
