#include <sol/sol.hpp>
#include <mousetrap.hpp>

const std::string RESOURCE_PATH = "/home/clem/Workspace/rat_game/battle/";
using namespace mousetrap;

int main()
{
    static sol::state lua;
    lua.open_libraries(
        sol::lib::base,
        sol::lib::package,
        sol::lib::os,
        sol::lib::io,
        sol::lib::string,
        sol::lib::table,
        sol::lib::math,
        sol::lib::coroutine
    );

    lua["RESOURCE_PATH"] = RESOURCE_PATH;
    lua.safe_script_file(RESOURCE_PATH + "include.lua");

    return 0;

    auto app = Application("rat.game");
    app.connect_signal_activate([](Application* app){
        auto window = Window(*app);
        window.present();
    });

    return app.run();
}