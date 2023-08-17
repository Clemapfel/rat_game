//
// Copyright (c) Clemens Cords (mail@clemens-cords.com), created 8/17/23
//

#pragma once

#include <mousetrap.hpp>
#include <sol/sol.hpp>

using namespace mousetrap;
namespace rt
{
    class PartyInfo : public Widget
    {
        public:
            PartyInfo(sol::table lua);


        private:
            Label _name;
            LevelBar _hp_bar;
            LevelBar _ap_bar;

            void update();
            sol::table _lua;
    };
}
