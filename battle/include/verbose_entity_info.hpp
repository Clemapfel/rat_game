//
// Copyright (c) Clemens Cords (mail@clemens-cords.com), created 5/3/23
//

#pragma once

#include <mousetrap.hpp>
#include <include/battle_entity.hpp>

using namespace mousetrap;

namespace rt::battle {
    /// @brief
    class VerboseEntityInfo : public Widget
    {
        public:
            VerboseEntityInfo();
            operator NativeWidget() const override;

            void update_from(const Entity&);

        private:
            Box _main = Box(Orientation::VERTICAL);

            Label _name;

            Frame _hp_bar_frame;
            LevelBar _hp_bar = LevelBar(0, 1);
            Label _hp_bar_value_label = Label("100%");
            Overlay _hp_bar_overlay;
            Label _hp_label = Label("HP:");
            Box _hp_box = Box(Orientation::HORIZONTAL);

            Frame _ap_bar_frame;
            LevelBar _ap_bar = LevelBar(0, 1);
            Label _ap_bar_value_label = Label("100%");
            Overlay _ap_bar_overlay;
            Label _ap_label = Label("AP:");
            Box _ap_box = Box(Orientation::HORIZONTAL);

            Label _attack_label = Label("Attack:");
            Label _attack_value;
            Box _attack_box = Box(Orientation::HORIZONTAL);

            Label _defense_label = Label("Defense:");
            Label _defense_value;
            Box _defense_box = Box(Orientation::HORIZONTAL);

            Label _speed_label = Label("Speed:");
            Label _speed_value;
            Box _speed_box = Box(Orientation::HORIZONTAL);
    };
}