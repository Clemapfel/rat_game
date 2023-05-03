-- RESOURCE_PATH = ""
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

rt.add_effect(entity_a, rt.UNAWARE)

println(serialize(entity_a))
println(rt.get_hp(entity_b))
rt.BASIC_ATTACK.apply(entity_a, entity_b)
println(rt.get_hp(entity_b))

