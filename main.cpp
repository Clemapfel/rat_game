#include <sol/sol.hpp>

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

    auto app = Application("com.rat-game");
    app.connect_signal_activate([](Application& app){
        main_window = new Window(app);

        auto bar = LevelBar(0, 1);
        bar.set_value(0);

        auto animation = Animation(bar, seconds(5));
        animation.set_lower(bar.get_min_value());
        animation.set_upper(bar.get_max_value());
        animation.on_tick([&](Animation&, double v){
            bar.set_value(v);
        });

        auto start_animation_action = Action("start.animation", app);
        start_animation_action.set_function([&](Action&){
            animation.play();
        });
        start_animation_action.add_shortcut("<Control>space");
        main_window->set_listens_for_shortcut_actions(start_animation_action);

        main_window->set_child(bar);
        main_window->present();
    });

    return app.run();
}