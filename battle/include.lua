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
require "entity"

entity = rt.BattleEntity("test")
rt.set_attack_level(entity, rt.StatModifier.PLUS_1)
rt.set_attack_level(entity, rt.StatModifier.MINUS_1)