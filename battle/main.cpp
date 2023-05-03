#include <sol/sol.hpp>
#include <mousetrap.hpp>

#include <include/lua/state.hpp>
#include <include/battle_entity.hpp>

const std::string RESOURCE_PATH = "/home/clem/Workspace/rat_game/battle/";
using namespace mousetrap;
using namespace rt;

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
        sol::lib::coroutine
    );

    rt::battle::state["RESOURCE_PATH"] = RESOURCE_PATH;
    rt::battle::state.safe_script_file(RESOURCE_PATH + "include.lua");

    auto entity = battle::Entity(battle::state.get<sol::table>("entity_a"));
    std::cout << entity.get_attack_level() << std::endl;

    return 0;

    auto app = Application("rat.game");
    app.connect_signal_activate([](Application* app){
        auto window = Window(*app);
        window.present();
    });

    return app.run();
}