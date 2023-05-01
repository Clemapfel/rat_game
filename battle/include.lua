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
require "stat_level"
require "continuous_effect"
require "weather"
require "entity"

require "data/effects"

--- @TODO

entity_a = rt.Entity("a")
entity_b = rt.Entity("b")


rt.raise_attack_level(entity_b)
rt.add_effect(entity_b, rt.BURNED)
println(rt.get_attack(entity_b))
