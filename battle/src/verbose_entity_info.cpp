//
// Created by clem on 5/3/23.
//

#include <include/verbose_entity_info.hpp>

namespace rt::battle
{
    VerboseEntityInfo::VerboseEntityInfo()
    {}

    VerboseEntityInfo::operator NativeWidget() const
    {
        return _main;
    }
}