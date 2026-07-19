cmake_minimum_required(VERSION 3.18)
project(game_perftune C)

set(CMAKE_C_STANDARD 11)

add_executable(game_perftune
    game_perftune.c
    game_list.c
    gpu_tuner.c
    net_tuner.c
    cpu_pinner.c
)

target_link_libraries(game_perftune log)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_options(game_perftune PRIVATE -Os -flto)
    target_link_options(game_perftune PRIVATE -s -flto)
endif()
