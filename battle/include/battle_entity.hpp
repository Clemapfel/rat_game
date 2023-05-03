//
// Copyright (c) Clemens Cords (mail@clemens-cords.com), created 5/3/23
//

#pragma once

#include <sol/table.hpp>

namespace rt::battle
{
    class Entity
    {
        public:
            Entity(sol::table);

            std::string get_id() const;
            std::string get_name() const;

            float get_attack() const;
            float get_defense() const;
            float get_speed() const;

            float get_attack_base() const;
            float get_defense_base() const;
            float get_speed_base() const;

            size_t get_hp() const;
            size_t get_hp_base() const;

            size_t get_ap() const;
            size_t get_ap_base() const;

            int get_attack_level() const;
            int get_defense_level() const;
            int get_speed_level() const;

        private:
            sol::table _internal;
    };
}
