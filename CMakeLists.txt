cmake_minimum_required(VERSION 3.12)
project(rat_game VERSION 0.1.0 DESCRIPTION "" LANGUAGES CXX)

### DEPENDENCIES ###

find_library(lua REQUIRED NAMES lua)
set(SOL_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/submodules/sol2/include")

find_package(mousetrap REQUIRED)

find_package(PkgConfig)
pkg_check_modules(GTK gtk4)

if (NOT GTK_FOUND)
    message(FATAL_ERROR "Missing Dependency: unable to locate GTK4")
endif()

### EXECUTABLE ###

add_executable(battle_main battle/main.cpp battle/include/party_info.hpp battle/include/battle_entity.hpp battle/src/battle_entity.cpp battle/include/lua/state.hpp battle/src/party_info.cpp battle/include/verbose_entity_info.hpp battle/src/verbose_entity_info.cpp)
target_link_libraries(battle_main PRIVATE
    ${lua}
    "${MOUSETRAP_LIBRARIES}"
    ${GTK_LIBRARIES}
)

target_include_directories(battle_main PRIVATE
    "${SOL_INCLUDE_DIR}"
    "${MOUSETRAP_INCLUDE_DIRECTORIES}"
    "${CMAKE_SOURCE_DIR}/battle/"
    "${GTK_INCLUDE_DIRS}"
)

target_compile_features(battle_main PUBLIC
    cxx_std_17
)