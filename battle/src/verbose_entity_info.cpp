//
// Created by clem on 5/3/23.
//

#include <include/verbose_entity_info.hpp>

namespace rt::battle
{
    VerboseEntityInfo::VerboseEntityInfo()
    {
        float margin = 10;

        _hp_bar_overlay.set_child(_hp_bar);
        _hp_bar_overlay.add_overlay(_hp_bar_value_label);
        _hp_bar_frame.set_child(_hp_bar_overlay);

        _hp_label.set_margin_end(margin);
        _hp_label.set_expand_horizontally(false);
        _hp_bar_frame.set_expand_horizontally(true);

        _hp_box.push_back(_hp_label);
        _hp_box.push_back(_hp_bar_frame);

        _ap_bar_overlay.set_child(_ap_bar);
        _ap_bar_overlay.add_overlay(_ap_bar_value_label);
        _ap_bar_frame.set_child(_ap_bar_overlay);

        _ap_label.set_margin_end(margin);
        _ap_label.set_expand_horizontally(false);
        _ap_bar_frame.set_expand_horizontally(true);

        _ap_box.push_back(_ap_label);
        _ap_box.push_back(_ap_bar_frame);

        _hp_bar.set_value(0.75);
        _ap_bar.set_value(1);

        size_t max_label_size = std::max(
            _hp_label.get_preferred_size().natural_size.x,
            _ap_label.get_preferred_size().natural_size.x
        );

        _hp_label.set_size_request({max_label_size, 0});
        _ap_label.set_size_request({max_label_size, 0});

        _attack_box.push_back(_attack_label);
        _attack_box.push_back(Separator());
        _attack_box.push_back(_attack_value);

        _defense_box.push_back(_defense_label);
        _defense_box.push_back(Separator());
        _defense_box.push_back(_defense_value);

        _speed_box.push_back(_speed_label);
        _speed_box.push_back(Separator());
        _speed_box.push_back(_speed_value);

        for (auto* left : {
            &_attack_label,
            &_defense_label,
            &_speed_label
        })
            left->set_horizontal_alignment(Alignment::START);

        for (auto* right : {
            &_attack_value,
            &_defense_value,
            &_speed_value
        })
            right->set_horizontal_alignment(Alignment::END);



        _main.push_back(_hp_box);
        _main.push_back(_ap_box);
        _main.push_back(_attack_box);
        _main.push_back(_defense_box);
        _main.push_back(_speed_box);

        _main.set_margin(10);
        _main.set_expand_horizontally(true);
    }

    VerboseEntityInfo::operator NativeWidget() const
    {
        return _main;
    }

    void VerboseEntityInfo::update_from(const Entity& entity)
    {
        _name.set_text(entity.get_name());

        _hp_bar.set_max_value(entity.get_hp_base());
        _hp_bar.set_value(entity.get_hp());

        _hp_bar_value_label.set_text(g_strdup_printf("%i", entity.get_hp()) + std::string("%"));

        _ap_bar.set_max_value(entity.get_ap_base());
        _ap_bar.set_value(entity.get_ap());

        _attack_value.set_text(g_strdup_printf("%i", entity.get_attack()));
        _defense_value.set_text(g_strdup_printf("%i", entity.get_defense()));
        _speed_value.set_text(g_strdup_printf("%i", entity.get_speed()));
    }
}