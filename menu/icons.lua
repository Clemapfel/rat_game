mn.Icon = meta.new_type("MenuIcon", function(sprite_id, sprite_index)
    return meta.new(mn.Icon, {
        _sprite = rt.Sprite(sprite_id, sprite_index)
    })
end)

mn.Icon.EQUIP = mn.Icon()