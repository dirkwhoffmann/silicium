cmake_minimum_required(VERSION 3.20)
project(utlib)
add_library(utlib)

target_include_directories(utlib PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty)

target_compile_features(utlib INTERFACE cxx_std_17)

file(GLOB_RECURSE UTL_SRC
        "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/*.c")

target_sources(utlib PRIVATE ${UTL_SRC})

