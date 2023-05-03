#include <sol/sol.hpp>
#include <mousetrap.hpp>

#include <include/lua/state.hpp>
#include <include/battle_entity.hpp>
#include <include/verbose_entity_info.hpp>

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

    auto app = Application("rat.game");
    app.connect_signal_activate([](Application* app){
        auto window = Window(*app);

        static sol::table temp = battle::state["entity_a"];
        static auto entity = battle::Entity(temp);
        static auto entity_info = battle::VerboseEntityInfo();
        entity_info.update_from(entity);

        window.set_child(entity_info);
        window.present();
    });

    return app.run();
}