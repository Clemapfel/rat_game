rt.settings.battle.status_bar_element = {

}

--- @class bt.StatusBarElement
bt.StatusBarElement = meta.new_type("StatusBarElement", rt.Widget, function(scene, entity, status)
    return meta.new(bt.StatusBarElement, {
        _scene = scene,
        _status = status,

        _shape = {},      -- rt.Shape
        _spritesheet = {}, -- rt.SpriteAtlasEntry

        _n_turns_left_label = {}, -- rt.Glyph

        _tooltip = {
            is_realized = false
        }
    })
end)

--- @brief
function bt.StatusBarElement:_realize_tooltip()

end

--- @brief
function bt.StatusBarElement:realize()
    if self._is_realized then return end
    self._is_realized = true

    self._shape = rt.VertexRectangle(0, 0, 1, 1)
end

--- @brief
function bt.StatusBarElement:draw()
    if self._is_realized then
        self._shape:draw()
        self._glphy:draw()
    end
end