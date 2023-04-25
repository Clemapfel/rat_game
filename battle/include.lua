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
require "ignition_effect"
require "continuous_effect"
require "weather"
require "entity"

entity = rt.Entity("test")
println(entity)
rt.add_continuous_effect(entity, rt.Continuous.at_risk)
assert(rt.has_continuous_effect(entity, rt.Continuous.at_risk))
rt.remove_conitnuous_effect(entity, rt.Continuous.at_risk)
println(entity)

println()