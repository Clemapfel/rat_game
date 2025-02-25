function rt.Set(...)
    local out = {}
    for x in range(...) do
        out[x] = true
    end
    return out
end