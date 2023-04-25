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

effect = rt.IgnitionEffect(function (a, b, c)
    println(a.name .. b.name .. c)
end)

entity_a = rt.Entity("a")
entity_b = rt.Entity("b")
effect(entity_a, entity_b, "test")