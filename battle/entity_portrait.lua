--- @class bt.EntityPortrait
bt.EntityPortrait = meta.new_type("EntityPortrait", function(entity)

    if meta.is_nil(env.entity_portrait_spritesheet) then
        env.entity_portrait_spritesheet = rt.Spritesheet("assets/sprites", "entity_portrait")
    end

    local color = rt.settings.entity_portrait.gradient_color
    local color_from = rt.RGBA(color.r, color.g, color.b, 1)
    local color_to = rt.RGBA(color.r, color.g, color.b, 0)

    color_from = rt.Palette.GREY_6
    color_to = rt.Palette.GREY_4

    local sprite_id = "test"
    local out = meta.new(bt.EntityPortrait, {
        _entity = entity,
        _sprite = rt.Sprite(env.entity_portrait_spritesheet, sprite_id),
        _aspect = rt.AspectLayout(1),
        _backdrop = rt.Spacer(),
        _overlay = rt.OverlayLayout(),
        _frame = rt.Frame(rt.FrameType.RECTANGULAR),
        _gradient = rt.GradientSpacer(
            rt.GradientDirection.TOP_TO_BOTTOM,
            color_from,
            color_to
        )
    }, rt.Widget, rt.Drawable)

    out._backdrop:set_color(rt.Palette.BASE)
    out._overlay:set_base_child(out._backdrop)
    out._overlay:push_overlay(out._gradient)
    out._overlay:push_overlay(out._sprite)
    out._frame:set_child(out._overlay)
    out._aspect:set_child(out._frame)

    out._frame:set_thickness(2)
    return out
end)

--- @overload
function bt.EntityPortrait:get_top_level_widget()
    return self._aspect
end
