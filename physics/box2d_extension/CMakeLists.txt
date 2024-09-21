cmake_minimum_required(VERSION 3.10)

project(box2d_extension VERSION 1.0)

option(BUILD_SHARED_LIBS "Build shared libraries" ON)

include_directories(${PROJECT_SOURCE_DIR}/box2d/include)
include_directories(${PROJECT_SOURCE_DIR}/box2d/src)

file(GLOB_RECURSE BOX2D_SOURCES
    ${PROJECT_SOURCE_DIR}/box2d/src/*.c
)

file(GLOB_RECURSE BOX2D_HEADERS
    ${PROJECT_SOURCE_DIR}/box2d/include/box2d/*.h
)

add_library(box2d_extension SHARED
    physics.hpp
    physics.cpp
    ${BOX2D_HEADERS}
    ${BOX2D_SOURCES}
)

set_target_properties(box2d_extension PROPERTIES
    LINKER_LANGUAGE C
)

if (MSVC)
    target_compile_options(box2d_extension PRIVATE /experimental:c11atomics /std:c17)
endif()
