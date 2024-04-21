--- @class bt.BattleBackgroundImplementation
bt.BattleBackgroundImplementation = meta.new_abstract_type("BattleBackgroundImplementation")

--- @brief
function bt.BattleBackgroundImplementation:realize()
    rt.error("In bt.BattleBackgroundImplementation.realize: abstract method called for `" .. meta.typeof(self) .. "`")
end


--- @brief
function bt.BattleBackgroundImplementation:step(delta_time, music_intensity)
    rt.error("In bt.BattleBackgroundImplementation.step: abstract method called for `" .. meta.typeof(self) .. "`")
end

--- @brief
function bt.BattleBackgroundImplementation:draw()
    rt.error("In bt.BattleBackgroundImplementation.draw: abstract method called for `" .. meta.typeof(self) .. "`")
end

--- @brief
function bt.BattleBackgroundImplementation:resize(x, y, width, height)
    rt.error("In bt.BattleBackgroundImplementation.resize: abstract method called for `" .. meta.typeof(self) .. "`")
end

--- ###

--- @class bt.BattleBackground
bt.BattleBackground = meta.new_type("BattleBackground", bt.Animation, rt.Widget, function(id)
    local implementation = bt.BattleBackground[id]
    if implementation == nil then
        rt.error("In bt.BattleBackground: no background implementation with id `" .. id .. "` available")
    end

    return meta.new(bt.BattleBackground, {
        _implementation_id = id,
        _implementation = {}, -- bt.BattleBackgroundImplementation
    })
end)

--- @brief
function bt.BattleBackground:realize()
    if self._is_realized == true then return end
    self._implementation = bt.BattleBackground[self._implementation_id]()
    self._implementation:realize()
    self._is_realized = true
end

--- @brief
function bt.BattleBackground:size_allocate(x, y, width, height)
    if not (self._is_realized == true) then return end
    self._implementation:resize(x, y, width, height)
end

--- @brief
function bt.BattleBackground:draw()
    self._implementation:draw()
end

--- @brief
function bt.BattleBackground:update(delta)
    local _magnitudes = {}
    local n_magnitudes = 148
    for i = 1, n_magnitudes do
        table.insert(_magnitudes, rt.random.number(0, 1) * rt.skewed_gaussian(i / n_magnitudes, 0.2, 1, 0))
    end
    self._implementation:step(delta, _magnitudes)
end