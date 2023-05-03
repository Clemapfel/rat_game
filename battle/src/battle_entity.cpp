//
// Created by clem on 5/3/23.
//

#include <include/battle_entity.hpp>
#include <include/lua/state.hpp>

namespace rt::battle
{
    Entity::Entity(sol::table table)
    {
        _internal = table;
    }

    #define implement_entity_function(name, return_t) \
    return_t Entity::name() const                   \
    {                                               \
        static sol::function f = state["rt"][#name]; \
        return f(_internal);                        \
    }

    implement_entity_function(get_attack, float);
    implement_entity_function(get_defense, float);
    implement_entity_function(get_speed, float);
    implement_entity_function(get_attack_base, float);
    implement_entity_function(get_defense_base, float);
    implement_entity_function(get_speed_base, float);

    implement_entity_function(get_hp, size_t);
    implement_entity_function(get_hp_base, size_t);
    implement_entity_function(get_ap, size_t);
    implement_entity_function(get_ap_base, size_t);

    implement_entity_function(get_attack_level, int);
    implement_entity_function(get_defense_level, int);
    implement_entity_function(get_speed_level, int);
}
