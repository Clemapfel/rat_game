cmake_minimum_required(VERSION 3.18)
project(rat_game VERSION 0.1.0 DESCRIPTION "" LANGUAGES CXX)

### DEPENDENCIES ###

find_library(lua REQUIRED NAMES lua)
set(SOL_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/submodules/sol2/include")

find_package(mousetrap REQUIRED)

find_package(PkgConfig)
pkg_check_modules(GTK REQUIRED gtk4)

### EXECUTABLE ###

set(MOUSETRAP_HEADER_FILES
    battle/party_info.hpp
)

set(MOUSETRAP_SOURCE_FILES
    battle/party_info.cpp
)

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