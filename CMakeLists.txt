cmake_minimum_required(VERSION 3.12)
project(rat_game VERSION 0.1.0 DESCRIPTION "" LANGUAGES CXX)

### DEPENDENCIES ###

find_library(lua REQUIRED NAMES lua)
set(SOL_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/submodules/sol2/include")

### LIBRARY ###

add_executable(battle_main battle/main.cpp)
target_link_libraries(battle_main PRIVATE
    ${lua}
)

target_include_directories(battle_main PRIVATE
    "${SOL_INCLUDE_DIR}"
    "${CMAKE_SOURCE_DIR}/battle/"
)

target_compile_features(battle_main PUBLIC
    cxx_std_17
)