--- @class
bt.BattleUI = meta.new_abstract_type("BattleUI", rt.Widget, rt.Animation, {
    _entity = {},
    _is_realized = false
})

--- @abstract
function bt.BattleUI:sync()
    rt.error("In bt.BattleUI:synch: pure abstract method called")
end

--- @abstract