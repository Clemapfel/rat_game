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

        auto button = Button();
        button.connect_signal_clicked([](Button*){
            sol::function step = battle::state["rt"]["step"];
            step();
        });
        button.set_child(Label("&#8594;"));
        button.set_margin(75);
        window.set_child(button);
        window.present();
    });

    return app.run();
}