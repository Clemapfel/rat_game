-- RESOURCE_PATH = "."
package.path = package.path .. ";" .. RESOURCE_PATH .. "include/lua/?.lua"

require "common"
require "meta"
require "test"
require "queue"
require "set"

--- @module rat_game battle module
rt = {}
rt.generate = {}

require "battle_log"
require "priority"
require "status"
require "stat_level"
require "continuous_effect"
require "weather"
require "move"
require "entity"

require "data/effects"
require "data/moves"
require "data/weathers"

--- @TODO

entity_a = rt.Entity("a")
entity_b = rt.Entity("b")
rt.raise_attack_level(entity_a)

do
local brackets = {}
local priorities = {}

for prio in pairs(rt.Priority) do
    table.insert(priorities, prio)
    brackets[prio] = {}
end

local temp = {}
for i=1,10 do
    table.insert(temp, {
        speed = math.random(),
        priority = (i % 3) - 2
    })
end

for _, entity in pairs(temp) do

    local prio = entity.priority
    if brackets[prio] == nil then
        brackets[prio] = {}
    end
    table.insert(brackets[prio], entity.id)
end

local out = {}

table.sort(priorities)
for prio in pairs(priorities) do
    local bracket = brackets[prio]
    table.sort(brackets, function(a, b)
        return a.priority > b.priority
    end)

    for _, v in pairs(brackets) do
        table.insert(out, v)
    end
end

println(serialize(out))
end