cmake_minimum_required(VERSION 3.19)
project(rat_game)

find_library(fftw REQUIRED NAMES fftw3)
find_library(fftwf REQUIRED NAMES fftw3f)
find_library(fftwl REQUIRED NAMES fftw3l)
set(FFTW_LIBRARIES "${fftw};${fftwf};${fftwl}")
find_package(Lua REQUIRED)

add_executable(rat_game_test cpp/main.cpp)
target_link_libraries(rat_game_test PRIVATE ${FFTW_LIBRARIES} ${LUA_LIBRARIES})