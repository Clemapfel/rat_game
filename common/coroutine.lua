rt.coroutine = {}

--- @brief
function rt.coroutine.start( f)
    local out = coroutine.create(f)
    return coroutine.resume(f)
end

function rt.coroutine.try_yield()

end