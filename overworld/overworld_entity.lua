--- @class ow.OverworldEntity
ow.OverworldEntity = meta.new_abstract_type("OverworldEntity", rt.Drawable, rt.Animation, rt.SignalEmitter)

--- @overload called when player interacts with object
function ow.OverworldEntity:on_interact() end

--- @overload called when player intersects
function ow.OverworldEntity:on_intersect() end

--- @overload
function ow.OverworldEntity:draw() end

--- @overload
function ow.OverworldEntity:realize()
    rt.error("In ow.OverworldEntity:realize: abstract method called")
end

--- @overload
function ow.OverworldEntity:unrealize()
    rt.error("In ow.OverworldEntity:unrealize: abstract method called")
end

