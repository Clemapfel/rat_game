--- @class bt.VerboseInfo.StatusPage
bt.VerboseInfo.StatusPage = meta.new_type("VerboseInfo_StatusPage", rt.Drawable, function(config)
    return meta.new(bt.VerboseInfo.StatusPage, {
        backdrop = bt.Backdrop(),
        -- other members: cf. create_from
    })
end)

--- @brief
function bt.VerboseInfo.StatusPage:create_from(config)

    self.backdrop:realize()

    local new_label = function (...)
        local str = ""
        for _, v in pairs({...}) do
            str = str .. tostring(v)
        end
        local out = rt.Label(str, rt.settings.font.default, rt.settings.font.default_mono)
        out:realize()
        out:set_alignment(rt.Alignment.START)
        return out
    end

    self.name_label = new_label("<u><b>", config.name, "</b></u>")

    local grey = "GRAY_3"
    local number_prefix = "<b><color=" .. grey .. ">:</color></b>    <mono>"
    local number_postfix = "</mono>"

    self.duration_label_left = new_label("Duration")
    self.duration_label_right = new_label(number_prefix, ternary(config.max_duration == POSITIVE_INFINITY, "∞", config.max_duration), number_postfix)

    self.effect_label = new_label("<u>Effect</u>: " .. config.description)

    self.sprite = rt.Sprite(config.sprite_id)
    self.sprite:realize()
end

--- @brief
function bt.VerboseInfo.StatusPage:reformat(aabb)
    local x, y, width, height = aabb.x, aabb.y, aabb.width, aabb.height
    local current_x, current_y = 0, 0
    local m = rt.settings.margin_unit

    self.name_label:fit_into(current_x, current_y, width, height)
    current_y = current_y + select(2, self.name_label:measure()) + m

    self.duration_label_left:fit_into(current_x, current_y, width, height)
    self.duration_label_right:fit_into(select(1, self.duration_label_left:measure()) + 2 * m, current_y, width, height)
    current_y = current_y + select(2, self.duration_label_left:measure())
    current_y = current_y + m

    self.effect_label:fit_into(current_x, current_y, width - 2 * m, height)
    current_y = current_y + select(2, self.effect_label:measure())

    x, y, width, height = 0, 0, width, current_y - y
    x = x - 2 * m
    y = y - 2 * m
    width = width
    height = height + math.max(2 * self.name_label:get_font():get_size(), 5 * m)
    self.backdrop:fit_into(x, y, width, height)

    local resolution = select(1, self.sprite:get_resolution())
    self.sprite:fit_into(x + width - 2 * resolution - 1 * m, y + 1 * m, 2 * resolution, 2 * resolution)
end

--- @brief
function bt.VerboseInfo.StatusPage:draw()
    self.backdrop:draw()
    self.name_label:draw()
    self.duration_label_left:draw()
    self.duration_label_right:draw()
    self.effect_label:draw()
    self.sprite:draw()
end