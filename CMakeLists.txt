cmake_minimum_required(VERSION 3.18)
project(rat_game VERSION 0.1.0 DESCRIPTION "" LANGUAGES CXX)

### DEPENDENCIES ###

find_library(lua REQUIRED NAMES lua)
set(SOL_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/submodules/sol2/include")

### EXECUTABLE ###

add_executable(battle_main main.cpp)
target_link_libraries(battle_main PRIVATE
    "${lua}"
    "${MOUSETRAP_LIBRARIES}"
)

target_include_directories(battle_main PRIVATE
    "${SOL_INCLUDE_DIR}"
    "${MOUSETRAP_INCLUDE_DIRECTORIES}"
)

target_compile_features(battle_main PUBLIC
    cxx_std_17
)