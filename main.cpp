#include <sol/sol.hpp>
#include <mousetrap.hpp>

const std::string RESOURCE_PATH = "/home/clem/Workspace/rat_game/";
using namespace mousetrap;

namespace rt::battle
{
    static inline sol::state state = sol::state();
}

static inline Window* main_window = nullptr;
static inline KeyFile* config = nullptr;

/*
class PartyInfo : public Widget
{
    static inline RGBA AP_COLOR = RGBA(0, 1, 0.5, 1);
    static inline RGBA HP_COLOR = RGBA(1, 0, 0, 1);

    public:
        PartyInfo(sol::table& lua);

    private:
        Frame _frame;

        Frame _hp_bar_frame;
        LevelBar _hp_bar;
        Label _hp_bar_label;
        Overlay _hp_bar_overlay;
        StyleClass _hp_style_class = StyleClass("hp_bar");

        Frame _ap_bar_frame;
        LevelBar _ap_bar;
        Label _ap_bar_label;
        Overlay _ap_bar_overlay;
        StyleClass _ap_style_class = StyleClass("ap_bar");

        sol::table* _lua;
};

PartyInfo::PartyInfo(sol::table& lua)
    : Widget(_frame.operator NativeWidget()),
      _lua(&lua)
{
    _hp_style_class.set_property(STYLE_TARGET_LEVEL_BAR_BLOCK_HIGH, HP)

    _hp_bar_overlay.set_child(_hp_bar);
    _hp_bar_overlay.add_overlay(_hp_bar_label);
    _hp_bar_frame.set_child(_hp_bar_overlay);
    _hp_bar_frame.apply_style_class(_hp_style_class);

    _ap_bar_overlay.set_child(_ap_bar);
    _ap_bar_overlay.add_overlay(_ap_bar_label);
    _ap_bar_frame.set_child(_ap_bar_overlay);
}
*/

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