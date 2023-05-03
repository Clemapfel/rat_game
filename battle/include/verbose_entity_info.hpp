//
// Copyright (c) Clemens Cords (mail@clemens-cords.com), created 5/3/23
//

#pragma once

#include <mousetrap.hpp>
#include <include/battle_entity.hpp>

using namespace mousetrap;

namespace rt::battle
{
    /// @brief
    class VerboseEntityInfo : public Widget
    {
        public:
            VerboseEntityInfo();
            operator NativeWidget() const override;

            void update_from(const Entity&);

        private:
            Frame _main;

            Frame _hp_bar_frame;
            LevelBar _hp_bar;
            Label _hp_value_label = Label("100");
            Label _hp_label = Label("HP:");
    };
}
