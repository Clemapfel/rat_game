rt.random = {}
rt.random.DEFAULT_SEED = 1234
if not meta.is_nil(love) then
    love.math.setRandomSeed(rt.random.DEFAULT_SEED)
else
    math.randomseed(rt.random.DEFAULT_SEED)
end

--- @brief generate number in [0, 1]
--- @param seed_maybe Number (or nil)
--- @return Number
function rt.rand(seed_maybe)
    if not meta.is_nil(seed_maybe) then
        love.math.setRandomSeed(seed_maybe)
    end
    return love.math.random()
end

--- @brief re-seed randomness
--- @param seed Number
function rt.random.seed(seed)

    love.math.setRandomSeed(seed)
end

--- @brief get random number in given range
--- @param min Number
--- @param max Number
--- @return Number
function rt.random.integer(min, max)

    return love.math.random(min, max)
end

--- @brief get random float in given range
--- @param min Number
--- @param max Number
--- @return Number
function rt.random.number(min, max)

    return min + rt.rand() * max
end

--- @brief pick random element from table
--- @param set Table
function rt.random.choose(set)

    local step = rt.random.integer(0, #set)
    local i, v = next(set)
    local n = 0
    while i ~= nil do
        if n == step then
            return v
        end
        n = n + 1
        i, v = next(set, i)
    end
    return v
end

rt.random.CHAR_LIST = {
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
}

--- @brief generate string
--- @param length Number
--- @param set Table<String> (or nil)
function rt.random.string(length, set)
    if meta.is_nil(set) then
        set = rt.random.CHAR_LIST
    end

    local out = {}
    for i = 1, length do
        table.insert(out, set[rt.random.integer(1, #set)])
    end
    return table.concat(out, "")
end

--- @brief test random
function rt.test.random()
   error("TODO")
end
