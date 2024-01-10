cmake_minimum_required(VERSION 3.19)
project(rat_game)

find_library(fftw REQUIRED NAMES fftw3)
find_package(Lua REQUIRED)

add_executable(rat_game_test cpp/main.cpp)
target_link_libraries(rat_game_test PRIVATE fftw3 ${LUA_LIBRARIES})