cmake_minimum_required(VERSION 3.10)

project(box2d_extension VERSION 1.0 LANGUAGES C)
option(BUILD_SHARED_LIBS "Build shared libraries" ON)

file(GLOB_RECURSE BOX2D_SOURCES
    ${CMAKE_SOURCE_DIR}/box2d/src/*.c
    ${CMAKE_SOURCE_DIR}/box2d/src/*.h
)

file(GLOB_RECURSE BOX2D_HEADERS
    ${CMAKE_SOURCE_DIR}/box2d/include/box2d/*.h
)

add_library(box2d_extension STATIC
    box2d_extension.h
    box2d_extension.c
    ${BOX2D_HEADERS}
    ${BOX2D_SOURCES}
)

target_include_directories(box2d_extension PUBLIC
    ${CMAKE_SOURCE_DIR}/box2d/include
    ${CMAKE_SOURCE_DIR}/box2d/src
    ${CMAKE_SOURCE_DIR}
)

set_target_properties(box2d_extension PROPERTIES LINKER_LANGUAGE C)

if (MSVC)
    target_compile_options(box2d_extension PRIVATE /experimental:c11atomics /std:c17)
endif()