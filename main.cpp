#include <sol/sol.hpp>
#include <mousetrap.hpp>

const std::string RESOURCE_PATH = "/home/clem/Workspace/rat_game/";
using namespace mousetrap;

namespace rt::battle
{
    static inline sol::state state = sol::state();
}

int main()
{
    rt::battle::state.open_libraries(
        sol::lib::base,
        sol::lib::package,
        sol::lib::os,
        sol::lib::io,
        sol::lib::string,
        sol::lib::table,
        sol::lib::math,
        sol::lib::coroutine,
        sol::lib::debug
    );

    rt::battle::state["RESOURCE_PATH"] = RESOURCE_PATH;
    rt::battle::state.safe_script_file(RESOURCE_PATH + "lua/include.lua");

    return 0;
}