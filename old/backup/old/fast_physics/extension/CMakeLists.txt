cmake_minimum_required(VERSION 3.10)

project(box2d_extension VERSION 1.0 LANGUAGES CXX)
add_library(box2d_extension SHARED
    box2d_extension.hpp
    box2d_extension.cpp
)
set_target_properties(box2d_extension PROPERTIES LINKER_LANGUAGE CXX)

