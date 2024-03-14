--- @class bt.BattleEntityPortrait
bt.BattleEntityPortrait = meta.new_type("EntityPortrait", rt.Widget, function(entity)

    if meta.is_nil(env.entity_portrait_spritesheet) then
        env.entity_portrait_spritesheet = rt.Spritesheet("assets/sprites", "entity_portrait")
    end

    local color = rt.settings.entity_portrait.gradient_color
    local color_from = rt.RGBA(color.r, color.g, color.b, 1)
    local color_to = rt.RGBA(color.r, color.g, color.b, 0)

    color_from = rt.Palette.GRAY_6
    color_to = rt.Palette.GRAY_4

    local sprite_id = entity.portrait
    local sprite
    if env.entity_portrait_spritesheet:has_animation(sprite_id) then
        sprite = rt.Sprite(env.entity_portrait_spritesheet)
    else
        local letter_seen = false
        local abbreviation = ""
        for i = 1, #entity.name do
            local c = string.sub(entity.name, i, i)
            if string.find(c, "[A-Z]") ~= nil then
                if not letter_seen then
                    abbreviation = abbreviation ..  c
                    letter_seen = true
                end
            elseif string.find(c, "[0-9]") ~= nil then
                abbreviation = abbreviation ..  c
            end
        end
        sprite = rt.Viewport(rt.Label("<o><b>" .. abbreviation .. "</o></b>"))
    end

    local out = meta.new(bt.BattleEntityPortrait, {
        _entity = entity,
        _sprite = sprite,
        _aspect = rt.AspectLayout(1),
        _backdrop = rt.Spacer(),
        _overlay = rt.OverlayLayout(),
        _frame = rt.Frame(rt.FrameType.RECTANGULAR),
        _gradient = rt.GradientSpacer(
            rt.GradientDirection.TOP_TO_BOTTOM,
            color_from,
            color_to
        )
    })

    out._backdrop:set_color(rt.Palette.BASE)
    out._overlay:set_base_child(out._backdrop)
    out._overlay:push_overlay(out._gradient)
    out._overlay:push_overlay(out._sprite)
    out._frame:set_child(out._overlay)
    out._aspect:set_child(out._frame)

    local spacer = rt.Spacer()
    spacer:set_minimum_size(32, 32)

    out._frame:set_thickness(2)
    return out
end)

--- @overload
function bt.BattleEntityPortrait:get_top_level_widget()
    return self._aspect
end