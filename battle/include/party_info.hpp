//
// Copyright (c) Clemens Cords (mail@clemens-cords.com), created 5/3/23
//

#pragma once

#include <mousetrap.hpp>


using namespace mousetrap;

namespace rt::battle
{
    /// @brief
    class PartyInfo : public Widget
    {
        public:
            PartyInfo();

            operator NativeWidget() const override;

        private:;
    };
}
