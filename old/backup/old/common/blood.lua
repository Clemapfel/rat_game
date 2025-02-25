--- @class rt.BloodEffect
rt.BloodEffect = meta.new_type("BloodEffect", rt.Drawable, rt.Updatable, function(sprite)
    local out = meta.new(rt.BloodEffect, {
        _velocity_shader = rt.ComputeShader("common/blood_velocity_step.glsl"),
        _spatial_hash_shader = rt.ComputeShader("common/blood_spatial_hash_step.glsl"),
        _render_shader = rt.Shader("common/blood_render.glsl")
    })
end)

--- @brief
function rt.BloodEffect:initialize()

end

--- @override
function rt.BloodEffect:draw()

end

--- @override
function rt.BloodEffect:update(delta)

end


