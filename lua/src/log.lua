--- @brief gender determines pronouns used in log
rt.GrammaticalGender = meta.new_enum({
    SHE_HER,
    HE_HIM,
    THEY_THEM,
    IT_IT,
})

--- @brief log message, interpolating values based on the entity given
function rt.log(message, entity)
    meta.assert_string(message)
    if not meta.is_nil(entity) then
        meta.assert_isa(entity, rt.Entity)
    end
    rt.queue(function()
        println(message)
    end)
end