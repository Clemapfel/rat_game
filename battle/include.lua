-- RESOURCE_PATH = ""
package.path = package.path .. ";" .. RESOURCE_PATH .. "include/lua/?.lua"

require "common"
require "meta"
require "test"
require "queue"
require "set"

--- @module rat_game battle module
rt = {}
log = {}

require "battle_log"
require "status_ailment"
require "stat_modifier"
require "continuous_effect"
require "weather"
require "entity"

require "data/effects"

--- @TODO

entity_a = rt.Entity("a")
entity_b = rt.Entity("b")

rt.raise_attack_level(entity_b)

print(serialize(rt.UNAWARE))

rt.UNAWARE.before_damage_taken(entity_a, entity_b)
rt.UNAWARE.on_damage_taken(entity_a, entity_b, 10)
