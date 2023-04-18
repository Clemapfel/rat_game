-- RESOURCE_PATH = ""
package.path = package.path .. ";" .. RESOURCE_PATH .. "include/lua/?.lua"

require "common"
require "meta"
require "test"
require "queue"
require "set"

--- @module rat_game battle module
rt = {}

require "battle_log"
require "status_ailment"
require "stat_modifier"
--- require "entity"


--- ### ACTION QUEUE ###

rt._action_queue = Queue()

function rt.queue_action(f)
    rt._action_queue:push_back(coroutine.wrap(f))
end

function test()
end


function rt.step_action()

    if rt._action_queue:is_empty() then
        return
    end

    (rt._action_queue:pop_back())()
end

function rt.flush_actions()
    while not rt._action_queue:is_empty() do
        rt.step_action()
    end
end

for i=1,10 do
    rt.queue_action(function() print(i) end)
end

rt.flush_actions()