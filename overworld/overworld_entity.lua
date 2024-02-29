
--- @class ow.OverworldEntity
ow.OverworldEntity = meta.new_abstract_type("OverworldEntity", rt.Drawable, {
    _is_realized = false,
})


--- @overload
function ow.OverworldEntity:realize()
    rt.error("In ow.OverworldEntity:realize: abstract method called")
end
